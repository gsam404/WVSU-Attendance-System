<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

// Prevent raw PHP errors from breaking the JSON response
ini_set('display_errors', 0);
error_reporting(E_ALL);

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(); }

$action = $_POST['action'] ?? $_GET['action'] ?? '';

try {
    // --- 1. FETCH ALL DATA ---
    if ($action === 'fetch') {
        $departments = [];
        $dept_query = $conn->query("SELECT * FROM departments ORDER BY name ASC");
        
        if (!$dept_query) throw new Exception("Fetch Depts Failed: " . $conn->error);
        
        while ($dept = $dept_query->fetch_assoc()) {
            $dept_id = $dept['id'];
            $courses = [];
            $course_query = $conn->query("SELECT * FROM programs WHERE department_id = $dept_id ORDER BY name ASC");
            while ($course = $course_query->fetch_assoc()) {
                $courses[] = $course;
            }
            $dept['courses'] = $courses;
            $departments[] = $dept;
        }
        echo json_encode(["status" => "success", "data" => $departments]);
        exit();
    }

    // --- 2. ADD A DEPARTMENT ---
    if ($action === 'add_dept') {
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';
        
        $stmt = $conn->prepare("INSERT INTO departments (name, code) VALUES (?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ss", $name, $code);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 3. ADD A COURSE ---
    if ($action === 'add_course') {
        $dept_id = $_POST['department_id'] ?? '';
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';
        
        $stmt = $conn->prepare("INSERT INTO programs (department_id, name, code) VALUES (?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("iss", $dept_id, $name, $code);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 4. DELETE A DEPARTMENT ---
    if ($action === 'delete_dept') {
        $id = $_POST['id'] ?? '';
        $stmt = $conn->prepare("DELETE FROM departments WHERE id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 5. DELETE A COURSE ---
    if ($action === 'delete_course') {
        $id = $_POST['id'] ?? '';
        $stmt = $conn->prepare("DELETE FROM programs WHERE id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 6. EDIT A DEPARTMENT ---
    if ($action === 'edit_dept') {
        $id = $_POST['id'] ?? '';
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';
        $stmt = $conn->prepare("UPDATE departments SET name = ?, code = ? WHERE id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ssi", $name, $code, $id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

} catch (Exception $e) {
    // If anything fails, send the exact error message back to Flutter
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

if (isset($conn)) {
    $conn->close();
}
?>