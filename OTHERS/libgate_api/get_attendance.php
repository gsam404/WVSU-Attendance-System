<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

try {

    // ===============================
    // GET FILTER PARAMETERS
    // ===============================
    $date = $_GET['date'] ?? null;
    $month = $_GET['month'] ?? null;
    $department = $_GET['department'] ?? null;
    $program = $_GET['program'] ?? null;

    // ===============================
    // BASE QUERY
    // ===============================
    $query = "SELECT 
                l.Scan_Date as date, 
                l.Time_In as signIn, 
                l.Time_Out as signOut, 
                CONCAT(s.First_Name, ' ', s.Last_Name) as name, 
                s.Student_Number as studentId, 
                s.Year_Level as year, 
                p.code as course, 
                d.code as department 
              FROM entry_logs l
              JOIN students s ON l.Student_Number = s.Student_Number
              LEFT JOIN programs p ON s.Program = p.code
              LEFT JOIN departments d ON p.department_id = d.id
              WHERE 1=1";

    // ===============================
    // APPLY FILTERS
    // ===============================
    if ($date) {
        $query .= " AND DATE(l.Scan_Date) = '$date'";
    }

    if ($month) {
        $query .= " AND MONTH(l.Scan_Date) = '$month'";
    }

    if ($department && $department !== 'All Departments') {
        $query .= " AND d.code = '$department'";
    }

    if ($program && $program !== 'All Programs') {
        $query .= " AND p.code = '$program'";
    }

    $query .= " ORDER BY l.Scan_Date DESC, l.Time_In DESC";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Database Query Failed: " . $conn->error);
    }

    $attendance_data = [];

    while ($row = $result->fetch_assoc()) {
        $row['signOut'] = $row['signOut'] ?? '--:--';
        $row['course'] = $row['course'] ?? 'N/A';
        $row['department'] = $row['department'] ?? 'N/A';

        $attendance_data[] = $row;
    }

    echo json_encode($attendance_data);

} catch (Exception $e) {
    echo json_encode([["error" => $e->getMessage()]]);
}

if (isset($conn)) {
    $conn->close();
}
?>