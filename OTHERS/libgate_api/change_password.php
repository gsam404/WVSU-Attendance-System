<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connect.php';

$raw  = file_get_contents("php://input");
$json = json_decode($raw, true);

$admin_id = $_POST['id']           ?? $json['id']           ?? '';
$old_pass = $_POST['old_password'] ?? $json['old_password'] ?? '';
$new_pass = $_POST['new_password'] ?? $json['new_password'] ?? '';

if (empty($admin_id) || empty($old_pass) || empty($new_pass)) {
    echo json_encode([
        "success"  => false,
        "message"  => "Missing fields",
        "received" => [
            "id"        => $admin_id,
            "old_empty" => empty($old_pass),
            "new_empty" => empty($new_pass)
        ]
    ]);
    exit();
}

// Find admin
$stmt = $conn->prepare("SELECT password_hash FROM admins WHERE id = ?");
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    exit();
}

$stmt->bind_param("i", $admin_id);
$stmt->execute();
$result = $stmt->get_result();
$admin  = $result->fetch_assoc();
$stmt->close();

if (!$admin) {
    echo json_encode(["success" => false, "message" => "Admin not found. id=" . $admin_id]);
    exit();
}

// Verify current password
if (!password_verify($old_pass, $admin['password_hash'])) {
    echo json_encode(["success" => false, "message" => "Current password is incorrect"]);
    exit();
}

// Update new password
$new_hash = password_hash($new_pass, PASSWORD_DEFAULT);
$update   = $conn->prepare("UPDATE admins SET password_hash = ? WHERE id = ?");
if (!$update) {
    echo json_encode(["success" => false, "message" => "Update prepare failed: " . $conn->error]);
    exit();
}

$update->bind_param("si", $new_hash, $admin_id);

if ($update->execute()) {
    echo json_encode(["success" => true, "message" => "Password updated successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Execute failed: " . $update->error]);
}

$update->close();
$conn->close();
?>