<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

error_reporting(E_ALL);
ini_set('display_errors', 0);

date_default_timezone_set('Asia/Manila');

include 'db_connect.php';

// admin_id is now OPTIONAL — if not sent, scans across all students
$admin_id   = intval($_POST['admin_id'] ?? 0);
$scanned_id = strtoupper(trim($_POST['scanned_id'] ?? ''));

if (empty($scanned_id)) {
    echo json_encode(["status" => "error", "message" => "No ID provided to scanner."]);
    exit();
}

$current_time = date("H:i:s");
$current_date = date("Y-m-d");
$school_year_id = null;

try {
    $conn->query("SET time_zone = '+08:00'");

    $sy_stmt = $conn->prepare("SELECT id FROM school_years WHERE ? BETWEEN start_date AND end_date LIMIT 1");
    if ($sy_stmt) {
        $sy_stmt->bind_param("s", $current_date);
        $sy_stmt->execute();
        $sy_res = $sy_stmt->get_result();
        if ($sy_res && $sy_row = $sy_res->fetch_assoc()) {
            $school_year_id = intval($sy_row['id']);
        }
        $sy_stmt->close();
    }

    // 1. AUTO-LOGOUT LOGIC
    if ($admin_id > 0) {
        // Scoped to this admin only
        $conn->query("UPDATE entry_logs 
                      SET time_out = '18:00:00', 
                          status = 'Auto-Logged-Out',
                          time_spent = TIMEDIFF('18:00:00', time_in)
                      WHERE admin_id = $admin_id
                        AND time_out IS NULL 
                        AND (scan_date < CURDATE() OR (scan_date = CURDATE() AND CURTIME() > '18:00:00'))");
    } else {
        // No admin scope — apply to all
        $conn->query("UPDATE entry_logs 
                      SET time_out = '18:00:00', 
                          status = 'Auto-Logged-Out',
                          time_spent = TIMEDIFF('18:00:00', time_in)
                      WHERE time_out IS NULL 
                        AND (scan_date < CURDATE() OR (scan_date = CURDATE() AND CURTIME() > '18:00:00'))");
    }

    // 2. GET STUDENT INFO
    if ($admin_id > 0) {
        // Scoped: only students belonging to this admin
        $stmt = $conn->prepare("SELECT s.student_number, s.first_name, s.last_name, COALESCE(p.code, 'No Program') AS program, s.admin_id
                                FROM students s
                                LEFT JOIN programs p ON s.program_id = p.id
                                WHERE TRIM(s.student_number) = ? AND s.admin_id = ?
                                LIMIT 1");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
        $stmt->bind_param("si", $scanned_id, $admin_id);
    } else {
        // No admin scope — search all students
        $stmt = $conn->prepare("SELECT s.student_number, s.first_name, s.last_name, COALESCE(p.code, 'No Program') AS program, s.admin_id
                                FROM students s
                                LEFT JOIN programs p ON s.program_id = p.id
                                WHERE TRIM(s.student_number) = ?
                                LIMIT 1");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
        $stmt->bind_param("s", $scanned_id);
    }

    $stmt->execute();
    $student_res = $stmt->get_result();

    if ($student_res->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Student ID '$scanned_id' not found in the system."]);
        exit();
    }

    $student        = $student_res->fetch_assoc();
    $s_id           = $student['student_number'];
    $full_name      = $student['first_name'] . " " . $student['last_name'];
    $program        = $student['program'] ?? 'No Program';
    $resolved_admin = $student['admin_id']; // Use the student's own admin_id for logs


    // 3. CHECK FOR OPEN SESSION
    $check_stmt = $conn->prepare("SELECT log_id, time_in FROM entry_logs 
                                  WHERE student_number = ? AND admin_id = ?
                                    AND scan_date = CURDATE() AND time_out IS NULL 
                                  LIMIT 1");
    if (!$check_stmt) throw new Exception("Prepare failed: " . $conn->error);

    $check_stmt->bind_param("si", $s_id, $resolved_admin);
    $check_stmt->execute();
    $open_log = $check_stmt->get_result()->fetch_assoc();

    if ($open_log) {
        // --- ACTION: LOG OUT ---
        $log_id = $open_log['log_id'];
        $t_in   = $open_log['time_in'];

        $start      = new DateTime($t_in);
        $end        = new DateTime($current_time);
        $diff       = $start->diff($end);
        $time_spent = $diff->format('%H:%I:%S');

        $upd = $conn->prepare("UPDATE entry_logs 
                               SET time_out = ?, time_spent = ?, status = 'Completed' 
                               WHERE log_id = ? AND admin_id = ?");
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
    } else {
        // --- ACTION: LOG IN ---
        if ($school_year_id !== null) {
            $ins = $conn->prepare("INSERT INTO entry_logs (admin_id, student_number, scan_date, time_in, status, school_year_id) 
                                   VALUES (?, ?, ?, ?, 'Active', ?)");
            if (!$ins) throw new Exception("Prepare failed: " . $conn->error);
            $ins->bind_param("isssi", $resolved_admin, $s_id, $current_date, $current_time, $school_year_id);
        } else {
            $ins = $conn->prepare("INSERT INTO entry_logs (admin_id, student_number, scan_date, time_in, status) 
                                   VALUES (?, ?, ?, ?, 'Active')");
            if (!$ins) throw new Exception("Prepare failed: " . $conn->error);
            $ins->bind_param("isss", $resolved_admin, $s_id, $current_date, $current_time);
        }

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
    echo json_encode([
        "status"  => "error",
        "message" => "Server Error: " . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) $conn->close();
}
?>