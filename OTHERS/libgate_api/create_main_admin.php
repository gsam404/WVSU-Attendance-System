<?php
$conn = new mysqli("localhost", "root", "", "libgate_db");

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Detect whether admins uses campus_id
$hasCampusId = false;
$schemaCheck = $conn->query("SHOW COLUMNS FROM admins LIKE 'campus_id'");
if ($schemaCheck && $schemaCheck->num_rows > 0) {
    $hasCampusId = true;
}

// Load campus list for selection
$campuses = [];
$campusQuery = $conn->query("SELECT id, name FROM campuses ORDER BY name ASC");
if ($campusQuery) {
    while ($row = $campusQuery->fetch_assoc()) {
        $campuses[] = $row;
    }
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $full_name = trim($_POST['full_name'] ?? '');
    $email = trim(strtolower($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';
    $campus_id = intval($_POST['campus_id'] ?? 0);
    $campus_name = trim($_POST['campus'] ?? '');

    // Check required fields
    if (empty($full_name) || empty($email) || empty($password)) {
        die("All fields are required.");
    }

    if ($hasCampusId) {
        if ($campus_id <= 0) {
            die("Please select a campus.");
        }
    } else {
        if (empty($campuses) && empty($campus_name)) {
            die("Please enter a campus name.");
        }
    }

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        die("Invalid email address.");
    }

    // Only allow WVSU email addresses
    if (!preg_match('/@wvsu\.edu\.ph$/i', $email)) {
        die("Only @wvsu.edu.ph email addresses are allowed.");
    }

    // Check for duplicate email (case-insensitive)
    $check = $conn->prepare("
        SELECT id
        FROM admins
        WHERE LOWER(email) = LOWER(?)
        LIMIT 1
    ");
    $check->bind_param("s", $email);
    $check->execute();
    $result = $check->get_result();

    if ($result->num_rows > 0) {
        header("Location: create_main_admin.php?error=exists");
        exit();
    }

    // Hash password
    $password_hash = password_hash($password, PASSWORD_BCRYPT);

    if ($hasCampusId) {

        $stmt = $conn->prepare("
            INSERT INTO admins
            (full_name, email, password_hash, role, campus_id)
            VALUES (?, ?, ?, 'main_admin', ?)
        ");

        $stmt->bind_param("sssi", $full_name, $email, $password_hash, $campus_id);

    } else {

        $selectedCampus = 'Main Campus';

        if ($campus_id > 0) {
            foreach ($campuses as $campus) {
                if ($campus['id'] == $campus_id) {
                    $selectedCampus = $campus['name'];
                    break;
                }
            }
        } elseif (!empty($campus_name)) {
            $selectedCampus = $campus_name;
        }

        $stmt = $conn->prepare("
            INSERT INTO admins
            (full_name, email, password_hash, role, campus)
            VALUES (?, ?, ?, 'main_admin', ?)
        ");

        $stmt->bind_param("ssss", $full_name, $email, $password_hash, $selectedCampus);
    }

    if ($stmt->execute()) {
        header("Location: create_main_admin.php?success=1");
        exit();
    } else {
        die("Database Error: " . $stmt->error);
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Create Main Administrator</title>
    <style>
        body{
            font-family: Arial, sans-serif;
            margin:40px;
        }

        .success{
            color:green;
            background:#eaf8ea;
            border:1px solid #8fd18f;
            padding:10px;
            margin-bottom:20px;
            width:400px;
        }

        label{
            font-weight:bold;
        }

        input, select{
            width:300px;
            padding:8px;
        }

        button{
            padding:10px 20px;
            cursor:pointer;
        }
    </style>
</head>
<body>

<h2>Create Main Administrator</h2>

<?php if(isset($_GET['success'])): ?>
    <div class="success">
        ✅ Main administrator created successfully.
    </div>
<?php endif; ?>

<?php if(isset($_GET['error']) && $_GET['error'] == 'exists'): ?>
    <div style="
        color:#721c24;
        background:#f8d7da;
        border:1px solid #f5c6cb;
        padding:10px;
        margin-bottom:20px;
        width:400px;
    ">
        ❌ An administrator with this email already exists.
    </div>
<?php endif; ?>

<form method="POST" autocomplete="off">

    <label>Full Name</label><br>
    <input type="text" name="full_name" required><br><br>

    <label>WVSU Email</label><br>
    <input
        type="email"
        name="email"
        autocomplete="off"
        spellcheck="false"
        autocapitalize="none"
        required
    ><br><br>

    <label>Password</label><br>
    <input
        type="password"
        name="password"
        autocomplete="new-password"
        required
    ><br><br>

    <label>Campus</label><br>

    <?php if (!empty($campuses)): ?>

        <select name="campus_id" required>
            <option value="">Select Campus</option>

            <?php foreach($campuses as $campus): ?>
                <option value="<?= htmlspecialchars($campus['id']) ?>">
                    <?= htmlspecialchars($campus['name']) ?>
                </option>
            <?php endforeach; ?>

        </select>

    <?php elseif ($hasCampusId): ?>

        <p style="color:red;">
            No campuses found. Please add campus records first.
        </p>

    <?php else: ?>

        <input
            type="text"
            name="campus"
            placeholder="Campus Name"
            required
        >

    <?php endif; ?>

    <br><br>

    <button type="submit">
        Create Main Admin
    </button>

</form>

</body>
</html>