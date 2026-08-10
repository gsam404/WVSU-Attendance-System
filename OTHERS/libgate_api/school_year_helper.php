<?php


if (!function_exists('getOrCreateSchoolYear')) {

    /**
     * @param mysqli $conn
     * @param int $campus_id
     * @param string|null $forDate  'Y-m-d', defaults to today
     * @return array{id:int,name:string,start_date:string,end_date:string}|null
     */
    function getOrCreateSchoolYear(mysqli $conn, int $campus_id, ?string $forDate = null): ?array
    {
        $forDate = $forDate ?? date('Y-m-d');
        $ts = strtotime($forDate);
        if ($ts === false) {
            return null;
        }

        $startYear = (int) date('Y', $ts); // simply the calendar year of the import/scan
        $endYear   = $startYear + 1;

        $name       = "$startYear-$endYear";
        $start_date = sprintf('%04d-01-01', $startYear);
        $end_date   = sprintf('%04d-12-31', $startYear);

        // 1. Look for an existing row for this campus + name.
        $stmt = $conn->prepare("SELECT id FROM school_years WHERE campus_id = ? AND name = ? LIMIT 1");
        if (!$stmt) {
            return null;
        }
        $stmt->bind_param("is", $campus_id, $name);
        $stmt->execute();
        $res = $stmt->get_result();
        if ($row = $res->fetch_assoc()) {
            $stmt->close();
            return [
                'id'         => (int) $row['id'],
                'name'       => $name,
                'start_date' => $start_date,
                'end_date'   => $end_date,
            ];
        }
        $stmt->close();

        // 2. Not found — create it.
        $ins = $conn->prepare("
            INSERT INTO school_years (name, start_date, end_date, campus_id, created_at)
            VALUES (?, ?, ?, ?, NOW())
        ");
        if (!$ins) {
            return null;
        }
        $ins->bind_param("sssi", $name, $start_date, $end_date, $campus_id);
        if (!$ins->execute()) {
            $ins->close();
            return null;
        }
        $newId = $conn->insert_id;
        $ins->close();

        return [
            'id'         => $newId,
            'name'       => $name,
            'start_date' => $start_date,
            'end_date'   => $end_date,
        ];
    }
}