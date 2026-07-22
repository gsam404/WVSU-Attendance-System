// ======================================================
// GET LOGGED-IN ADMIN INFORMATION
// Retrieves the admin's campus and role
// Used to determine which academic data can be accessed.
// ======================================================

<?php

// ======================================================
// INITIAL SETUP
// Headers, database connection, and logged-in admin
// ======================================================
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

ini_set('display_errors', 0);
error_reporting(E_ALL);

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(); }

$action   = $_POST['action']   ?? $_GET['action']   ?? '';

$admin_id = intval($_POST['admin_id'] ?? $_GET['admin_id'] ?? 0);

if ($admin_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing admin_id."
    ]);
    exit();
}

// ----- Load Departments for this campus -----

$stmt = $conn->prepare("
    SELECT campus_id, role
    FROM admins
    WHERE id = ?
");

$stmt->bind_param("i", $admin_id);
$stmt->execute();

$admin = $stmt->get_result()->fetch_assoc();

if (!$admin) {
    echo json_encode([
        "status" => "error",
        "message" => "Admin not found."
    ]);
    exit();
}

$campus_id = $admin['campus_id'];
$role = $admin['role'];

try {

// ======================================================
// FETCH ACADEMIC DATA
// Loads departments, programs, and school years
// ======================================================
if ($action === 'fetch') {
    ...
}

    if ($action === 'fetch') {
        $departments = [];
        $stmt = $conn->prepare("SELECT *
            FROM departments
            WHERE campus_id = ?
            ORDER BY name ASC");
        $stmt->bind_param("i", $campus_id);
        $stmt->execute();
        $dept_query = $stmt->get_result();

        if (!$dept_query) throw new Exception("Fetch Depts Failed: " . $conn->error);

        while ($dept = $dept_query->fetch_assoc()) {
            $dept_id = $dept['id'];
            $programs = [];

// // ----- Load Programs under each Department -----

            $program_stmt = $conn->prepare("SELECT *
                FROM programs
                WHERE department_id = ?
                AND campus_id = ?");
            $program_stmt->bind_param("ii", $dept_id, $campus_id);
            $program_stmt->execute();
            $program_query = $program_stmt->get_result();
            while ($program = $program_query->fetch_assoc()) {
                $programs[] = $program;
            }
            $dept['programs'] = $programs;
            $departments[] = $dept;
        }

// // ----- Load School Years -----

        $school_years = [];
        $sy_stmt = $conn->prepare("SELECT id, name, start_date, end_date FROM school_years ORDER BY start_date DESC");
        if ($sy_stmt) {
            $sy_stmt->execute();
            $sy_result = $sy_stmt->get_result();
            while ($sy = $sy_result->fetch_assoc()) {
                $school_years[] = $sy;
            }
            $sy_stmt->close();
        }

        echo json_encode(["status" => "success", "data" => $departments, "school_years" => $school_years]);
        exit();
    }

  // ======================================================
// DEPARTMENT CRUD
// ======================================================
// ----- Create Department -----
    if ($action === 'add_dept') {
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';

        $stmt = $conn->prepare("INSERT INTO departments (admin_id, campus_id, name, code) VALUES (?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param(
            "iiss",
            $admin_id,
            $campus_id,
            $name,
            $code
        );
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ======================================================
// PROGRAM CRUD
// ======================================================
// ----- Create Program -----
    if ($action === 'add_program') {
        $dept_id = $_POST['department_id'] ?? '';
        $name    = $_POST['name'] ?? '';
        $code    = $_POST['code'] ?? '';

        $stmt = $conn->prepare("INSERT INTO programs (admin_id, campus_id, department_id, name, code) VALUES (?, ?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param(
            "iiiss",
            $admin_id,
            $campus_id,
            $dept_id,
            $name,
            $code
        );
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ----- Delete Department -----
    if ($action === 'delete_dept') {
        $id = intval($_POST['id'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM departments WHERE id = ? AND campus_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ii", $id, $campus_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    } 

 // ======================================================
// SCHOOL YEAR CRUD
// ======================================================
// ----- Create School Year -----
    if ($action === 'add_school_year') {
        $name = trim($_POST['name'] ?? '');
        $start_date = trim($_POST['start_date'] ?? '');
        $end_date = trim($_POST['end_date'] ?? '');

        if (empty($name) || empty($start_date) || empty($end_date)) {
            echo json_encode(["status" => "error", "message" => "Missing required school year fields."]);
            exit();
        }

        $stmt = $conn->prepare("INSERT INTO school_years (name, start_date, end_date) VALUES (?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("sss", $name, $start_date, $end_date);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ----- Delete School Year -----
    if ($action === 'delete_school_year') {
        $id = intval($_POST['id'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM school_years WHERE id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ----- Update/Edit School Year -----
    if ($action === 'edit_school_year') {
        $id = intval($_POST['id'] ?? 0);
        $name = trim($_POST['name'] ?? '');
        $start_date = trim($_POST['start_date'] ?? '');
        $end_date = trim($_POST['end_date'] ?? '');

        if ($id <= 0 || empty($name) || empty($start_date) || empty($end_date)) {
            echo json_encode(["status" => "error", "message" => "Missing required school year fields."]);
            exit();
        }

        $stmt = $conn->prepare("UPDATE school_years SET name = ?, start_date = ?, end_date = ? WHERE id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("sssi", $name, $start_date, $end_date, $id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ----- Delete Program -----
    if ($action === 'delete_program') {
        $id = intval($_POST['id'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM programs WHERE id = ? AND campus_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ii", $id, $campus_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

  // ----- Update/Edit Department -----

    if ($action === 'edit_dept') {
        $id   = intval($_POST['id'] ?? 0);
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';
        $stmt = $conn->prepare("UPDATE departments SET name = ?, code = ? WHERE id = ? AND campus_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ssii", $name, $code, $id, $campus_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

// ======================================================
// ERROR HANDLING
// Returns JSON errors if an exception occurs
// ======================================================





// ----- Update/Edit Program -----
if ($action === 'edit_program') {
    $id = intval($_POST['id'] ?? 0);
    $name = trim($_POST['name'] ?? '');
    $code = trim($_POST['code'] ?? '');

    $stmt = $conn->prepare("
        UPDATE programs
        SET name = ?, code = ?
        WHERE id = ? AND campus_id = ?
    ");

    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param(
        "ssii",
        $name,
        $code,
        $id,
        $campus_id
    );

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success"
        ]);
    } else {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    exit();
}

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

if (isset($conn)) { 
// // ======================================================
// CLOSE DATABASE CONNECTION
// ======================================================
$conn->close(); }

?>

