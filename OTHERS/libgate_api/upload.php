<?php
/**
 * LIBGATE Student Import API
 * Version 2
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

header("Content-Type: application/json");


set_time_limit(300);
ini_set('memory_limit', '512M');

$conn = new mysqli("localhost", "root", "", "libgate_db");

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed."
    ]));
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die(json_encode([
        "status" => "error",
        "message" => "POST request required."
    ]));
}

if (!isset($_FILES['file'])) {
    die(json_encode([
        "status" => "error",
        "message" => "No file uploaded."
    ]));
}

$admin_id = intval($_POST['admin_id'] ?? 0);


if ($admin_id <= 0) {
    die(json_encode([
        "status"=>"error",
        "message"=>"Invalid Admin ID."
    ]));
}

/*
|--------------------------------------------------------------------------
| GET ADMIN CAMPUS
|--------------------------------------------------------------------------
*/

$getCampusStmt = $conn->prepare("
    SELECT 
        admins.campus_id,
        campuses.name AS campus_name
    FROM admins
    JOIN campuses 
        ON admins.campus_id = campuses.id
    WHERE admins.id = ?
    LIMIT 1
");

if (!$getCampusStmt) {
    die(json_encode([
        "status" => "error",
        "message" => "Failed to prepare campus lookup."
    ]));
}

$getCampusStmt->bind_param("i", $admin_id);
$getCampusStmt->execute();

$result = $getCampusStmt->get_result();

if ($admin = $result->fetch_assoc()) {

    $campus_id = (int)$admin["campus_id"];
    $campus_name = $admin["campus_name"];

} else {

    die(json_encode([
        "status"=>"error",
        "message"=>"Admin not found."
    ]));

}

$getCampusStmt->close();

$file = $_FILES['file'];

$extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if ($extension != "csv") {
    die(json_encode([
        "status"=>"error",
        "message"=>"Only CSV files are supported."
    ]));
}

$handle = fopen($file['tmp_name'], "r");

if (!$handle) {
    die(json_encode([
        "status"=>"error",
        "message"=>"Unable to open CSV."
    ]));
}

/*
|--------------------------------------------------------------------------
| HEADER NORMALIZATION
|--------------------------------------------------------------------------
*/

function normalizeHeader($header)
{
    $header = strtolower(trim($header));

    $header = str_replace("\xEF\xBB\xBF", "", $header);

    $header = preg_replace('/[^a-z0-9]+/', '_', $header);

    $header = trim($header, "_");

    return $header;
}

/*
|--------------------------------------------------------------------------
| HEADER ALIASES
|--------------------------------------------------------------------------
*/

$aliases = [

'student_number'=>[
'student_number',
'studentnumber',
'student_no',
'student_no.',
'student_id',
'studentid',
'student_number_id',
'student_number_no',
'student_number_no.',
'student_numberid',
'id_number',
'idnumber',
],

'last_name'=>[
'last_name',
'lastname',
'surname',
],

'first_name'=>[
'first_name',
'firstname',
'given_name',
'givenname',
],

'middle_name'=>[
'middle_name',
'middlename',
'middle',
'mi',
'm_i',
],

'program'=>[
'program',
'course',
'degree',
'program_name',
'course_name',
],

'year_level'=>[
'year',
'yearlevel',
'year_level',
'year_lvl',
'yearlevels',
],

'section'=>[
'section',
'block',
],

'date_of_birth'=>[
'date_of_birth',
'birth_date',
'birthdate',
'dob',
],

'place_of_birth'=>[
'place_of_birth',
'birth_place',
'birthplace',
'pob',
],

'gender'=>[
'gender',
'sex',
],

'email_address'=>[
'email',
'email_address',
'emailaddress',
'e_mail',
],

];

/*
|--------------------------------------------------------------------------
| FIND COLUMN INDEX
|--------------------------------------------------------------------------
*/

$headers = fgetcsv($handle);

if (!$headers) {
    die(json_encode([
        "status"=>"error",
        "message"=>"CSV has no header row."
    ]));
}

$headers = array_map('normalizeHeader', $headers);

$columns = [];

foreach ($aliases as $databaseField => $possibleHeaders)
{
    $columns[$databaseField] = false;

    foreach ($possibleHeaders as $alias)
    {
        $index = array_search(normalizeHeader($alias), $headers);

        if ($index !== false)
        {
            $columns[$databaseField] = $index;
            break;
        }
    }
} // <-- ADD THIS

/*
|--------------------------------------------------------------------------
| REQUIRED COLUMNS
|--------------------------------------------------------------------------
*/

$required = [
    'student_number',
    'last_name',
    'first_name',
    'program',
    'year_level'
];

$missingColumns = [];

foreach ($required as $field)
{
    if ($columns[$field] === false)
    {
        $missingColumns[] = $field;
    }
}

if (!empty($missingColumns))
{
    fclose($handle);

    die(json_encode([
        "status"=>"error",
        "message"=>"Missing required column(s): ".implode(", ", $missingColumns)
    ]));
}

/*
|--------------------------------------------------------------------------
| PROGRAM LOOKUP
|--------------------------------------------------------------------------
*/

$programStmt = $conn->prepare("
SELECT id
FROM programs
WHERE campus_id = ?
AND (
    UPPER(code)=UPPER(?)
    OR UPPER(name)=UPPER(?)
)
LIMIT 1
");

if(!$programStmt){
    die(json_encode([
        "status"=>"error",
        "message"=>"Failed to prepare program lookup."
    ]));
}

/*
|--------------------------------------------------------------------------
| STUDENT INSERT
|--------------------------------------------------------------------------
*/

$studentStmt = $conn->prepare("
INSERT INTO students
(
student_number,
admin_id,
campus_id,
program_id,
last_name,
first_name,
middle_name,
year_level,
section,
date_of_birth,
place_of_birth,
gender,
email_address
)

VALUES
(
?,?,?,?,?,?,?,?,?,?,?,?,?
)

ON DUPLICATE KEY UPDATE

admin_id = VALUES(admin_id),
campus_id = VALUES(campus_id),

program_id =
IF(VALUES(program_id) IS NULL,
program_id,
VALUES(program_id)),

last_name =
IF(VALUES(last_name)='',
last_name,
VALUES(last_name)),

first_name =
IF(VALUES(first_name)='',
first_name,
VALUES(first_name)),

middle_name =
IF(VALUES(middle_name)='',
middle_name,
VALUES(middle_name)),

year_level =
IF(VALUES(year_level)='',
year_level,
VALUES(year_level)),

section =
IF(VALUES(section)='',
section,
VALUES(section)),

date_of_birth =
IF(VALUES(date_of_birth) IS NULL,
date_of_birth,
VALUES(date_of_birth)),

place_of_birth =
IF(VALUES(place_of_birth)='',
place_of_birth,
VALUES(place_of_birth)),

gender =
IF(VALUES(gender)='',
gender,
VALUES(gender)),

email_address =
IF(VALUES(email_address)='',
email_address,
VALUES(email_address))
");

if(!$studentStmt){
    die(json_encode([
        "status"=>"error",
        "message"=>"Failed to prepare student insert."
    ]));
}

/*
|--------------------------------------------------------------------------
| IMPORT LOOP
|--------------------------------------------------------------------------
*/

$totalRows = 0;
$imported = 0;
$updated = 0;
$skipped = 0;

$errors = [];

while(($row = fgetcsv($handle)) !== false)
{
    if(empty(array_filter($row)))
        continue;

    $totalRows++;

    $get = function($field) use ($columns,$row){

        $index = $columns[$field];

        if($index===false)
            return "";

        return trim($row[$index] ?? "");
    };

    $studentNumber = $get("student_number");
    $lastName      = $get("last_name");
    $firstName     = $get("first_name");
    $middleName    = $get("middle_name");
    $programName   = $get("program");
    $yearLevel     = $get("year_level");
    $section       = $get("section");
    $birthDate     = $get("date_of_birth");
    $birthPlace    = $get("place_of_birth");
    $gender        = $get("gender");
    $email         = $get("email_address");

    $missingFields = [];

if ($studentNumber == "") $missingFields[] = "Student Number";
if ($firstName == "")     $missingFields[] = "First Name";
if ($lastName == "")      $missingFields[] = "Last Name";
if ($programName == "")   $missingFields[] = "Program";
if ($yearLevel == "")     $missingFields[] = "Year Level";

if (!empty($missingFields)) {

    $skipped++;

    $errors[] = [
        "row" => $totalRows + 1,
        "type" => "missing_required_fields",
        "field" => implode(", ", $missingFields),
        "message" => "Missing required field(s): " . implode(", ", $missingFields)
    ];

    continue;
}

    if($studentNumber=="")
    {
        $skipped++;

        $errors[] = [

            "row" => $totalRows + 1,

            "type" => "missing_student_number",

            "field" => "student_number",

            "message" => "Student Number is required."

        ];

        continue;
    }

    /*
    -------------------------------------------------------
    Find Program ID
    -------------------------------------------------------
    */

    $programID = null;

    if($programName!="")
    {
        $programStmt->bind_param(
            "iss",
            $campus_id,
            $programName,
            $programName
        );

        $programStmt->execute();

        $result = $programStmt->get_result();

        if($program = $result->fetch_assoc())
        {
            $programID = $program["id"];
        }

        $result->free();
    }

        if ($programID === null && $programName != "")
        {
            $errors[] = [

                "row" => $totalRows + 1,

                "type" => "program_not_found",

                "field" => "program",

                "value" => $programName,

                "message" => "Program not found."

            ];
        }
    /*
    -------------------------------------------------------
    Normalize Year Level
    -------------------------------------------------------
    */

    $yearLevel = strtolower(trim($yearLevel));

    $yearMap = [
        "1" => "1",
        "1st" => "1",
        "first" => "1",
        "first_year" => "1",
        "firstyear" => "1",

        "2" => "2",
        "2nd" => "2",
        "second" => "2",
        "second_year" => "2",
        "secondyear" => "2",

        "3" => "3",
        "3rd" => "3",
        "third" => "3",
        "third_year" => "3",
        "thirdyear" => "3",

        "4" => "4",
        "4th" => "4",
        "fourth" => "4",
        "fourth_year" => "4",
        "fourthyear" => "4",
    ];

    $yearLevel = $yearMap[$yearLevel] ?? $yearLevel;

    /*
    -------------------------------------------------------
    Normalize Date
    -------------------------------------------------------
    */

    if($birthDate != "")
    {
        $timestamp = strtotime($birthDate);

        if($timestamp !== false)
        {
            $birthDate = date("Y-m-d",$timestamp);
        }
        else
        {
            $birthDate = null;
        }
    }
    else
    {
        $birthDate = null;
    }

    /*
    -------------------------------------------------------
    Insert Student
    -------------------------------------------------------
    */

    $studentStmt->bind_param(
        "siiisssssssss",
        $studentNumber,
        $admin_id,
        $campus_id,
        $programID,
        $lastName,
        $firstName,
        $middleName,
        $yearLevel,
        $section,
        $birthDate,
        $birthPlace,
        $gender,
        $email
    );

    if(!$studentStmt->execute())
    {
        $skipped++;

        $errors[] = [

            "row" => $totalRows + 1,

            "type" => "database_error",

            "message" => $studentStmt->error

        ];

        continue;
    }

    if($studentStmt->affected_rows==1)
        $imported++;
    else
        $updated++;
}

/*
|--------------------------------------------------------------------------
| CLEAN UP
|--------------------------------------------------------------------------
*/

fclose($handle);

$studentStmt->close();

$programStmt->close();

$conn->close();

/*
|--------------------------------------------------------------------------
| RESPONSE
|--------------------------------------------------------------------------
*/

echo json_encode([

    "status" => "success",

    "message" => "Import completed successfully.",

    "summary" => [

    "total_rows" => $totalRows,
    "imported" => $imported,
    "updated" => $updated,
    "skipped" => $skipped,

    "campus_id" => $campus_id,
    "campus_name" => $campus_name,
    "admin_id" => $admin_id,
    "timestamp" => date("Y-m-d H:i:s")

],

    "errors" => $errors

]);

?>
    