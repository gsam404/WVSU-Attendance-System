import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:wvsu_attendance_system/pages/admin_session.dart'; // ← FIX: import session
import 'package:wvsu_attendance_system/config/api_config.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _MissingFieldEntry {
  final int rowNumber;
  final String studentId;
  final List<String> fields;

  const _MissingFieldEntry({
    required this.rowNumber,
    required this.studentId,
    required this.fields,
  });
}

class _ImportPageState extends State<ImportPage> {
  static const int _pageSize = 15;
  String? selectedFileName;
  int? recordCount;
  bool isReady = false;
  bool isUploading = false;
  bool isProcessingFile = false;
  bool importReady = false;
  int totalRows = 0;
  int validRows = 0;
  int missingFieldCount = 0;
  List<String> duplicateStudentIds = [];
  List<String> missingRequiredColumns = [];
  List<_MissingFieldEntry> missingFieldRows = [];
  List<String> optionalFieldNotices = [];
  List<String> validationMessages = [];
  List<String> requiredFields = [
    'Student ID',
    'First Name',
    'Last Name',
    'Email Address',
    'Course',
    'Year',
  ];

  // We always store a CSV-ready byte payload to send to the server
  Uint8List? _csvBytesToUpload;

  List<String> detectedFields = [];
  List<List<dynamic>> previewRows = [];
  final ScrollController _previewHorizontalController = ScrollController();
  final TextEditingController _previewSearchController =
      TextEditingController();
  String _previewSearchQuery = '';
  int _studentIdColumnIndex = -1;
  int _previewPage = 0;
  int _missingFieldPage = 0;
  int _duplicatePage = 0;

