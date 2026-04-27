<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

// Prevent PHP errors from breaking JSON output
error_reporting(E_ALL);
ini_set('display_errors', 0); 

date_default_timezone_set('Asia/Manila'); 

include 'db_connect.php';

// Catch the Type Error issue by defaulting to an empty string instead of null
$scanned_id = $_POST['scanned_id'] ?? '';
$scanned_id = strtoupper(trim($scanned_id));

if (empty($scanned_id)) {
    echo json_encode(["status" => "error", "message" => "No ID provided to scanner."]);
    exit();
}

$current_time = date("H:i:s");
$current_date = date("Y-m-d");

try {
    $conn->query("SET time_zone = '+08:00'");

    // 1. AUTO-LOGOUT LOGIC (Fixed table name to lowercase to match DB)
    $conn->query("UPDATE entry_logs 
                  SET Time_Out = '18:00:00', 
                      Status = 'Auto-Logged-Out',
                      Time_Spent = TIMEDIFF('18:00:00', Time_In)
                  WHERE Time_Out IS NULL 
                  AND (Scan_Date < CURDATE() OR (Scan_Date = CURDATE() AND CURTIME() > '18:00:00'))");

    // 2. GET STUDENT INFO
    $stmt = $conn->prepare("SELECT Student_Number, First_Name, Last_Name, Program FROM students WHERE TRIM(Student_Number) = ? LIMIT 1");
    if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
    
    $stmt->bind_param("s", $scanned_id);
    $stmt->execute();
    $student_res = $stmt->get_result();

    if ($student_res->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "ID '$scanned_id' not found in database."]);
        exit();
    }

    $student = $student_res->fetch_assoc();
    $s_id      = $student['Student_Number'];         
    $full_name = $student['First_Name'] . " " . $student['Last_Name'];
    $program   = $student['Program'] ?? 'No Program';

    // 3. CHECK FOR OPEN SESSION
    $check_stmt = $conn->prepare("SELECT Log_ID, Time_In FROM entry_logs WHERE Student_Number = ? AND Scan_Date = CURDATE() AND Time_Out IS NULL LIMIT 1");
    if (!$check_stmt) throw new Exception("Prepare failed: " . $conn->error);

    $check_stmt->bind_param("s", $s_id);
    $check_stmt->execute();
    $open_log = $check_stmt->get_result()->fetch_assoc();

    if ($open_log) {
        // --- ACTION: LOG OUT ---
        $log_id = $open_log['Log_ID'];
        $t_in   = $open_log['Time_In'];

        $start      = new DateTime($t_in);
        $end        = new DateTime($current_time);
        $diff       = $start->diff($end);
        $time_spent = $diff->format('%H:%I:%S');

        $upd = $conn->prepare("UPDATE entry_logs SET Time_Out = ?, Time_Spent = ?, Status = 'Completed' WHERE Log_ID = ?");
        if (!$upd) throw new Exception("Prepare failed: " . $conn->error);

        $upd->bind_param("ssi", $current_time, $time_spent, $log_id);

        if ($upd->execute()) {
            echo json_encode([
                "status"     => "success",
                "student_id" => $s_id,
                "full_name"  => $full_name,
                "program"    => $program,
                "action"     => "Out",
                "time_spent" => $time_spent,
                "message"    => "Successfully logged Out"
            ]);
        }
    } else {
        // --- ACTION: LOG IN ---
        $ins = $conn->prepare("INSERT INTO entry_logs (Student_Number, Scan_Date, Time_In, Status) VALUES (?, ?, ?, 'Active')");
        if (!$ins) throw new Exception("Prepare failed: " . $conn->error);

        $ins->bind_param("sss", $s_id, $current_date, $current_time);

        if ($ins->execute()) {
            echo json_encode([
                "status"     => "success",
                "student_id" => $s_id,
                "full_name"  => $full_name,
                "program"    => $program,
                "action"     => "In",
                "message"    => "Successfully logged In"
            ]);
        }
    }

} catch (Exception $e) {
    // This catches fatal database errors and outputs them so you can see exactly what broke
    echo json_encode([
        "status" => "error", 
        "message" => "Server Error: " . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) $conn->close();
}
?>