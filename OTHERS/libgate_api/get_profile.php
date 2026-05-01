<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

ini_set('display_errors', 0);
error_reporting(0);

include 'db_connect.php';

// Get the admin ID sent from Flutter after login
$id = intval($_POST['id'] ?? 0);

if ($id <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid ID."]);
    exit;
}

// Query `admins` table — NOT `users`
$stmt = $conn->prepare(
    "SELECT full_name, email, profilepicture_url
     FROM admins
     WHERE id = ?
     LIMIT 1"
);
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // Build full profile picture URL if stored as a relative path
    $picUrl = '';
    if (!empty($row['profilepicture_url'])) {
        $raw = $row['profilepicture_url'];
        $picUrl = str_starts_with($raw, 'http')
            ? $raw
            : "http://" . $_SERVER['HTTP_HOST'] . "/libgate_api/" . ltrim($raw, '/');
    }

    echo json_encode([
        "success"     => true,
        "full_name"   => $row['full_name'],
        "email"       => $row['email'],
        "profile_pic" => $picUrl,
    ]);
} else {
    echo json_encode(["success" => false, "message" => "No admin found."]);
}

$stmt->close();
$conn->close();
?>