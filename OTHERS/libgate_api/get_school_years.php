<?php
/**
 * LIBGATE - Get School Years (campus-scoped)
 * Returns the list of school_years.name for the requesting admin's campus,
 * most recent first.
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "libgate_db");

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed."
    ]));
}

$admin_id = intval($_GET['admin_id'] ?? 0);

if ($admin_id <= 0) {
    die(json_encode([
        "status" => "error",
        "message" => "Invalid Admin ID."
    ]));
}

/*
|--------------------------------------------------------------------------
| GET ADMIN CAMPUS
|--------------------------------------------------------------------------
*/

$getCampusStmt = $conn->prepare("SELECT campus_id FROM admins WHERE id = ? LIMIT 1");

if (!$getCampusStmt) {
    die(json_encode([
        "status" => "error",
        "message" => "Failed to prepare campus lookup."
    ]));
}

$getCampusStmt->bind_param("i", $admin_id);
$getCampusStmt->execute();
$result = $getCampusStmt->get_result();

if ($admin = $result->fetch_assoc()) {
    $campus_id = (int)$admin["campus_id"];
} else {
    die(json_encode([
        "status" => "error",
        "message" => "Admin not found."
    ]));
}

$getCampusStmt->close();

/*
|--------------------------------------------------------------------------
| GET SCHOOL YEARS FOR THIS CAMPUS
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT name
    FROM school_years
    WHERE campus_id = ?
    ORDER BY start_date DESC
");

if (!$stmt) {
    die(json_encode([
        "status" => "error",
        "message" => "Failed to prepare school year lookup."
    ]));
}

$stmt->bind_param("i", $campus_id);
$stmt->execute();
$result = $stmt->get_result();

$years = [];
while ($row = $result->fetch_assoc()) {
    $years[] = $row['name'];
}

$stmt->close();
$conn->close();

echo json_encode([
    "status" => "success",
    "campus_id" => $campus_id,
    "data" => $years
]);
?>