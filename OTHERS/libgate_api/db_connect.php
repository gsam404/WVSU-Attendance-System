<?php
$servername = "127.0.0.1"; // Use localhost or this dependending on your windows version
$username = "root"; // Default XAMPP username
$password = "";     // Default XAMPP password is blank
$database = "libgate_db";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>