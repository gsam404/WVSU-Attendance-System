import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import './sidebar.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String? selectedFileName;
  int? recordCount;
  bool isReady = false;
  bool isUploading = false;
  Uint8List? selectedFileBytes;

  List<String> detectedFields = [];
  List<List<dynamic>> previewRows = [];

  // --- LOGIC: RESET & SUCCESS ---

  // Clears the selection without showing a "Success" snackbar
  void _resetUI() {
    setState(() {
      selectedFileName = null;
      selectedFileBytes = null;
      recordCount = null;
      isReady = false;
      isUploading = false;
      detectedFields = [];
      previewRows = [];
    });
  }

  // Called only after a successful server response
  void _handleSuccess(String message) {
    _resetUI();
    _showSnackBar(message, Colors.green);
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c),
    );
  }

  // --- LOGIC: FILE PICKING & PARSING ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final file = result.files.first;
      final bytes = file.bytes!;
      List<List<dynamic>> rows = [];

      try {
        if (file.extension == 'xlsx') {
          var excel = excel_pkg.Excel.decodeBytes(bytes);
          for (var table in excel.tables.keys) {
            rows = excel.tables[table]!.rows
                .map((row) => row.map((cell) => cell?.value).toList())
                .toList();
            break;
          }
        } else if (file.extension == 'csv') {
          final csvString = utf8.decode(bytes);
          rows = const CsvToListConverter().convert(csvString);
        }

        setState(() {
          selectedFileName = file.name;
          selectedFileBytes = bytes;
          isReady = true;

          if (rows.isNotEmpty) {
            recordCount = rows.length > 1 ? rows.length - 1 : 0;
            detectedFields = rows[0].map((e) => e?.toString().trim() ?? "Header").toList();
            previewRows = rows.skip(1).take(5).map((row) {
              return List.generate(detectedFields.length, (index) {
                return index < row.length ? row[index]?.toString() ?? "" : "";
              });
            }).toList();
          }
        });
      } catch (e) {
        _showSnackBar("Error reading file: $e", Colors.red);
      }
    }
  }

  // --- LOGIC: DATABASE IMPORT ---
  Future<void> _uploadToDatabase() async {
    if (!isReady || selectedFileBytes == null) return;
    
    setState(() => isUploading = true);
    
    try {
      // Note: Use 'http://10.0.2.2/api/upload.php' if using Android Emulator
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost/api/upload.php'));
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          selectedFileBytes!, 
          filename: selectedFileName
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      // Parse the JSON response from your upload.php
      final result = json.decode(responseData);

      if (response.statusCode == 200 && result['status'] == 'success') {
        _handleSuccess(result['message']);
      } else {
        _showSnackBar(result['message'] ?? "Server error occurred.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Connection failed. Check if XAMPP is running.", Colors.red);
      print("Upload Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Row(
        children: [
          const SideBar(selectedIndex: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Import new student files", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                        const SizedBox(height: 20),
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
                        _buildPreviewTableCard(),
                        const SizedBox(height: 30),
                        _buildActionFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity, color: const Color(0xFFD6D6D6),
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
    child: const Text("Import", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  );

  Widget _buildDropZone() => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.cloud_upload_outlined, size: 30, color: Color(0xFF6C91C2)),
      ),
      const SizedBox(width: 20),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Drop student file here", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Upload CSV or XLSX from admissions or registrar records.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
      ElevatedButton(
        onPressed: _pickFile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text("Choose File", style: TextStyle(color: Colors.white)),
      )
    ]),
  );

  Widget _buildFileSummaryCard() {
    IconData fileIcon = Icons.table_chart;
    Color iconColor = Colors.green;

    return Container(
      height: 180, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Selected file", style: TextStyle(fontWeight: FontWeight.bold)),
            if (isReady) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
              child: const Text("Ready", style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Text("Quick summary before import.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const Spacer(),
        if (isReady) Row(children: [
          Icon(fileIcon, color: iconColor, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedFileName ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
            Text("${recordCount ?? 0} students found", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
        ]) else const Center(child: Text("No file selected", style: TextStyle(color: Colors.grey))),
      ]),
    );
  }

  Widget _buildIncludedFieldsCard() => Container(
    height: 180, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Included fields", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      if (detectedFields.isEmpty) 
        const Expanded(child: Center(child: Text("Select a file to see fields", style: TextStyle(color: Colors.grey, fontSize: 12))))
      else Wrap(
        spacing: 8, runSpacing: 8,
        children: detectedFields.map((f) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
          child: Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
        )).toList(),
      )
    ]),
  );

  Widget _buildPreviewTableCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Preview rows", style: TextStyle(fontWeight: FontWeight.bold)),
      const Text("Review a few records before continuing.", style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 20),
      if (previewRows.isEmpty || detectedFields.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text("No data to preview")),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: detectedFields.asMap().entries.map((e) => DataColumn(
              label: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))
            ).toList(),
            rows: previewRows.map((row) => DataRow(
              cells: row.map((c) => DataCell(Text(c.toString(), style: const TextStyle(fontSize: 12)))).toList(),
            )).toList(),
          ),
        ),
    ]),
  );

  Widget _buildActionFooter() => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    OutlinedButton(
      onPressed: _resetUI, // FIX: Resets the page without showing success snackbar
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
    ),
    const SizedBox(width: 15),
    ElevatedButton(
      onPressed: isUploading || !isReady ? null : _uploadToDatabase,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C91C2), 
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: isUploading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Text("Import Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    )
  ]);
}