<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

try {

    // ===============================
    // GET FILTER PARAMETERS
    // ===============================
    $date = $_GET['date'] ?? null;
    $month = $_GET['month'] ?? null;
    $department = $_GET['department'] ?? null;
    $program = $_GET['program'] ?? null;
    $school_year_id = intval($_GET['school_year_id'] ?? 0);
    $school_year = trim($_GET['school_year'] ?? '');

    // ===============================
    // BASE QUERY
    // ===============================
    $query = "SELECT 
                l.scan_date as date, 
                DATE_FORMAT(l.time_in, '%h:%i %p') as signIn,
                l.time_out as signOut, 
                CONCAT(s.first_name, ' ', s.last_name) as name, 
                s.student_number as studentId, 
                s.year_level as year, 
                p.code as course, 
                d.code as department 
              FROM entry_logs l
              JOIN students s ON l.student_number = s.student_number
              LEFT JOIN programs p ON s.program_id = p.id
              LEFT JOIN departments d ON p.department_id = d.id
              LEFT JOIN school_years sy ON l.school_year_id = sy.id
              WHERE 1=1";

    // ===============================
    // APPLY FILTERS
    // ===============================

    // FIX: filter by the actual school_years row (via the join above),
    // not a recomputed date range. entry_logs.school_year_id is already
    // the source of truth — it's set once, at scan time, by
    // school_year_helper.php's getOrCreateSchoolYear(). Recomputing a
    // separate Aug 1 - Jul 31 window here used a DIFFERENT definition of
    // "school year" than the one entries were actually tagged with,
    // which could pull entries from the wrong year into a report (or
    // exclude entries that do belong). Always match on the same id/name
    // that was stored on the row.
    if ($school_year_id > 0) {
        $query .= " AND l.school_year_id = $school_year_id";
    } elseif ($school_year && $school_year !== 'All Years') {
        $school_year_safe = $conn->real_escape_string($school_year);
        $query .= " AND sy.name = '$school_year_safe'";
    }

    if ($date && !$school_year && !$month && $school_year_id === 0) { // Only use exact date if SY or Month aren't selected
        $query .= " AND DATE(l.scan_date) = '$date'";
    }

    if ($month && !$school_year) {
        $query .= " AND MONTH(l.scan_date) = '$month'";
    }

    if ($department && $department !== 'All Departments') {
        $query .= " AND d.code = '$department'";
    }

    if ($program && $program !== 'All Programs') {
        $program_safe = $conn->real_escape_string($program);
        $query .= " AND p.code = '$program_safe'";
    }

    $query .= " ORDER BY l.scan_date DESC, l.time_in DESC";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Database Query Failed: " . $conn->error);
    }

    $attendance_data = [];

    while ($row = $result->fetch_assoc()) {
        $row['signOut'] = $row['signOut'] ?? '--:--';
        $row['course'] = $row['course'] ?? 'N/A';
        $row['department'] = $row['department'] ?? 'N/A';

        $attendance_data[] = $row;
    }

    echo json_encode($attendance_data);

} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}

if (isset($conn)) {
    $conn->close();
}
?>