<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

// --- FIX 1: SET TIMEZONE ---
date_default_timezone_set('Asia/Manila'); 

include 'db_connect.php';

// --- FIX 2: SYNC DATABASE SESSION TIME ---
$conn->query("SET time_zone = '+08:00'");

$scanned_id = $_POST['scanned_id'] ?? null;

// --- FIX 3: CLEAN INPUT FOR BETTER MATCHING ---
// trim removes spaces/newlines; strtoupper handles case sensitivity
$scanned_id = strtoupper(trim($scanned_id));

$current_time = date("H:i:s");
$current_date = date("Y-m-d");

// 1. AUTO-LOGOUT LOGIC
$conn->query("UPDATE Entry_Logs 
              SET Time_Out = '18:00:00', 
                  Status = 'Auto-Logged-Out',
                  Time_Spent = TIMEDIFF('18:00:00', Time_In)
              WHERE Time_Out IS NULL 
              AND (Scan_Date < CURDATE() OR (Scan_Date = CURDATE() AND CURTIME() > '18:00:00'))");

// 2. THE GATEKEEPER
if ($current_time < "07:00:00" || $current_time > "18:00:00") {
    echo json_encode([
        "status" => "error", 
        "message" => "Library is CLOSED. Hours: 7:00 AM - 6:00 PM."
    ]);
    exit();
}

// 3. GET STUDENT INFO 
// Added TRIM() in SQL to ensure database-side cleanup
$stmt = $conn->prepare("SELECT Student_ID, First_Name, Last_Name, Program FROM Students WHERE TRIM(Student_ID) = ? LIMIT 1");
$stmt->bind_param("s", $scanned_id);
$stmt->execute();
$student_res = $stmt->get_result();

if ($student_res->num_rows === 0) {
    // We return the scanned_id in the error message to help you debug what the server received
    echo json_encode(["status" => "error", "message" => "ID '$scanned_id' not found in database."]);
    exit();
}

$student = $student_res->fetch_assoc();
$s_id = $student['Student_ID'];
$full_name = $student['First_Name'] . " " . $student['Last_Name'];
$program = $student['Program'] ?? 'No Program';

// 4. CHECK FOR OPEN SESSION
$check_stmt = $conn->prepare("SELECT Log_ID, Time_In FROM Entry_Logs WHERE Student_ID = ? AND Scan_Date = CURDATE() AND Time_Out IS NULL LIMIT 1");
$check_stmt->bind_param("s", $s_id);
$check_stmt->execute();
$open_log = $check_stmt->get_result()->fetch_assoc();

if ($open_log) {
    // --- ACTION: LOG OUT ---
    $log_id = $open_log['Log_ID'];
    $t_in = $open_log['Time_In'];

    $start = new DateTime($t_in);
    $end = new DateTime($current_time);
    $diff = $start->diff($end);
    $time_spent = $diff->format('%H:%I:%S');

    $upd = $conn->prepare("UPDATE Entry_Logs SET Time_Out = ?, Time_Spent = ?, Status = 'Completed' WHERE Log_ID = ?");
    $upd->bind_param("ssi", $current_time, $time_spent, $log_id);
    
    if ($upd->execute()) {
        echo json_encode([
            "status" => "success",
            "student_id" => $s_id, 
            "full_name" => $full_name,
            "program" => $program,
            "action" => "Out",
            "time_spent" => $time_spent,
            "message" => "Successfully logged Out"
        ]);
    }
} else {
    // --- ACTION: LOG IN ---
    $ins = $conn->prepare("INSERT INTO Entry_Logs (Student_ID, Scan_Date, Time_In, Status) VALUES (?, ?, ?, 'Active')");
    $ins->bind_param("sss", $s_id, $current_date, $current_time);
    
    if ($ins->execute()) {
        echo json_encode([
            "status" => "success",
            "student_id" => $s_id,
            "full_name" => $full_name,
            "program" => $program,
            "action" => "In",
            "message" => "Successfully logged In"
        ]);
    }
}

$conn->close();
?>