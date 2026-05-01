<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

ini_set('display_errors', 0);
error_reporting(E_ALL);

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(); }

$action   = $_POST['action']   ?? $_GET['action']   ?? '';
// ── FIX: every request now requires admin_id ─────────────────────────────────
$admin_id = intval($_POST['admin_id'] ?? $_GET['admin_id'] ?? 0);

if ($admin_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Missing admin_id."]);
    exit();
}

try {
    // --- 1. FETCH ALL DATA (scoped to this admin) ---
    if ($action === 'fetch') {
        $departments = [];
        $stmt = $conn->prepare("SELECT * FROM departments WHERE admin_id = ? ORDER BY name ASC");
        $stmt->bind_param("i", $admin_id);
        $stmt->execute();
        $dept_query = $stmt->get_result();

        if (!$dept_query) throw new Exception("Fetch Depts Failed: " . $conn->error);

        while ($dept = $dept_query->fetch_assoc()) {
            $dept_id = $dept['id'];
            $courses = [];
            $course_stmt = $conn->prepare("SELECT * FROM programs WHERE department_id = ? AND admin_id = ? ORDER BY name ASC");
            $course_stmt->bind_param("ii", $dept_id, $admin_id);
            $course_stmt->execute();
            $course_query = $course_stmt->get_result();
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

        $stmt = $conn->prepare("INSERT INTO departments (admin_id, name, code) VALUES (?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("iss", $admin_id, $name, $code);
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
        $name    = $_POST['name'] ?? '';
        $code    = $_POST['code'] ?? '';

        $stmt = $conn->prepare("INSERT INTO programs (admin_id, department_id, name, code) VALUES (?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("iiss", $admin_id, $dept_id, $name, $code);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 4. DELETE A DEPARTMENT (only if owned by this admin) ---
    if ($action === 'delete_dept') {
        $id = intval($_POST['id'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM departments WHERE id = ? AND admin_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ii", $id, $admin_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 5. DELETE A COURSE (only if owned by this admin) ---
    if ($action === 'delete_course') {
        $id = intval($_POST['id'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM programs WHERE id = ? AND admin_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ii", $id, $admin_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

    // --- 6. EDIT A DEPARTMENT (only if owned by this admin) ---
    if ($action === 'edit_dept') {
        $id   = intval($_POST['id'] ?? 0);
        $name = $_POST['name'] ?? '';
        $code = $_POST['code'] ?? '';
        $stmt = $conn->prepare("UPDATE departments SET name = ?, code = ? WHERE id = ? AND admin_id = ?");
        if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);

        $stmt->bind_param("ssii", $name, $code, $id, $admin_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        exit();
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

if (isset($conn)) { $conn->close(); }
?>