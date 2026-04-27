<?php
// Prevent PHP errors from breaking the JSON response
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php'; 

if (!$conn) {
    echo json_encode(["error" => "Database connection failed: " . mysqli_connect_error()]);
    exit();
}

$weekly = array_fill(0, 7, 0); 
$monthly = array_fill(0, 12, 0); 
$peakDay = "None";
$topDepartment = "None";
$topCourse = "None";

// 1. Weekly Query
$weekly_query = "SELECT DAYOFWEEK(Scan_Date) as day_num, COUNT(*) as count 
                 FROM entry_logs 
                 WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
                 GROUP BY day_num";
$weekly_result = mysqli_query($conn, $weekly_query);

if ($weekly_result) {
    while($row = mysqli_fetch_assoc($weekly_result)) {
        $index = (int)$row['day_num'] - 1; 
        $weekly[$index] = (int)$row['count'];
    }
}

// 2. Monthly Query
$monthly_query = "SELECT MONTH(Scan_Date) as month_num, COUNT(*) as count 
                  FROM entry_logs 
                  WHERE YEAR(Scan_Date) = YEAR(CURDATE()) 
                  GROUP BY month_num";
$monthly_result = mysqli_query($conn, $monthly_query);

if ($monthly_result) {
    while($row = mysqli_fetch_assoc($monthly_result)) {
        $index = (int)$row['month_num'] - 1; 
        $monthly[$index] = (int)$row['count'];
    }
}

// 3. Peak Day Query
$peak_query = "SELECT DAYNAME(Scan_Date) as day_name, COUNT(*) as count 
               FROM entry_logs 
               WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
               GROUP BY day_name 
               ORDER BY count DESC LIMIT 1";
$peak_result = mysqli_query($conn, $peak_query);

if($peak_result && $row = mysqli_fetch_assoc($peak_result)) {
    $peakDay = $row['day_name'];
}

// 4. Top Department (USING REAL DEPARTMENTS)
$top_dept_query = "SELECT d.code as Department, COUNT(l.Log_ID) as count 
                   FROM entry_logs l 
                   JOIN students s ON l.Student_Number = s.Student_Number 
                   JOIN programs p ON s.Program = p.code
                   JOIN departments d ON p.department_id = d.id
                   GROUP BY d.id 
                   ORDER BY count DESC LIMIT 1";
$top_dept_result = mysqli_query($conn, $top_dept_query);

if($top_dept_result && $row = mysqli_fetch_assoc($top_dept_result)) {
    $topDepartment = $row['Department'] ?? "None";
}

// 5. Top Course
$top_course_query = "SELECT p.code as Course, COUNT(l.Log_ID) as count 
                     FROM entry_logs l 
                     JOIN students s ON l.Student_Number = s.Student_Number 
                     JOIN programs p ON s.Program = p.code
                     GROUP BY p.id 
                     ORDER BY count DESC LIMIT 1";
$top_course_result = mysqli_query($conn, $top_course_query);

if($top_course_result && $row = mysqli_fetch_assoc($top_course_result)) {
    $topCourse = $row['Course'] ?? "None";
}

echo json_encode([
    "weekly" => $weekly,
    "monthly" => $monthly,
    "peakDay" => $peakDay,
    "topDepartment" => $topDepartment,
    "topCourse" => $topCourse
]);
?>