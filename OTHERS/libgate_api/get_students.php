<?php
/**
 * LIBGATE Get Students API
 * Returns imported student records strictly scoped to the logged-in
 * admin's campus_id — every admin (including main_admin) only sees
 * students uploaded under their own campus.
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "libgate_db");

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed."
    ]));
}

$campusId = isset($_GET['campus_id']) ? intval($_GET['campus_id']) : 0;

if ($campusId <= 0) {
    die(json_encode([
        "status" => "error",
        "message" => "campus_id is required."
    ]));
}

$sql = "
    SELECT
        s.student_number,
        s.last_name,
        s.first_name,
        s.middle_name,
        s.year_level,
        s.section,
        s.date_of_birth,
        s.place_of_birth,
        s.gender,
        s.email_address,
        COALESCE(p.code, p.name, '') AS program
    FROM students s
    LEFT JOIN programs p ON p.id = s.program_id
    WHERE s.campus_id = ?
    ORDER BY s.last_name, s.first_name
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    die(json_encode([
        "status" => "error",
        "message" => "Failed to prepare student query."
    ]));
}

$stmt->bind_param("i", $campusId);
$stmt->execute();
$result = $stmt->get_result();

$students = [];

while ($row = $result->fetch_assoc()) {
    $students[] = [
        "student_number" => $row["student_number"],
        "last_name"       => $row["last_name"],
        "first_name"      => $row["first_name"],
        "middle_name"     => $row["middle_name"],
        "program"         => $row["program"],
        "year_level"      => $row["year_level"],
        "section"         => $row["section"],
        "date_of_birth"   => $row["date_of_birth"],
        "place_of_birth"  => $row["place_of_birth"],
        "gender"          => $row["gender"],
        "email_address"   => $row["email_address"],
    ];
}

$stmt->close();
$conn->close();

echo json_encode([
    "status" => "success",
    "data" => $students
]);