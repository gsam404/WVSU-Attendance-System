<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

error_reporting(E_ALL);
ini_set('display_errors', 0);

date_default_timezone_set('Asia/Manila');

include 'db_connect.php';

$admin_id   = intval($_POST['admin_id'] ?? 0);
$scanned_id = strtoupper(trim($_POST['scanned_id'] ?? ''));

if (empty($scanned_id)) {
    echo json_encode(["status" => "error", "message" => "No ID provided to scanner."]);
    exit();
}

$current_time = date("H:i:s");
$current_date = date("Y-m-d");

try {
    $conn->query("SET time_zone = '+08:00'");

    // 1. AUTO-LOGOUT LOGIC
    if ($admin_id > 0) {
        $conn->query("UPDATE entry_logs 
                      SET Time_Out = '18:00:00', 
                          Status = 'Auto-Logged-Out',
                          Time_Spent = TIMEDIFF('18:00:00', Time_In)
                      WHERE admin_id = $admin_id
                        AND Time_Out IS NULL 
                        AND (Scan_Date < CURDATE() OR (Scan_Date = CURDATE() AND CURTIME() > '18:00:00'))");
    } else {
        $conn->query("UPDATE entry_logs 
                      SET Time_Out = '18:00:00', 
                          Status = 'Auto-Logged-Out',
                          Time_Spent = TIMEDIFF('18:00:00', Time_In)
                      WHERE Time_Out IS NULL 
                        AND (Scan_Date < CURDATE() OR (Scan_Date = CURDATE() AND CURTIME() > '18:00:00'))");
    }

    // 2. GET STUDENT INFO
    if ($admin_id > 0) {
        $stmt = $conn->prepare("SELECT Student_Number, First_Name, Last_Name, Program, admin_id
                                FROM students 
                                WHERE TRIM(Student_Number) = ? AND admin_id = ? 
                                LIMIT 1");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
        $stmt->bind_param("si", $scanned_id, $admin_id);
    } else {
        $stmt = $conn->prepare("SELECT Student_Number, First_Name, Last_Name, Program, admin_id
                                FROM students 
                                WHERE TRIM(Student_Number) = ? 
                                LIMIT 1");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
        $stmt->bind_param("s", $scanned_id);
    }

    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Student ID '$scanned_id' not found in the system."]);
        exit();
    }

    $s_id = $first_name = $last_name = $program = $resolved_admin = null;
    $stmt->bind_result($s_id, $first_name, $last_name, $program, $resolved_admin);
    $stmt->fetch();
    $stmt->close();

    $full_name = $first_name . " " . $last_name;
    $program   = $program ?? 'No Program';

    // 3. CHECK FOR OPEN SESSION
    $check_stmt = $conn->prepare("SELECT Log_ID, Time_In FROM entry_logs 
                                  WHERE Student_Number = ? AND admin_id = ?
                                    AND Scan_Date = CURDATE() AND Time_Out IS NULL 
                                  LIMIT 1");
    if (!$check_stmt) throw new Exception("Prepare failed: " . $conn->error);

    $check_stmt->bind_param("si", $s_id, $resolved_admin);
    $check_stmt->execute();
    $check_stmt->store_result();

    $log_id = null;
    $t_in   = null;
    $check_stmt->bind_result($log_id, $t_in);
    $check_stmt->fetch();
    $has_open_log = $check_stmt->num_rows > 0;
    $check_stmt->close();

    if ($has_open_log && $t_in !== null) {
        // --- ACTION: LOG OUT ---
        //  FIXED: only create DateTime if $t_in is not null
        $start      = new DateTime($t_in);
        $end        = new DateTime($current_time);
        $diff       = $start->diff($end);
        $time_spent = $diff->format('%H:%I:%S');

        $upd = $conn->prepare("UPDATE entry_logs 
                               SET Time_Out = ?, Time_Spent = ?, Status = 'Completed' 
                               WHERE Log_ID = ? AND admin_id = ?");
        if (!$upd) throw new Exception("Prepare failed: " . $conn->error);

        $upd->bind_param("ssii", $current_time, $time_spent, $log_id, $resolved_admin);

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
        $upd->close();
    } else {
        // --- ACTION: LOG IN ---
        $ins = $conn->prepare("INSERT INTO entry_logs (admin_id, Student_Number, Scan_Date, Time_In, Status) 
                               VALUES (?, ?, ?, ?, 'Active')");
        if (!$ins) throw new Exception("Prepare failed: " . $conn->error);

        $ins->bind_param("isss", $resolved_admin, $s_id, $current_date, $current_time);

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
        $ins->close();
    }

} catch (Exception $e) {
    echo json_encode([
        "status"  => "error",
        "message" => "Server Error: " . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) $conn->close();
}
?>