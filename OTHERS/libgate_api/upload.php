<?php
/**
 * LIBGATE_DB - STUDENT IMPORT BACKEND
 * Save as: C:/xampp/htdocs/api/upload.php
 */

// 1. CORS Headers for Flutter Web
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

// 2. Increase limits for large files (9,000+ records)
set_time_limit(300); // 5 minutes
ini_set('memory_limit', '256M');

// 3. Database Connection
$host = "localhost";
$user = "root";
$pass = ""; 
$db   = "libgate_db";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "DB Connection Failed"]));
}

// 4. Processing
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $fileTmpPath = $_FILES['file']['tmp_name'];
    $fileName = $_FILES['file']['name'];
    $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

    // Check if file is CSV
    if ($fileExtension !== 'csv') {
        echo json_encode(["status" => "error", "message" => "Please save your Excel file as CSV before uploading."]);
        exit;
    }

    // A. Wipe the old database table
    $conn->query("TRUNCATE TABLE students");

    // B. Read and Insert
    if (($handle = fopen($fileTmpPath, "r")) !== FALSE) {
        // Skip Header Row
        fgetcsv($handle, 1000, ","); 

        // Prepare SQL - ensure these column names match your phpMyAdmin exactly
        $stmt = $conn->prepare("INSERT INTO students (id, name, course, year, dept) VALUES (?, ?, ?, ?, ?)");

        $count = 0;
        $conn->begin_transaction(); // Use transaction for speed

        try {
            while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
                if (count($data) >= 5) {
                    // Bind the 5 columns from your CSV
                    $stmt->bind_param("sssss", $data[0], $data[1], $data[2], $data[3], $data[4]);
                    $stmt->execute();
                    $count++;
                }
            }
            $conn->commit();
            echo json_encode([
                "status" => "success", 
                "message" => "Imported $count students successfully."
            ]);
        } catch (Exception $e) {
            $conn->rollback();
            echo json_encode(["status" => "error", "message" => "Error during import: " . $e->getMessage()]);
        }
        
        fclose($handle);
        $stmt->close();
    }
} else {
    echo json_encode(["status" => "error", "message" => "No file received by the server."]);
}

$conn->close();
?>