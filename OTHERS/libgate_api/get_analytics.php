<?php
// 1. TURN ON ERROR REPORTING (This stops the white page)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Force JSON response so Flutter can parse it correctly
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

// Check connection again just in case
if (!$conn) {
    die(json_encode(["error" => "Database connection failed: " . mysqli_connect_error()]));
}

// Initialize default values
$weekly = array_fill(0, 7, 0);   // 7 days: Sun-Sat
$monthly = array_fill(0, 12, 0); // 12 months: Jan-Dec

// ─── WEEKLY STATS ────────────────────────────────────────────────────────────

// Weekly visits per day
$weekly_query = "SELECT DAYOFWEEK(Scan_Date) as day_num, COUNT(*) as count 
                 FROM entry_logs 
                 WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
                 GROUP BY day_num";
$weekly_result = mysqli_query($conn, $weekly_query);
if (!$weekly_result) { die(json_encode(["error" => "Weekly Query Failed: " . mysqli_error($conn)])); }

while ($row = mysqli_fetch_assoc($weekly_result)) {
    $index = (int)$row['day_num'] - 1; // DAYOFWEEK: 1=Sun → index 0
    $weekly[$index] = (int)$row['count'];
}

// Peak day of the current week
$weekly_peak_query = "SELECT DAYNAME(Scan_Date) as day_name, COUNT(*) as count 
                      FROM entry_logs 
                      WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
                      GROUP BY day_name 
                      ORDER BY count DESC LIMIT 1";
$weekly_peak_result = mysqli_query($conn, $weekly_peak_query);
if (!$weekly_peak_result) { die(json_encode(["error" => "Weekly Peak Query Failed: " . mysqli_error($conn)])); }
$weeklyPeakDay = "None";
if ($row = mysqli_fetch_assoc($weekly_peak_result)) {
    $weeklyPeakDay = $row['day_name'];
}

// Top department for the current week
$weekly_dept_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
                      FROM entry_logs l 
                      JOIN students s ON l.Student_Number = s.Student_Number 
                      WHERE YEARWEEK(l.Scan_Date, 1) = YEARWEEK(CURDATE(), 1)
                      GROUP BY s.Program 
                      ORDER BY count DESC LIMIT 1";
$weekly_dept_result = mysqli_query($conn, $weekly_dept_query);
if (!$weekly_dept_result) { die(json_encode(["error" => "Weekly Dept Query Failed: " . mysqli_error($conn)])); }
$weeklyTopDepartment = "None";
if ($row = mysqli_fetch_assoc($weekly_dept_result)) {
    $weeklyTopDepartment = $row['Program'] ?? "None";
}

// Top course for the current week
$weekly_course_query = "SELECT s.Program as course, COUNT(l.Log_ID) as count 
                        FROM entry_logs l 
                        JOIN students s ON l.Student_Number = s.Student_Number 
                        WHERE YEARWEEK(l.Scan_Date, 1) = YEARWEEK(CURDATE(), 1)
                        GROUP BY s.Program 
                        ORDER BY count DESC LIMIT 1";
$weekly_course_result = mysqli_query($conn, $weekly_course_query);
if (!$weekly_course_result) { die(json_encode(["error" => "Weekly Course Query Failed: " . mysqli_error($conn)])); }
$weeklyTopCourse = "None";
if ($row = mysqli_fetch_assoc($weekly_course_result)) {
    $weeklyTopCourse = $row['course'] ?? "None";
}

// ─── MONTHLY STATS ───────────────────────────────────────────────────────────

// Monthly visits per month
$monthly_query = "SELECT MONTH(Scan_Date) as month_num, COUNT(*) as count 
                  FROM entry_logs 
                  WHERE YEAR(Scan_Date) = YEAR(CURDATE()) 
                  GROUP BY month_num";
$monthly_result = mysqli_query($conn, $monthly_query);
if (!$monthly_result) { die(json_encode(["error" => "Monthly Query Failed: " . mysqli_error($conn)])); }

while ($row = mysqli_fetch_assoc($monthly_result)) {
    $index = (int)$row['month_num'] - 1; // MONTH: 1=Jan → index 0
    $monthly[$index] = (int)$row['count'];
}

// Peak month of the current year
$monthly_peak_query = "SELECT MONTHNAME(Scan_Date) as month_name, COUNT(*) as count 
                       FROM entry_logs 
                       WHERE YEAR(Scan_Date) = YEAR(CURDATE()) 
                       GROUP BY month_name 
                       ORDER BY count DESC LIMIT 1";
$monthly_peak_result = mysqli_query($conn, $monthly_peak_query);
if (!$monthly_peak_result) { die(json_encode(["error" => "Monthly Peak Query Failed: " . mysqli_error($conn)])); }
$monthlyPeakMonth = "None";
if ($row = mysqli_fetch_assoc($monthly_peak_result)) {
    $monthlyPeakMonth = $row['month_name'];
}

// Top department for the current year
$monthly_dept_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
                       FROM entry_logs l 
                       JOIN students s ON l.Student_Number = s.Student_Number 
                       WHERE YEAR(l.Scan_Date) = YEAR(CURDATE())
                       GROUP BY s.Program 
                       ORDER BY count DESC LIMIT 1";
$monthly_dept_result = mysqli_query($conn, $monthly_dept_query);
if (!$monthly_dept_result) { die(json_encode(["error" => "Monthly Dept Query Failed: " . mysqli_error($conn)])); }
$monthlyTopDepartment = "None";
if ($row = mysqli_fetch_assoc($monthly_dept_result)) {
    $monthlyTopDepartment = $row['Program'] ?? "None";
}

// Top course for the current year
$monthly_course_query = "SELECT s.Program as course, COUNT(l.Log_ID) as count 
                         FROM entry_logs l 
                         JOIN students s ON l.Student_Number = s.Student_Number 
                         WHERE YEAR(l.Scan_Date) = YEAR(CURDATE())
                         GROUP BY s.Program 
                         ORDER BY count DESC LIMIT 1";
$monthly_course_result = mysqli_query($conn, $monthly_course_query);
if (!$monthly_course_result) { die(json_encode(["error" => "Monthly Course Query Failed: " . mysqli_error($conn)])); }
$monthlyTopCourse = "None";
if ($row = mysqli_fetch_assoc($monthly_course_result)) {
    $monthlyTopCourse = $row['course'] ?? "None";
}

// ─── RETURN JSON 
echo json_encode([
    // Chart data
    "weekly"  => array_values($weekly),
    "monthly" => array_values($monthly),

    // Weekly stat cards
    "weeklyPeakDay"        => $weeklyPeakDay,
    "weeklyTopDepartment"  => $weeklyTopDepartment,
    "weeklyTopCourse"      => $weeklyTopCourse,

    // Monthly stat cards
    "monthlyPeakMonth"     => $monthlyPeakMonth,
    "monthlyTopDepartment" => $monthlyTopDepartment,
    "monthlyTopCourse"     => $monthlyTopCourse,
]);
?>