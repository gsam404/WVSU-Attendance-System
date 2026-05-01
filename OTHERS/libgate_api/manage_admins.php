<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit; }

$host = "localhost";
$user = "root";
$pass = "";
$db   = "libgate_db";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "DB Connection failed"]);
    exit;
}

$request_body = file_get_contents('php://input');
$data = json_decode($request_body, true);
$input = array_merge($_GET, $_POST, $data ?? []);

$action         = $input['action'] ?? '';
$requester_role = trim($input['requester_role'] ?? '');
$is_main_admin  = (strcasecmp($requester_role, 'main_admin') == 0 || strcasecmp($requester_role, 'main admin') == 0);

if ($action !== 'get_all' && !$is_main_admin) {
    echo json_encode(["status" => "error", "message" => "Permission denied."]);
    exit;
}

// --- GET ALL ---
if ($action === 'get_all') {
    $result = $conn->query("SELECT id, full_name, email, role, campus FROM admins ORDER BY created_at DESC");
    $admins = [];
    while ($row = $result->fetch_assoc()) { $admins[] = $row; }
    echo json_encode(["status" => "success", "data" => $admins]);
    exit;
}

// --- ADD (With Default Password) ---
if ($action === 'add') {
    $full_name = trim($input['full_name'] ?? '');
    $email     = trim($input['email']     ?? '');
    $campus    = trim($input['campus']    ?? '');

    if (empty($full_name) || empty($email) || empty($campus)) {
        echo json_encode(["status" => "error", "message" => "Missing required fields."]);
        exit;
    }

    // You can change this default password here
    $default_pass = "wvsu_librarian"; 
    $password_hash = password_hash($default_pass, PASSWORD_DEFAULT);

    $stmt = $conn->prepare("INSERT INTO admins (full_name, email, password_hash, role, campus) VALUES (?, ?, ?, 'admin', ?)");
    $stmt->bind_param("ssss", $full_name, $email, $password_hash, $campus);

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Admin added! Temp Pass: $default_pass"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Email already exists."]);
    }
    exit;
}

// --- DELETE ---
if ($action === 'delete') {
    $id = intval($input['id'] ?? 0);
    if ($id <= 1) {
        echo json_encode(["status" => "error", "message" => "Cannot delete primary admin."]);
        exit;
    }
    $stmt = $conn->prepare("DELETE FROM admins WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    echo json_encode(["status" => "success", "message" => "Deleted"]);
    exit;
}

// --- UPDATE ---
if ($action === 'update') {
    $id = intval($input['id'] ?? 0);
    $full_name = trim($input['full_name'] ?? '');
    $email = trim($input['email'] ?? '');
    $campus = trim($input['campus'] ?? '');

    $stmt = $conn->prepare("UPDATE admins SET full_name=?, email=?, campus=? WHERE id=?");
    $stmt->bind_param("sssi", $full_name, $email, $campus, $id);
    $stmt->execute();
    echo json_encode(["status" => "success", "message" => "Updated"]);
    exit;
}
?>