<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

// Scope all queries to this admin
$admin_id = intval($_GET['admin_id'] ?? $_POST['admin_id'] ?? 0);
if ($admin_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Missing or invalid admin_id."]);
    exit();
}

$today = date('Y-m-d');

// 1. Total Visits today (this admin only) — use prepared statement
$stmt = mysqli_prepare($conn,
    "SELECT COUNT(*) as total FROM entry_logs WHERE admin_id = ? AND scan_date = ?"
);
if (!$stmt) {
    echo json_encode(["status" => "error", "message" => "DB prepare error (total): " . mysqli_error($conn)]);
    exit();
}
mysqli_stmt_bind_param($stmt, "is", $admin_id, $today);
mysqli_stmt_execute($stmt);
$total_result = mysqli_stmt_get_result($stmt);
$total_data   = mysqli_fetch_assoc($total_result);
mysqli_stmt_close($stmt);

// 2. Department Breakdown for Pie Chart (this admin only) — use prepared statement
$stmt2 = mysqli_prepare($conn,
    "SELECT d.code AS Department, COUNT(l.log_id) AS count
     FROM entry_logs l
     JOIN students s ON l.student_number = s.student_number
     JOIN programs p ON s.program_id = p.id
     JOIN departments d ON p.department_id = d.id
     WHERE l.admin_id = ? AND l.scan_date = ?
     GROUP BY d.id
     ORDER BY count DESC"
);
if (!$stmt2) {
    echo json_encode(["status" => "error", "message" => "DB prepare error (pie): " . mysqli_error($conn)]);
    exit();
}
mysqli_stmt_bind_param($stmt2, "is", $admin_id, $today);
mysqli_stmt_execute($stmt2);
$pie_result = mysqli_stmt_get_result($stmt2);

$pie_stats = [];
if ($pie_result) {
    while ($row = mysqli_fetch_assoc($pie_result)) {
        $pie_stats[] = [
            "label" => $row['Department'] ?: 'Unknown',
            "value" => (int) $row['count'],
        ];
    }
}
mysqli_stmt_close($stmt2);

echo json_encode([
    "status"       => "success",
    "total_visits" => (int) ($total_data['total'] ?? 0),
    "pie_stats"    => $pie_stats,
]);
?>