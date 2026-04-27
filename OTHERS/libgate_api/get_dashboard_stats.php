<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

$today = date('Y-m-d');

// 1. Total Visits
$total_query = "SELECT COUNT(*) as total FROM entry_logs WHERE Scan_Date = '$today'";
$total_result = mysqli_query($conn, $total_query);
$total_data = mysqli_fetch_assoc($total_result);

// 2. Department Breakdown for Pie Chart
$pie_query = "SELECT d.code as Department, COUNT(l.Log_ID) as count 
              FROM entry_logs l 
              JOIN students s ON l.Student_Number = s.Student_Number 
              JOIN programs p ON s.Program = p.code
              JOIN departments d ON p.department_id = d.id
              WHERE l.Scan_Date = '$today' 
              GROUP BY d.id";
$pie_result = mysqli_query($conn, $pie_query);

$pie_stats = [];
if ($pie_result) {
    while($row = mysqli_fetch_assoc($pie_result)) {
        $pie_stats[] = [
            "label" => $row['Department'] ? $row['Department'] : 'Unknown',
            "value" => (int)$row['count']
        ];
    }
}

echo json_encode([
    "status" => "success",
    "total_visits" => $total_data['total'] ?? 0,
    "pie_stats" => $pie_stats
]);
?>