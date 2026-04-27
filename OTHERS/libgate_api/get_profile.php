<?php
// Include your existing connection file
include 'db_connect.php'; 

// Set header to JSON so Flutter can read it
header('Content-Type: application/json');

// In a real app, you'd get the ID from a session or a POST request
// For now, we fetch the admin with ID 1
$id = 1; 

$sql = "SELECT full_name, email, profilepicture_url FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // This sends the data to Flutter
    echo json_encode($row);
} else {
    echo json_encode(["error" => "No user found"]);
}

$stmt->close();
$conn->close();
?>
