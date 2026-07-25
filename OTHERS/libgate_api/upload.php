<?php
/**
 * LIBGATE_DB - STUDENT IMPORT BACKEND
 * Save as: C:/xampp/htdocs/libgate_api/upload.php
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit; }

set_time_limit(300);
ini_set('memory_limit', '256M');

$conn = new mysqli("localhost", "root", "", "libgate_db");
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "DB Connection Failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {

    // ── FIX: get the admin_id sent from Flutter ──────────────────────────────
    $admin_id = intval($_POST['admin_id'] ?? 0);
    if ($admin_id <= 0) {
        echo json_encode(["status" => "error", "message" => "Missing admin_id. Please log in again."]);
        exit;
    }

    $fileTmpPath = $_FILES['file']['tmp_name'];
    $fileName    = $_FILES['file']['name'];
    $fileExt     = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

    if ($fileExt !== 'csv') {
        echo json_encode(["status" => "error", "message" => "Only CSV files are accepted."]);
        exit;
    }

    $handle = fopen($fileTmpPath, "r");
    if ($handle === FALSE) {
        echo json_encode(["status" => "error", "message" => "Could not open the uploaded file."]);
        exit;
    }

    // Read and normalize headers
    $headers = fgetcsv($handle, 0, ",");
    if ($headers === FALSE) {
        echo json_encode(["status" => "error", "message" => "CSV file is empty or unreadable."]);
        exit;
    }

    $headers = array_map(function ($h) {
    $h = strtolower(trim(str_replace("\xEF\xBB\xBF", '', $h ?? '')));
    $h = preg_replace('/[^a-z0-9]+/', '_', $h);
    return trim($h, '_');
}, $headers); $headers);

    function findHeader($headers, $possibleNames) {
    foreach ($possibleNames as $name) {
        $index = array_search($name, $headers);
        if ($index !== false) {
            return $index;
        }
    }
    return false;
}

    // Map DB columns to CSV indices
    $colMap = [
        'student_number' => array_search('student_number', $headers),
        'last_name'      => array_search('last_name',      $headers),
        'first_name'     => array_search('first_name',     $headers),
        'middle_name'    => array_search('middle_name',    $headers),
        'program'        => array_search('program',        $headers),
        'year_level'     => array_search('year_level',     $headers),
        'section'        => array_search('section',        $headers),
        'date_of_birth'  => array_search('date_of_birth',  $headers),
        'place_of_birth' => array_search('place_of_birth', $headers),
        'gender'         => array_search('gender',         $headers),
        'email_address'  => array_search('email_address',  $headers),
    ];

    if ($colMap['student_number'] === false) {
        echo json_encode([
            "status"  => "error",
            "message" => "CSV header 'student_number' not found. Headers detected: " . implode(", ", $headers)
        ]);
        exit;
    }

    $get = function($row, $key) use ($colMap) {
        $idx = $colMap[$key];
        if ($idx === false || $idx === null) return null;
        return isset($row[$idx]) ? trim($row[$idx]) : null;
    };

    $prog_stmt = $conn->prepare("SELECT id FROM programs WHERE admin_id = ? AND (code = ? OR name = ?) LIMIT 1");
    if (!$prog_stmt) {
        echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
        exit;
    }

    $stmt = $conn->prepare("
        INSERT INTO students 
            (student_number, admin_id, last_name, first_name, middle_name, program_id,
             year_level, section, date_of_birth, place_of_birth, gender, email_address)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            admin_id = VALUES(admin_id),
            last_name = VALUES(last_name),
            first_name = VALUES(first_name),
            middle_name = VALUES(middle_name),
            program_id = VALUES(program_id),
            year_level = VALUES(year_level),
            section = VALUES(section),
            date_of_birth = VALUES(date_of_birth),
            place_of_birth = VALUES(place_of_birth),
            gender = VALUES(gender),
            email_address = VALUES(email_address)
    ");

    $count  = 0;
    $errors = 0;
    $conn->begin_transaction();

    try {
        while (($data = fgetcsv($handle, 0, ",")) !== FALSE) {
            if (empty(array_filter($data, fn($v) => trim($v ?? '') !== ''))) continue;

            $snum  = $get($data, 'student_number');
            $lname = $get($data, 'last_name');
            $fname = $get($data, 'first_name');
            $mname = $get($data, 'middle_name');
            $prog  = $get($data, 'program');
            $yr    = $get($data, 'year_level');
            $sec   = $get($data, 'section');
            $dob   = $get($data, 'date_of_birth');
            $pob   = $get($data, 'place_of_birth');
            $gen   = $get($data, 'gender');
            $email = $get($data, 'email_address');

            if (empty($snum)) { $errors++; continue; }

            $prog_id = null;
            if (!empty($prog)) {
                $prog_stmt->bind_param("iss", $admin_id, $prog, $prog);
                $prog_stmt->execute();
                $prog_res = $prog_stmt->get_result();
                if ($prog_row = $prog_res->fetch_assoc()) {
                    $prog_id = intval($prog_row['id']);
                }
                $prog_res->free();
            }

            $stmt->bind_param(
                "sississsssss",
                $snum, $admin_id, $lname, $fname, $mname, $prog_id,
                $yr, $sec, $dob, $pob, $gen, $email
            );
            $stmt->execute();
            $count++;
        }

        $conn->commit();
        echo json_encode([
            "status"  => "success",
            "message" => "Imported $count students successfully." .
                         ($errors > 0 ? " ($errors rows skipped — missing Student_Number)" : "")
        ]);

    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["status" => "error", "message" => "Import failed: " . $e->getMessage()]);
    }

    fclose($handle);
    $stmt->close();
    $prog_stmt->close();

} else {
    echo json_encode(["status" => "error", "message" => "No file received by the server."]);
}

$conn->close();
?>