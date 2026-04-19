<?php
$conn = new mysqli("localhost", "root", "", "libgate_db");

// check if admin already exists
$check = $conn->query("SELECT id FROM admins WHERE role = 'main_admin' LIMIT 1");

if ($check->num_rows > 0) {
    die("Setup already completed. Main admin exists.");
}

// get input from form (POST)
if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $full_name = $_POST['full_name'];
    $email = $_POST['email'];
    $password = $_POST['password'];

    $password_hash = password_hash($password, PASSWORD_BCRYPT);

    $stmt = $conn->prepare("
        INSERT INTO admins (full_name, email, password_hash, role)
        VALUES (?, ?, ?, 'main_admin')
    ");

    $stmt->bind_param("sss", $full_name, $email, $password_hash);

    if ($stmt->execute()) {
        echo "Main admin created successfully. Delete this file now.";
    } else {
        echo "Error: " . $stmt->error;
    }
    exit();
}
?>

<form method="POST">
    Full Name: <input type="text" name="full_name" required><br>
    Email: <input type="email" name="email" required><br>
    Password: <input type="password" name="password" required><br>
    <button type="submit">Create Main Admin</button>
</form>