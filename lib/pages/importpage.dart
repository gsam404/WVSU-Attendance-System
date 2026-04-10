import 'package:flutter/material.dart';
import './sidebar.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  // --- DATABASE READY STATE VARIABLES ---
  String? selectedFileName;
  int? recordCount;
  bool isReady = false;
  bool isUploading = false;

  // Placeholder lists for preview data (This would be populated after reading the file)
  final List<Map<String, String>> previewData = [
    {"id": "2024M0774", "name": "Mary Anne Labiscase", "course": "BSCS", "year": "2", "dept": "CICT"},
    {"id": "2024M1212", "name": "Jurish Pauleen Hitalia", "course": "BSN", "year": "4", "dept": "CON"},
    {"id": "2024M0909", "name": "Samantha Angela Galan", "course": "BSAM", "year": "3", "dept": "CAS"},
  ];

  // --- DATABASE READY METHODS ---
  Future<void> _pickFile() async {
    // TODO: Implement file_picker package here to select CSV/XLSX
    // FilePickerResult? result = await FilePicker.platform.pickFiles(...);
    
    // Simulating file selection for the UI
    setState(() {
      selectedFileName = "wvsu_2025-2026_2nd_sem.xlsx";
      recordCount = 9389;
      isReady = true;
    });
  }

  Future<void> _uploadToDatabase() async {
    if (!isReady) return;
    
    setState(() => isUploading = true);
    
    // TODO: Implement your ApiService call here to send the file to your database
    // await ApiService().uploadStudentFile(fileBytes);
    
    await Future.delayed(const Duration(seconds: 2)); // Simulating network delay
    
    setState(() {
      isUploading = false;
      isReady = false;
      selectedFileName = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully imported to database!"), backgroundColor: Colors.green),
      );
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Dashboard background
      body: Row(
        children: [
          const SideBar(selectedIndex: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    "Import",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ),
                
                // MAIN CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Import new student files", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                        const SizedBox(height: 15),
                        
                        // Drop Zone Box
                        _buildDropZone(),
                        const SizedBox(height: 20),
                        
                        // Middle Row (Selected File & Included Fields)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildSelectedFileBox()),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: _buildIncludedFieldsBox()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Preview Rows Box
                        _buildPreviewTableBox(),
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedFileName = null;
                                  isReady = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
                              ),
                              child: const Text("Cancel", style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: isUploading ? null : _uploadToDatabase,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                backgroundColor: const Color(0xFF6C91C2), // WVSU Blue-ish tone from image
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isUploading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Import Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
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

  // --- COMPONENT WIDGETS ---

  Widget _buildDropZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.upload_rounded, color: Color(0xFF6C91C2), size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Drop student file here", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Upload CSV or XLSX from admissions or registrar records.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _pickFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C91C2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Choose File", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildSelectedFileBox() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selected file", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (isReady) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFA7F3D0), borderRadius: BorderRadius.circular(10)),
                  child: const Text("Ready", style: TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const Text("Quick summary before import.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          if (isReady) Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.insert_drive_file, color: Color(0xFF3B82F6), size: 30),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedFileName ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${recordCount ?? 0} students found", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              )
            ],
          ) else const Center(child: Text("No file selected", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildIncludedFieldsBox() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Included fields", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip("StudentID"),
              _buildChip("FullName"),
              _buildChip("Course"),
              _buildChip("Department"),
              _buildChip("Year"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Color(0xFF374151), fontSize: 13)),
    );
  }

  Widget _buildPreviewTableBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Preview rows", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("Review a few records before continuing.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFEFF6FF)),
              columns: const [
                DataColumn(label: Text("StudentID", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("FullName", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Course", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Year", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: previewData.map((data) => DataRow(
                cells: [
                  DataCell(Text(data["id"]!)),
                  DataCell(Text(data["name"]!)),
                  DataCell(Text(data["course"]!)),
                  DataCell(Text(data["year"]!)),
                  DataCell(Text(data["dept"]!)),
                ],
              )).toList(),
            ),
          )
        ],
      ),
    );
  }
}