<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

// 1. Use your connection file
include 'db_connect.php';

// 2. Capture the ID from Flutter
$scanned_id = $_POST['scanned_id'] ?? null;

if (!$scanned_id) {
    echo json_encode(["status" => "error", "message" => "No ID received by server"]);
    $conn->close();
    exit;
}

// 3. Clean the input
$scanned_id = trim($scanned_id);

// 4. Verify the student exists in the Students table
$stmt = $conn->prepare("SELECT * FROM Students WHERE Student_ID LIKE ? LIMIT 1");
$stmt->bind_param("s", $scanned_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $student_id = $row['Student_ID'];
    $full_name = $row['First_Name'] . " " . $row['Last_Name'];
    $program = $row['Program'] ?? ''; // Added fallback in case Program isn't there
    
    // ---------------------------------------------------------
    // SMART IN/OUT LOGIC
    // Check the latest log for this student TODAY
    // ---------------------------------------------------------
    $check_log_stmt = $conn->prepare("SELECT Log_Type FROM Entry_Logs WHERE Student_ID = ? AND Scan_Date = CURDATE() ORDER BY Scan_Time DESC LIMIT 1");
    $check_log_stmt->bind_param("s", $student_id);
    $check_log_stmt->execute();
    $log_result = $check_log_stmt->get_result();
    
    // Default to 'In'
    $new_log_type = 'In'; 
    
    if ($log_result && $log_result->num_rows > 0) {
        $last_log = $log_result->fetch_assoc();
        // If their last scan today was 'In', then this scan must be 'Out'
        if ($last_log['Log_Type'] == 'In') {
            $new_log_type = 'Out'; 
        }
    }
    $check_log_stmt->close();
    
    // ---------------------------------------------------------
    // INSERT INTO Entry_Logs
    // ---------------------------------------------------------
    // Assuming Log_ID is Auto-Increment, so we don't need to pass it manually.
    $insert_stmt = $conn->prepare("INSERT INTO Entry_Logs (Student_ID, Log_Type, Scan_Date, Scan_Time) VALUES (?, ?, CURDATE(), CURTIME())");
    $insert_stmt->bind_param("ss", $student_id, $new_log_type);
    
    if ($insert_stmt->execute()) {
        // Success! Return the data to Flutter
        echo json_encode([
            "status" => "success",
            "student_id" => $student_id,
            "full_name" => $full_name,
            "program" => $program,
            "action" => $new_log_type, // Tells Flutter if they logged "In" or "Out"
            "message" => "Successfully logged " . $new_log_type
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Student found, but database failed to save the log."]);
    }
    
    $insert_stmt->close();
    
} else {
    // Failure: No match found in Students table
    echo json_encode(["status" => "error", "message" => "Barcode ID '$scanned_id' not found in database."]);
}

$stmt->close();
$conn->close();
?>