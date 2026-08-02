<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

if (!$conn) {
    echo json_encode(["error" => "Database connection failed: " . mysqli_connect_error()]);
    exit();
}

// ── FIX: scope all queries to this admin ─────────────────────────────────────
$admin_id = intval($_GET['admin_id'] ?? $_POST['admin_id'] ?? 0);
if ($admin_id <= 0) {
    echo json_encode(["error" => "Missing admin_id."]);
    exit();
}

$weekly  = array_fill(0, 7, 0);
$monthly = array_fill(0, 12, 0);

// ── 1. Weekly chart ──────────────────────────────────────────────────────────
$weekly_query = "
    SELECT DAYOFWEEK(scan_date) AS day_num, COUNT(*) AS cnt
    FROM entry_logs
    WHERE admin_id = $admin_id
      AND YEARWEEK(scan_date, 0) = YEARWEEK(CURDATE(), 0)
    GROUP BY DAYOFWEEK(scan_date)";
$res = mysqli_query($conn, $weekly_query);
if ($res) {
    while ($row = mysqli_fetch_assoc($res)) {
        $idx = (int)$row['day_num'] - 1;
        if ($idx >= 0 && $idx < 7) $weekly[$idx] = (int)$row['cnt'];
    }
}

// ── 2. Monthly chart ─────────────────────────────────────────────────────────
$monthly_query = "
    SELECT MONTH(scan_date) AS month_num, COUNT(*) AS cnt
    FROM entry_logs
    WHERE admin_id = $admin_id
      AND YEAR(scan_date) = YEAR(CURDATE())
    GROUP BY MONTH(scan_date)";
$res = mysqli_query($conn, $monthly_query);
if ($res) {
    while ($row = mysqli_fetch_assoc($res)) {
        $idx = (int)$row['month_num'] - 1;
        if ($idx >= 0 && $idx < 12) $monthly[$idx] = (int)$row['cnt'];
    }
}

// ── 3. Weekly stat cards ─────────────────────────────────────────────────────
$weeklyPeakDay = $weeklyTopDepartment = $weeklyTopCourse = "None";

$res = mysqli_query($conn, "
    SELECT DAYNAME(scan_date) AS v, COUNT(*) AS cnt
    FROM entry_logs
    WHERE admin_id = $admin_id
      AND YEARWEEK(scan_date, 0) = YEARWEEK(CURDATE(), 0)
    GROUP BY DAYNAME(scan_date) ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $weeklyPeakDay = $row['v'];

$res = mysqli_query($conn, "
    SELECT d.code AS v, COUNT(l.log_id) AS cnt
    FROM entry_logs l
    JOIN students s ON l.student_number = s.student_number
    JOIN programs p ON s.program_id = p.id
    JOIN departments d ON p.department_id = d.id
    WHERE l.admin_id = $admin_id
      AND YEARWEEK(l.scan_date, 0) = YEARWEEK(CURDATE(), 0)
    GROUP BY d.id ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $weeklyTopDepartment = $row['v'] ?? "None";

$res = mysqli_query($conn, "
    SELECT p.code AS v, COUNT(l.log_id) AS cnt
    FROM entry_logs l
    JOIN students s ON l.student_number = s.student_number
    JOIN programs p ON s.program_id = p.id
    WHERE l.admin_id = $admin_id
      AND YEARWEEK(l.scan_date, 0) = YEARWEEK(CURDATE(), 0)
    GROUP BY p.id ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $weeklyTopCourse = $row['v'] ?? "None";

// ── 4. Monthly stat cards ────────────────────────────────────────────────────
$monthlyPeakMonth = $monthlyTopDepartment = $monthlyTopCourse = "None";

$res = mysqli_query($conn, "
    SELECT MONTHNAME(scan_date) AS v, COUNT(*) AS cnt
    FROM entry_logs
    WHERE admin_id = $admin_id
      AND YEAR(scan_date) = YEAR(CURDATE())
    GROUP BY MONTH(scan_date), MONTHNAME(scan_date)
    ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $monthlyPeakMonth = $row['v'];

$res = mysqli_query($conn, "
    SELECT d.code AS v, COUNT(l.log_id) AS cnt
    FROM entry_logs l
    JOIN students s ON l.student_number = s.student_number
    JOIN programs p ON s.program_id = p.id
    JOIN departments d ON p.department_id = d.id
    WHERE l.admin_id = $admin_id
      AND YEAR(l.scan_date) = YEAR(CURDATE())
    GROUP BY d.id ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $monthlyTopDepartment = $row['v'] ?? "None";

$res = mysqli_query($conn, "
    SELECT p.code AS v, COUNT(l.log_id) AS cnt
    FROM entry_logs l
    JOIN students s ON l.student_number = s.student_number
    JOIN programs p ON s.program_id = p.id
    WHERE l.admin_id = $admin_id
      AND YEAR(l.scan_date) = YEAR(CURDATE())
    GROUP BY p.id ORDER BY cnt DESC LIMIT 1");
if ($res && $row = mysqli_fetch_assoc($res)) $monthlyTopCourse = $row['v'] ?? "None";

echo json_encode([
    "weekly"               => $weekly,
    "monthly"              => $monthly,
    "weeklyPeakDay"        => $weeklyPeakDay,
    "weeklyTopDepartment"  => $weeklyTopDepartment,
    "weeklyTopCourse"      => $weeklyTopCourse,
    "monthlyPeakMonth"     => $monthlyPeakMonth,
    "monthlyTopDepartment" => $monthlyTopDepartment,
    "monthlyTopCourse"     => $monthlyTopCourse,
]);
?>