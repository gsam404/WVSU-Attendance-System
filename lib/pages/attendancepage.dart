import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // ─── Filter state 
  // Default = today (real-time clock)
  DateTime _selectedDate = DateTime.now();
  String? _selectedFilterCategory;
  String? _selectedFilterValue;

  final List<String> _filterCategories = ['Program', 'Department', 'Month'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<String> _programs = ['All Programs'];
  List<String> _departments = ['All Departments'];

  // ─── Data state ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _attendanceData = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;

  // ─── Pagination: 30 rows per page, fully dynamic ───────────────────────────
  int _currentPage = 1;
  static const int _rowsPerPage = 30;

  // ─── Auto-refresh timer ────────────────────────────────────────────────────
  Timer? _pollTimer;

  static const String _base = 'http://localhost/libgate_api';

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _fetchAcademicFilters();
    _fetchAttendance();
    // Refresh every 10 s only when on today + no category filter
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_selectedFilterCategory == null && _isSameDay(_selectedDate, DateTime.now())) {
        _fetchAttendance();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Academic filters ──────────────────────────────────────────────────────
  Future<void> _fetchAcademicFilters() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/academic_api.php?action=fetch'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          final depts = ['All Departments'];
          final progs = ['All Programs'];
          for (var d in data['data']) {
            depts.add(d['code']);
            for (var c in (d['courses'] ?? [])) progs.add(c['code']);
          }
          if (mounted) setState(() { _departments = depts; _programs = progs; });
        }
      }
    } catch (_) {}
  }

  // ─── Fetch from PHP with correct params ───────────────────────────────────
  Future<void> _fetchAttendance() async {
    final params = <String, String>{};

    if (_selectedFilterCategory == 'Month' && _selectedFilterValue != null) {
      // Month filter → no date restriction, just month number
      params['month'] = (_months.indexOf(_selectedFilterValue!) + 1).toString();
    } else if (_selectedFilterCategory == 'Department' &&
        _selectedFilterValue != null &&
        _selectedFilterValue != 'All Departments') {
      params['department'] = _selectedFilterValue!;
      params['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate);
    } else if (_selectedFilterCategory == 'Program' &&
        _selectedFilterValue != null &&
        _selectedFilterValue != 'All Programs') {
      params['program'] = _selectedFilterValue!;
      params['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate);
    } else {
      // Default: by selected date (today on first load)
      params['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate);
    }

    try {
      final uri = Uri.parse('$_base/get_attendance.php')
          .replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _attendanceData = list.cast<Map<String, dynamic>>();
            _currentPage = 1;
          });
        }
      }
    } catch (_) {}
  }

  // ─── Derived / computed ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) return _attendanceData;
    final q = _searchQuery.toLowerCase();
    return _attendanceData.where((r) =>
        (r['name'] ?? '').toLowerCase().contains(q) ||
        (r['studentId'] ?? '').toLowerCase().contains(q)).toList();
  }

  // Total pages based on actual record count — never hardcoded
  int get _totalPages =>
      (_filteredData.length / _rowsPerPage).ceil().clamp(1, 99999);

  List<Map<String, dynamic>> get _pagedData {
    final all = _filteredData;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, all.length);
    return start >= all.length ? [] : all.sublist(start, end);
  }

  // ─── Metrics (recalculated on every filtered dataset change) ──────────────
  Map<String, String> _calcMetrics(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {'total': '0', 'dept': '—', 'course': '—', 'avg': '—', 'peak': '—'};
    }
    final deptCount = <String, int>{};
    final courseCount = <String, int>{};
    final studentVisits = <String, int>{};
    final hourCount = <int, int>{};

    for (final row in data) {
      final dept = row['department'] ?? 'N/A';
      final course = row['course'] ?? 'N/A';
      final sid = row['studentId'] ?? '';
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
      courseCount[course] = (courseCount[course] ?? 0) + 1;
      if (sid.isNotEmpty) studentVisits[sid] = (studentVisits[sid] ?? 0) + 1;
      try {
        final raw = (row['signIn'] ?? '').toString().replaceAll(' ', '');
        final t = DateFormat('h:mma').parse(raw.toUpperCase());
        hourCount[t.hour] = (hourCount[t.hour] ?? 0) + 1;
      } catch (_) {}
    }

    final topDept = deptCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final topCourse = courseCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final avg = (studentVisits.values.fold(0, (s, v) => s + v) / studentVisits.length)
        .toStringAsFixed(1);
    String peak = '—';
    if (hourCount.isNotEmpty) {
      final ph = hourCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      peak =
          '${DateFormat('h:00a').format(DateTime(0, 1, 1, ph))}–${DateFormat('h:00a').format(DateTime(0, 1, 1, ph + 1))}';
    }
    return {
      'total': data.length.toString(),
      'dept': topDept,
      'course': topCourse,
      'avg': '$avg visits',
      'peak': peak,
    };
  }

  String get _filterLabel {
    if (_selectedFilterCategory == 'Month' && _selectedFilterValue != null) {
      return _selectedFilterValue!;
    }
    return DateFormat('MMMM d, yyyy').format(_selectedDate);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT — bottom sheet with CSV / PDF choice
  // ═══════════════════════════════════════════════════════════════════════════
  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Export Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 4),
            Text(
              'Filter: $_filterLabel  •  ${_filteredData.length} record(s)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // CSV
            _exportOption(
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9),
              title: 'Export as CSV',
              subtitle: 'Opens in Excel / Google Sheets',
              onTap: () { Navigator.pop(context); _exportCSV(); },
            ),
            const Divider(height: 16),

            // PDF
            _exportOption(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFF1A4A8A),
              iconBg: const Color(0xFFE3EAF7),
              title: 'Export as PDF',
              subtitle: 'Formatted with WVSU header & summary',
              onTap: () { Navigator.pop(context); _exportPDF(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  // ─── CSV ──────────────────────────────────────────────────────────────────
  Future<void> _exportCSV() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final data = _filteredData;
      final rows = <List<dynamic>>[
        ['West Visayas State University'],
        ['LibGate Attendance Report'],
        ['Filter / Date: $_filterLabel'],
        ['Generated: ${DateFormat('MMMM d, yyyy – hh:mm a').format(DateTime.now())}'],
        ['Total Records: ${data.length}'],
        [],
        ['Date', 'Sign In', 'Sign Out', 'Name', 'Student ID', 'Year', 'Course', 'Department'],
      ];
      for (final row in data) {
        rows.add([
          row['date'] ?? '', row['signIn'] ?? '', row['signOut'] ?? '--',
          row['name'] ?? '', row['studentId'] ?? '', row['year'] ?? '',
          row['course'] ?? '', row['department'] ?? '',
        ]);
      }
      final bytes = Uint8List.fromList(
          utf8.encode(const ListToCsvConverter().convert(rows)));
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'WVSU_Attendance_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────
  Future<void> _exportPDF() async {
  if (_isExporting) return;
  setState(() => _isExporting = true);

  try {
    final data = _filteredData;
    final metrics = _calcMetrics(data);
    final pdf = pw.Document();

    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontRegular = await PdfGoogleFonts.notoSansRegular();

    //  LOGO
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/wvsu_logo.png'))
          .buffer
          .asUint8List(),
    );

    const wvsuBlue = PdfColor.fromInt(0xFF1A4A8A);
    const wvsuGold = PdfColor.fromInt(0xFFFFC107);
    const headerBg = PdfColor.fromInt(0xFFDDEAF8);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin:
              const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        ),

        // ✅ NEW HEADER
        header: (ctx) => pw.Column(
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: const pw.BoxDecoration(
                color: wvsuBlue,
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // LOGO
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(logo),
                  ),

                  pw.SizedBox(width: 12),

                  // CENTER TEXT
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'West Visayas State University',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Luna St., La Paz, Iloilo City (Libgate)',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'LibGate Attendance Report',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: wvsuGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Filter / Date: $_filterLabel',
                  style:
                      pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'Generated: ${DateFormat('MMM d, yyyy hh:mm a').format(DateTime.now())}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),

            pw.Divider(color: wvsuBlue, thickness: 1),
            pw.SizedBox(height: 4),
          ],
        ),

        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(
                font: fontRegular,
                fontSize: 9,
                color: PdfColors.grey600),
          ),
        ),

        build: (ctx) => [
          pw.Text('Summary',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: wvsuBlue)),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            children: [
              _pdfMetricRow('Total Entries',
                  metrics['total']!, fontBold, fontRegular, headerBg),
              _pdfMetricRow('Most Visited Department',
                  metrics['dept']!, fontBold, fontRegular, PdfColors.white),
              _pdfMetricRow('Most Visited Course',
                  metrics['course']!, fontBold, fontRegular, headerBg),
              _pdfMetricRow('Avg Visits / Student',
                  metrics['avg']!, fontBold, fontRegular, PdfColors.white),
              _pdfMetricRow('Peak Traffic Hour',
                  metrics['peak']!, fontBold, fontRegular, headerBg),
            ],
          ),

          pw.SizedBox(height: 14),

          pw.Text('Attendance Records',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: wvsuBlue)),

          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: wvsuBlue),
                children: [
                  'Date',
                  'Sign In',
                  'Sign Out',
                  'Name',
                  'Student ID',
                  'Yr',
                  'Course',
                  'Dept'
                ]
                    .map(
                      (h) => pw.Padding(
                        padding:
                            const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              ...data.map((row) => pw.TableRow(
                    children: [
                      row['date'] ?? '',
                      row['signIn'] ?? '',
                      row['signOut'] ?? '--',
                      row['name'] ?? '',
                      row['studentId'] ?? '',
                      row['year'] ?? '',
                      row['course'] ?? '',
                      row['department'] ?? '',
                    ]
                        .map(
                          (cell) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              cell.toString(),
                              style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 7.5),
                            ),
                          ),
                        )
                        .toList(),
                  )),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          'WVSU_Attendance_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isExporting = false);
  }
}

  pw.TableRow _pdfMetricRow(
      String label, String value, pw.Font bold, pw.Font regular, PdfColor bg) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9))),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 9))),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final metrics = _calcMetrics(filtered);
    final paged = _pagedData;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Row(
        children: [
          const SideBar(selectedIndex: 2),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFD6D6D6),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                    child: const Text(
                      'Attendance',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 14, 24, 6),
                    child: Text(
                      'Daily student entry logs – filtered by your selection',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),

                  // Thin export progress bar
                  if (_isExporting)
                    const LinearProgressIndicator(
                        backgroundColor: Color(0xFFDDEAF8), color: Colors.blueAccent),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ListView(
                        children: [
                          const SizedBox(height: 10),
                          _buildFilterBar(),
                          const SizedBox(height: 20),
                          _buildMetricsTable(metrics),
                          const SizedBox(height: 16),
                          _buildSearchAndCount(filtered.length),
                          const SizedBox(height: 12),
                          _buildDataTable(paged),
                          const SizedBox(height: 16),
                          // Pagination only renders when there's more than 1 page
                          if (_totalPages > 1) _buildPagination(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter bar ───────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date chip — always shows today by default
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(8),
          child: _filterChip(
            icon: Icons.calendar_today,
            label: _isSameDay(_selectedDate, DateTime.now())
                ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}'
                : DateFormat('MMM d, yyyy').format(_selectedDate),
            active: true,
          ),
        ),

        // Category filter dropdown
        _buildDropdown(
          hint: 'Filter by…',
          value: _selectedFilterCategory,
          items: _filterCategories,
          onChanged: (val) {
            setState(() {
              _selectedFilterCategory = val;
              _selectedFilterValue = null;
            });
            if (val == null) _fetchAttendance();
          },
        ),

        // Value dropdown
        if (_selectedFilterCategory != null)
          _buildDropdown(
            hint: 'Select $_selectedFilterCategory',
            value: _selectedFilterValue,
            items: _getChoicesForCategory(_selectedFilterCategory!),
            onChanged: (val) {
              setState(() => _selectedFilterValue = val);
              if (val != null) _fetchAttendance();
            },
          ),

        // Clear filter
        if (_selectedFilterCategory != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilterCategory = null;
                _selectedFilterValue = null;
              });
              _fetchAttendance();
            },
            icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
            label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),

        const Spacer(),

        // Export button → bottom sheet
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _showExportSheet,
          icon: _isExporting
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 16, color: Colors.white),
          label: Text(
            _isExporting ? 'Exporting…' : 'Export',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A4A8A),
            disabledBackgroundColor: Colors.grey.shade400,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({required IconData icon, required String label, bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDDEAF8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? Colors.blueAccent : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items
              .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<String> _getChoicesForCategory(String cat) {
    switch (cat) {
      case 'Program': return _programs;
      case 'Department': return _departments;
      case 'Month': return _months;
      default: return [];
    }
  }

  Future<void> _pickDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedFilterCategory = null;
        _selectedFilterValue = null;
      });
      _fetchAttendance();
    }
  }

  // ─── Search bar + record count ─────────────────────────────────────────────
  Widget _buildSearchAndCount(int count) {
    return Row(
      children: [
        Text('$count record${count == 1 ? '' : 's'} found',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const Spacer(),
        SizedBox(
          width: 280,
          height: 42,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
            decoration: InputDecoration(
              hintText: 'Search name or student ID…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _searchQuery = ''; _currentPage = 1; });
                      },
                    )
                  : const Icon(Icons.search, size: 18, color: Colors.blueAccent),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Metrics table ─────────────────────────────────────────────────────────
  Widget _buildMetricsTable(Map<String, String> m) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFDDEAF8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metric',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Value',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _metricRow('Total Entries', m['total']!),
          _metricRow('Most Visited Department', m['dept']!),
          _metricRow('Most Visited Course', m['course']!),
          _metricRow('Avg Visits / Student', m['avg']!),
          _metricRow('Peak Traffic Hour', m['peak']!, isLast: true),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200))),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Data table ────────────────────────────────────────────────────────────
  Widget _buildDataTable(List<Map<String, dynamic>> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text('No records found for this filter',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (ctx, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFDDEAF8)),
                    dataTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
                    columnSpacing: 28,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13),
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Sign In')),
                      DataColumn(label: Text('Sign Out')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Student ID')),
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Course')),
                      DataColumn(label: Text('Department')),
                    ],
                    rows: rows.map((item) => DataRow(cells: [
                          DataCell(Text(item['date'] ?? '')),
                          DataCell(Text(item['signIn'] ?? '')),
                          DataCell(Text(item['signOut'] ?? '--')),
                          DataCell(Text(item['name'] ?? '')),
                          DataCell(Text(item['studentId'] ?? '')),
                          DataCell(Text(item['year'] ?? '')),
                          DataCell(Text(item['course'] ?? '')),
                          DataCell(Text(item['department'] ?? '')),
                        ])).toList(),
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Dynamic pagination ────────────────────────────────────────────────────
  // Shows correct number of pages based on real record count.
  // Uses ellipsis (…) for large page counts.
  Widget _buildPagination() {
    final total = _totalPages;
    final current = _currentPage;

    // Build visible page numbers with ellipsis
    List<int?> pages = [];
    if (total <= 7) {
      pages = List.generate(total, (i) => i + 1);
    } else {
      pages.add(1);
      if (current > 3) pages.add(null);
      for (int p = (current - 1).clamp(2, total - 1);
          p <= (current + 1).clamp(2, total - 1); p++) {
        pages.add(p);
      }
      if (current < total - 2) pages.add(null);
      pages.add(total);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageNavBtn(
            icon: Icons.arrow_back_ios,
            onTap: current > 1 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 4),
          ...pages.map((p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: TextStyle(color: Colors.black38, fontSize: 13)),
              );
            }
            final isActive = p == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: isActive
                  ? Container(
                      width: 34, height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('$p',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  : InkWell(
                      onTap: () => setState(() => _currentPage = p),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        child: Text('$p',
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ),
                    ),
            );
          }),
          const SizedBox(width: 4),
          _pageNavBtn(
            icon: Icons.arrow_forward_ios,
            onTap: current < total ? () => setState(() => _currentPage++) : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Page $current of $total  (${_filteredData.length} total entries)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _pageNavBtn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34, height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon,
            size: 14,
            color: onTap != null ? Colors.blueAccent : Colors.grey.shade300),
      ),
    );
  }
}