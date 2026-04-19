<?php
// 1. TURN ON ERROR REPORTING (This stops the white page)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php'; 

// Check connection again just in case
if (!$conn) {
    die("Database connection failed: " . mysqli_connect_error());
}

$weekly = array_fill(0, 7, 0); 
$monthly = array_fill(0, 12, 0); 
$peakDay = "None";
$topDepartment = "None";
$topCourse = "None";

// 1. Weekly Query
$weekly_query = "SELECT DAYOFWEEK(Scan_Date) as day_num, COUNT(*) as count 
                 FROM Entry_Logs 
                 WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
                 GROUP BY day_num";
$weekly_result = mysqli_query($conn, $weekly_query);
if (!$weekly_result) { die("Weekly Query Failed: " . mysqli_error($conn)); } // <--- Catches errors!

while($row = mysqli_fetch_assoc($weekly_result)) {
    $index = (int)$row['day_num'] - 1; 
    $weekly[$index] = (int)$row['count'];
}

// 2. Monthly Query
$monthly_query = "SELECT MONTH(Scan_Date) as month_num, COUNT(*) as count 
                  FROM Entry_Logs 
                  WHERE YEAR(Scan_Date) = YEAR(CURDATE()) 
                  GROUP BY month_num";
$monthly_result = mysqli_query($conn, $monthly_query);
if (!$monthly_result) { die("Monthly Query Failed: " . mysqli_error($conn)); }

while($row = mysqli_fetch_assoc($monthly_result)) {
    $index = (int)$row['month_num'] - 1; 
    $monthly[$index] = (int)$row['count'];
}

// 3. Peak Day Query
$peak_query = "SELECT DAYNAME(Scan_Date) as day_name, COUNT(*) as count 
               FROM Entry_Logs 
               WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
               GROUP BY day_name 
               ORDER BY count DESC LIMIT 1";
$peak_result = mysqli_query($conn, $peak_query);
if (!$peak_result) { die("Peak Query Failed: " . mysqli_error($conn)); }

if($row = mysqli_fetch_assoc($peak_result)) {
    $peakDay = $row['day_name'];
}

// 4. Top Department (Replaced College with Program)
$top_dept_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
                   FROM Entry_Logs l 
                   JOIN Students s ON l.Student_ID = s.Student_ID 
                   GROUP BY s.Program 
                   ORDER BY count DESC LIMIT 1";
$top_dept_result = mysqli_query($conn, $top_dept_query);
if (!$top_dept_result) { die("Top Dept Query Failed: " . mysqli_error($conn)); }

if($row = mysqli_fetch_assoc($top_dept_result)) {
    $topDepartment = $row['Program'] ?? "None";
}

// 5. Top Course
$top_course_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
                     FROM Entry_Logs l 
                     JOIN Students s ON l.Student_ID = s.Student_ID 
                     GROUP BY s.Program 
                     ORDER BY count DESC LIMIT 1";
$top_course_result = mysqli_query($conn, $top_course_query);
if (!$top_course_result) { die("Top Course Query Failed: " . mysqli_error($conn)); }

if($row = mysqli_fetch_assoc($top_course_result)) {
    $topCourse = $row['Program'] ?? "None";
}

// If it survives everything above, it will print the JSON!
echo json_encode([
    "weekly" => $weekly,
    "monthly" => $monthly,
    "peakDay" => $peakDay,
    "topDepartment" => $topDepartment,
    "topCourse" => $topCourse
]);
?>