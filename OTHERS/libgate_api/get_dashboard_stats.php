<?php
// 1. TURN ON ERROR REPORTING
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Force JSON response
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

if (!$conn) {
    die(json_encode(["error" => "Database connection failed: " . mysqli_connect_error()]));
}

$today = date('Y-m-d');

// 1. Total visits today
$total_query = "SELECT COUNT(*) as total FROM entry_logs WHERE Scan_Date = '$today'";
$total_result = mysqli_query($conn, $total_query);
if (!$total_result) { die(json_encode(["error" => "Total Query Failed: " . mysqli_error($conn)])); }
$total_data = mysqli_fetch_assoc($total_result);

// 2. Top department today (fixed: Student_Number instead of Student_ID)
$top_dept_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
                   FROM entry_logs l 
                   JOIN students s ON l.Student_Number = s.Student_Number 
                   WHERE l.Scan_Date = '$today'
                   GROUP BY s.Program 
                   ORDER BY count DESC LIMIT 1";
$top_dept_result = mysqli_query($conn, $top_dept_query);
if (!$top_dept_result) { die(json_encode(["error" => "Top Dept Query Failed: " . mysqli_error($conn)])); }
$top_dept_data = mysqli_fetch_assoc($top_dept_result);
$top_dept = $top_dept_data['Program'] ?? "No Logs";

// 3. Program breakdown for pie chart (fixed: Student_Number instead of Student_ID)
$pie_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
              FROM entry_logs l 
              JOIN students s ON l.Student_Number = s.Student_Number 
              WHERE l.Scan_Date = '$today' 
              GROUP BY s.Program";
$pie_result = mysqli_query($conn, $pie_query);
if (!$pie_result) { die(json_encode(["error" => "Pie Query Failed: " . mysqli_error($conn)])); }

$pie_stats = [];
while ($row = mysqli_fetch_assoc($pie_result)) {
    $pie_stats[] = [
        "label" => $row['Program'],
        "count" => (int)$row['count']
    ];
}

// 4. Weekly visits for line chart (Sun=0 to Sat=6, current week)
$weekly_query = "SELECT DAYOFWEEK(Scan_Date) as day_num, COUNT(*) as count 
                 FROM entry_logs 
                 WHERE YEARWEEK(Scan_Date, 1) = YEARWEEK(CURDATE(), 1) 
                 GROUP BY day_num";
$weekly_result = mysqli_query($conn, $weekly_query);
if (!$weekly_result) { die(json_encode(["error" => "Weekly Query Failed: " . mysqli_error($conn)])); }

$weekly = array_fill(0, 7, 0); // Sun to Sat
while ($row = mysqli_fetch_assoc($weekly_result)) {
    $index = (int)$row['day_num'] - 1; // DAYOFWEEK: 1=Sun → index 0
    $weekly[$index] = (int)$row['count'];
}

// Return everything
echo json_encode([
    "status" => "success",
    "total_today" => (int)$total_data['total'],
    "top_dept" => $top_dept,
    "pie_stats" => $pie_stats,
    "weekly" => array_values($weekly)
]);
?>