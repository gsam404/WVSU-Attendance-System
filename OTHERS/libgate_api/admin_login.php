<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(); }

$host = "localhost";
$user = "root";
$pass = "";
$db   = "libgate_db";

$conn = new mysqli($host, $user, $pass, $db);

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';

    if (empty($email) || empty($password)) {
        echo json_encode(["success" => false, "message" => "Email and password are required"]);
        exit;
    }

    $stmt = $conn->prepare(
        "SELECT a.id, a.full_name, a.email, a.password_hash, a.role, c.name AS campus
         FROM admins a
         LEFT JOIN campuses c ON a.campus_id = c.id
         WHERE a.email = ?"
    );
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();

        if (password_verify($password, $row['password_hash'])) {
            echo json_encode([
                "success"     => true,
                "message"     => "Login successful",
                "id"          => $row['id'],
                "full_name"   => $row['full_name'],
                "email"       => $row['email'],
                "role"        => $row['role'],
                "campus"      => $row['campus']
            ]);
        } else {
            echo json_encode(["success" => false, "message" => "Incorrect password"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Account not found"]);
    }
    $stmt->close();
}
?>