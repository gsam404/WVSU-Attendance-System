<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// If the browser is sending an OPTIONS pre-flight request, stop here and say "OK"
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$today = date('Y-m-d');

// Changed 'Date' to 'Scan_Date'
$total_query = "SELECT COUNT(*) as total FROM Entry_Logs WHERE Scan_Date = '$today'";
$total_result = mysqli_query($conn, $total_query);
$total_data = mysqli_fetch_assoc($total_result);

// Changed 'l.Date' to 'l.Scan_Date'
// 2. Get Program Breakdown for Pie Chart (Replaced College with Program)
$pie_query = "SELECT s.Program, COUNT(l.Log_ID) as count 
              FROM Entry_Logs l 
              JOIN Students s ON l.Student_ID = s.Student_ID 
              WHERE l.Scan_Date = '$today' 
              GROUP BY s.Program";
$pie_result = mysqli_query($conn, $pie_query);

$pie_stats = [];
while($row = mysqli_fetch_assoc($pie_result)) {
    $pie_stats[] = [
        "label" => $row['Program'], // <--- Changed this from College
        "value" => (int)$row['count']
    ];
}

echo json_encode([
    "status" => "success",
    "total_visits" => $total_data['total'],
    "pie_stats" => $pie_stats
]);
?>