  @override
  void dispose() {
    _previewHorizontalController.dispose();
    _previewSearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // RESET & FEEDBACK
  // ---------------------------------------------------------------------------

  void _resetUI() {
    setState(() {
      selectedFileName = null;
      _csvBytesToUpload = null;
      recordCount = null;
      totalRows = 0;
      validRows = 0;
      missingFieldCount = 0;
      duplicateStudentIds = [];
      missingRequiredColumns = [];
      missingFieldRows = [];
      optionalFieldNotices = [];
      validationMessages = [];
      importReady = false;
      isReady = false;
      isUploading = false;
      isProcessingFile = false;
      detectedFields = [];
      previewRows = [];
      _previewSearchController.clear();
      _previewSearchQuery = '';
      _studentIdColumnIndex = -1;
      _previewPage = 0;
      _missingFieldPage = 0;
      _duplicatePage = 0;
    });
  }

  void _handleSuccess(String message) {
    _resetUI();
    _showSnackBar(message, Colors.green);
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c),
    );
  }

  // ---------------------------------------------------------------------------
  // FILE PICKING & PARSING
  // Supports CSV and XLSX. XLSX is converted to CSV so the same PHP backend
  // can handle both without modification.
  // ---------------------------------------------------------------------------

  Future<void> _pickFile() async {
    if (isProcessingFile) return;

    setState(() {
      isProcessingFile = true;
      selectedFileName = null;
      _csvBytesToUpload = null;
      isReady = false;
      importReady = false;
      detectedFields = [];
      previewRows = [];
      duplicateStudentIds = [];
      missingRequiredColumns = [];
      missingFieldRows = [];
      optionalFieldNotices = [];
      validationMessages = [];
      _previewSearchController.clear();
      _previewSearchQuery = '';
      _studentIdColumnIndex = -1;
      _previewPage = 0;
      _missingFieldPage = 0;
      _duplicatePage = 0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );

      if (result == null || result.files.first.bytes == null) return;

      final file = result.files.first;
      final bytes = file.bytes!;
      setState(() => selectedFileName = file.name);

      // Give Flutter a frame to paint the filename and spinner before doing
      // synchronous CSV/XLSX decoding, which may take time for large files.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      List<List<dynamic>> rows = [];
      if (file.extension?.toLowerCase() == 'xlsx') {
        // --- Parse XLSX ---
        final xlsxFile = excel_pkg.Excel.decodeBytes(bytes);
        for (final sheetName in xlsxFile.tables.keys) {
          rows = xlsxFile.tables[sheetName]!.rows
              .map((row) => row.map((cell) => cell?.value ?? "").toList())
              .toList();
          break; // only first sheet
        }

        // Convert the parsed rows to a CSV byte payload
        final csvString = const ListToCsvConverter().convert(
          rows.map((r) => r.map((c) => c.toString()).toList()).toList(),
        );
        _csvBytesToUpload = Uint8List.fromList(utf8.encode(csvString));
      } else {
        // --- Parse CSV ---
        // Keep the decoded string temporary so it can be reclaimed once the
        // converter has produced the row list.
        rows = const CsvToListConverter().convert(utf8.decode(bytes));
        _csvBytesToUpload = bytes; // already CSV, send as-is
      }

      if (rows.isEmpty) {
        _showSnackBar("The file appears to be empty.", Colors.orange);
        return;
      }

      final rawHeaders =
          rows.first.map((e) => e.toString().trim()).toList(growable: false);
      final lowerHeaders = rawHeaders
          .map((e) => e.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' '))
          .toList(growable: false);

      final studentIdIndex = lowerHeaders.indexWhere(
          (header) => header.contains('student') || header.contains('id'));
      final emailIndex =
          lowerHeaders.indexWhere((header) => header.contains('email'));
      final firstNameIndex =
          lowerHeaders.indexWhere((header) => header.contains('first'));
      final lastNameIndex =
          lowerHeaders.indexWhere((header) => header.contains('last'));
      final courseIndex = lowerHeaders.indexWhere((header) =>
          header.contains('course') ||
          header.contains('department') ||
          header.contains('program'));
      final yearIndex =
          lowerHeaders.indexWhere((header) => header.contains('year'));
      final sectionIndex =
          lowerHeaders.indexWhere((header) => header.contains('section'));

      final missingHeaders = <String>[];
      if (studentIdIndex < 0) missingHeaders.add('Student ID');
      if (emailIndex < 0) missingHeaders.add('Email Address');
      if (firstNameIndex < 0) missingHeaders.add('First Name');
      if (lastNameIndex < 0) missingHeaders.add('Last Name');
      if (courseIndex < 0) missingHeaders.add('Course / Program');
      if (yearIndex < 0) missingHeaders.add('Year');

      final optionalNotices = <String>[];
      if (sectionIndex < 0) {
        optionalNotices.add(
            'Section is optional. No Section column was found; imports will use blank sections.');
      }

      final duplicateSet = <String>{};
      final duplicates = <String>{};
      final missingFieldEntries = <_MissingFieldEntry>[];
      var missingFields = 0;
      var valid = 0;
      var blankSectionCount = 0;

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final studentId = studentIdIndex >= 0 && studentIdIndex < row.length
            ? row[studentIdIndex].toString().trim()
            : '';
        final email = emailIndex >= 0 && emailIndex < row.length
            ? row[emailIndex].toString().trim()
            : '';
        final firstName = firstNameIndex >= 0 && firstNameIndex < row.length
            ? row[firstNameIndex].toString().trim()
            : '';
        final lastName = lastNameIndex >= 0 && lastNameIndex < row.length
            ? row[lastNameIndex].toString().trim()
            : '';
        final course = courseIndex >= 0 && courseIndex < row.length
            ? row[courseIndex].toString().trim()
            : '';
        final year = yearIndex >= 0 && yearIndex < row.length
            ? row[yearIndex].toString().trim()
            : '';
        final section = sectionIndex >= 0 && sectionIndex < row.length
            ? row[sectionIndex].toString().trim()
            : '';

        final missingForRow = <String>[];
        if (studentId.isEmpty) missingForRow.add('Student ID');
        if (email.isEmpty) missingForRow.add('Email Address');
        if (firstName.isEmpty) missingForRow.add('First Name');
        if (lastName.isEmpty) missingForRow.add('Last Name');
        if (course.isEmpty) missingForRow.add('Course / Program');
        if (year.isEmpty) missingForRow.add('Year');
        if (sectionIndex >= 0 && section.isEmpty) {
          blankSectionCount++;
          missingForRow.add('Section (Optional)');
        }

        if (missingForRow.isNotEmpty) {
          missingFields++;
          missingFieldEntries.add(_MissingFieldEntry(
            rowNumber: i + 1,
            studentId: studentId.isEmpty ? '(blank)' : studentId,
            fields: List.unmodifiable(missingForRow),
          ));
        }

        if (studentId.isNotEmpty) {
          if (duplicateSet.contains(studentId)) {
            duplicates.add(studentId);
          } else {
            duplicateSet.add(studentId);
          }
        }

        final hasRequiredMissing = studentId.isEmpty ||
            email.isEmpty ||
            firstName.isEmpty ||
            lastName.isEmpty ||
            course.isEmpty ||
            year.isEmpty;

        if (missingForRow.isEmpty) {
          valid++;
        }
      }

      /*   if (sectionIndex >= 0 && blankSectionCount > 0) {
        optionalNotices.add(
            '$blankSectionCount row(s) have no Section. They can still be imported with a blank Section.');
      } */

      final summaryMessages = <String>[];
      if (missingHeaders.isNotEmpty) {
        summaryMessages
            .add('Missing required columns: ${missingHeaders.join(', ')}');
      }
      if (duplicates.isNotEmpty) {
        summaryMessages.add('Duplicate Student IDs found in file.');
      }

      setState(() {
        selectedFileName = file.name;
        isReady = true;
        totalRows = rows.length - 1;
        validRows = valid;
        missingFieldCount = missingFields;
        duplicateStudentIds = duplicates.toList();
        missingRequiredColumns = missingHeaders;
        missingFieldRows = missingFieldEntries;
        optionalFieldNotices = optionalNotices;
        validationMessages = summaryMessages;
        importReady = missingHeaders.isEmpty && duplicates.isEmpty;
        recordCount = totalRows;
        _studentIdColumnIndex = studentIdIndex;
        _previewPage = 0;
        _missingFieldPage = 0;
        _duplicatePage = 0;
        detectedFields = rawHeaders
            .map((e) => e.isEmpty ? 'Column' : e)
            .toList(growable: false);
        // Keep every data row in the preview, but reuse the parser's row lists
        // instead of creating a second string copy of every cell.
        previewRows = rows.skip(1).toList(growable: false);
      });
    } catch (e) {
      _showSnackBar("Error reading file: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isProcessingFile = false);
    }
  }

  Future<void> _uploadToDatabase() async {
    if (!isReady || _csvBytesToUpload == null) return;

    setState(() => isUploading = true);

    try {
      final uri = Uri.parse(ApiConfig.upload);
      final request = http.MultipartRequest('POST', uri);

      // ── FIX: attach the logged-in admin's ID so PHP knows whose data this is ──
      request.fields['admin_id'] = AdminSession.id;

      // Always send with a .csv extension so PHP accepts it
      final uploadName = selectedFileName!
          .replaceAll(RegExp(r'\.(xlsx|xls)$', caseSensitive: false), '.csv');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _csvBytesToUpload!,
          filename: uploadName,
        ),
      );

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();

      final result = json.decode(responseBody);

      if (streamed.statusCode == 200 && result['status'] == 'success') {
        _handleSuccess(result['message']);
      } else {
        _showSnackBar(
            result['message'] ?? "Server error occurred.", Colors.red);
      }
    } catch (e) {
      _showSnackBar(
          "Connection failed. Check if XAMPP is running.", Colors.red);
      debugPrint("Upload Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  List<List<dynamic>> get _filteredPreviewRows {
    final query = _previewSearchQuery.trim().toLowerCase();
    if (query.isEmpty || _studentIdColumnIndex < 0) return previewRows;

    return previewRows.where((row) {
      if (_studentIdColumnIndex >= row.length) return false;
      return row[_studentIdColumnIndex]
          .toString()
          .toLowerCase()
          .contains(query);
    }).toList(growable: false);
  }

  int _pageCount(int itemCount) =>
      itemCount == 0 ? 1 : (itemCount + _pageSize - 1) ~/ _pageSize;

  Widget _buildPageArrows({
    required int page,
    required int pageCount,
    required ValueChanged<int> onPageChanged,
  }) {
    final hasPrevious = page > 0;
    final hasNext = page < pageCount - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous 15 rows',
          onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        Text('Page ${page + 1} of $pageCount',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        IconButton(
          tooltip: 'Next 15 rows',
          onPressed: hasNext ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropZone(),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFileSummaryCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildIncludedFieldsCard()),
            ],
          ),
          const SizedBox(height: 25),
          if (isReady) ...[
            _buildValidationDetailsCard(),
            const SizedBox(height: 25),
          ],
          _buildPreviewTableCard(),
          const SizedBox(height: 30),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildDropZone() => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.cloud_upload_outlined,
                size: 30, color: Color(0xFF6C91C2)),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Drop student file here",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "Upload CSV or XLSX — both formats are supported.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isProcessingFile ? null : _pickFile,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: isProcessingFile
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text("Reading..."),
                    ],
                  )
                : const Text("Choose File",
                    style: TextStyle(color: Colors.white)),
          )
        ]),
      );

  Widget _buildFileSummaryCard() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Selected file",
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (isProcessingFile || isUploading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(isUploading ? 'Uploading...' : 'Reading...',
                        style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else if (isReady)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(importReady ? 'Ready' : 'Validation needed',
                    style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (isProcessingFile)
          Row(children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedFileName == null
                    ? 'Waiting for file...'
                    : 'Reading $selectedFileName',
                style: const TextStyle(color: Color(0xFF374151), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ])
        else if (isReady)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedFileName ?? "",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text("Total rows: $totalRows",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text("Valid rows: $validRows",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text("Missing-field rows: $missingFieldCount",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text("Duplicate IDs: ${duplicateStudentIds.length}",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])
        else
          const Center(
              child: Text("No file selected",
                  style: TextStyle(color: Colors.grey))),
      ]),
    );
  }

  Widget _buildIncludedFieldsCard() => Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Identified fields",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: detectedFields.isEmpty
                ? const Center(
                    child: Text("Select a file to see fields",
                        style: TextStyle(color: Colors.grey, fontSize: 12)))
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detectedFields
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(f,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF4B5563))),
                              ))
                          .toList(),
                    ),
                  ),
          ),
        ]),
      );

  Widget _buildDuplicateDetails() {
    final pageCount = _pageCount(duplicateStudentIds.length);
    final page = _duplicatePage < pageCount ? _duplicatePage : pageCount - 1;
    final pageItems = duplicateStudentIds
        .skip(page * _pageSize)
        .take(_pageSize)
        .toList(growable: false);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Duplicate Student IDs:',
          style:
              TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: pageItems
            .map((id) => Chip(
                  label: Text(id),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFFEE2E2),
                  side: BorderSide.none,
                ))
            .toList(),
      ),
      _buildPageArrows(
        page: page,
        pageCount: pageCount,
        onPageChanged: (value) => setState(() => _duplicatePage = value),
      ),
    ]);
  }

  Widget _buildMissingFieldDetails() {
    final pageCount = _pageCount(missingFieldRows.length);

    final currentPage =
        _missingFieldPage >= pageCount ? pageCount - 1 : _missingFieldPage;

    final pageItems =
        missingFieldRows.skip(currentPage * _pageSize).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rows with missing values (${missingFieldRows.length})',
          style: const TextStyle(
            color: Color(0xFFB45309),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 620,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageItems.length,
                  itemBuilder: (context, index) {
                    final entry = pageItems[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        "Row ${entry.rowNumber} • Student ID: ${entry.studentId}\n"
                        "Missing: ${entry.fields.join(', ')}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 45,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                _missingFieldPage--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    const Spacer(),
                    Text(
                      "${currentPage + 1}/$pageCount",
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: currentPage < pageCount - 1
                          ? () {
                              setState(() {
                                _missingFieldPage++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidationDetailsCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Validation details',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (missingRequiredColumns.isNotEmpty) ...[
            const Text('Missing required columns:',
                style: TextStyle(
                    color: Color(0xFFB45309), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(missingRequiredColumns.join(', '),
                style: const TextStyle(color: Color(0xFF92400E))),
            const SizedBox(height: 12),
          ],
          if (optionalFieldNotices.isNotEmpty) ...[
            const Text('Optional field notice:',
                style: TextStyle(
                    color: Color(0xFF166534), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...optionalFieldNotices.map((notice) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(notice,
                      style: const TextStyle(color: Color(0xFF166534))),
                )),
            const SizedBox(height: 12),
          ],
          if (duplicateStudentIds.isNotEmpty) ...[
            _buildDuplicateDetails(),
            const SizedBox(height: 12),
          ],
          if (missingFieldRows.isNotEmpty) ...[
            Text('Rows with missing values (${missingFieldRows.length}):',
                style: const TextStyle(
                    color: Color(0xFFB45309), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildMissingFieldDetails(),
          ],
          if (missingRequiredColumns.isEmpty &&
              duplicateStudentIds.isEmpty &&
              missingFieldRows.isEmpty)
            const Text('No validation problems found.',
                style: TextStyle(color: Color(0xFF166534))),
        ]),
      );

  Widget _buildPreviewTableCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Preview rows",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
              "Review all records before continuing. Use the scrollbars to view the full table.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          if (previewRows.isEmpty || detectedFields.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text("No data to preview")),
            )
          else
            _buildLazyPreviewTable(),
        ]),
      );

  Widget _buildLazyPreviewTable() {
    const columnWidth = 180.0;
    const rowHeight = 40.0;
    const tableHeight = 640.0;

    final filteredRows = _filteredPreviewRows;
    final pageCount = _pageCount(filteredRows.length);

    final currentPage =
        _previewPage >= pageCount ? pageCount - 1 : _previewPage;

    final pageRows =
        filteredRows.skip(currentPage * _pageSize).take(_pageSize).toList();

    final tableWidth = detectedFields.length * columnWidth;

    return SizedBox(
      height: tableHeight,
      child: Row(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _previewHorizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _previewHorizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _buildPreviewTableRow(
                        detectedFields,
                        width: columnWidth,
                        height: rowHeight,
                        isHeader: true,
                      ),
                      ...pageRows.map(
                        (row) => _buildPreviewTableRow(
                          row,
                          width: columnWidth,
                          height: rowHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Column(
              children: [
                IconButton(
                  tooltip: "Previous",
                  onPressed: currentPage > 0
                      ? () {
                          setState(() {
                            _previewPage--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                const Spacer(),
                Text(
                  "${currentPage + 1}/$pageCount",
                  style: const TextStyle(fontSize: 11),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Next",
                  onPressed: currentPage < pageCount - 1
                      ? () {
                          setState(() {
                            _previewPage++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTableRow(
    List<dynamic> values, {
    required double width,
    required double height,
    bool isHeader = false,
  }) {
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(detectedFields.length, (index) {
          final value = index < values.length ? values[index].toString() : '';
          return SizedBox(
            width: width,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isHeader ? const Color(0xFFF8FAFC) : Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Tooltip(
                message: value,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionFooter() =>
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        OutlinedButton(
          onPressed: isProcessingFile || isUploading ? null : _resetUI,
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text("Cancel", style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: isUploading || !importReady ? null : _uploadToDatabase,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C91C2),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: isUploading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("Import Students",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ]);
}
