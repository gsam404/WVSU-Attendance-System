import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime? _selectedDate;
  String? _selectedFilterCategory; 
  String? _selectedFilterValue;

  final List<String> _filterCategories = ['Program', 'Department', 'School Year', 'Month'];
  final List<String> _schoolYears = ['2024-2025', '2025-2026', '2026-2027'];
  final List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  // Now dynamically loaded from the database!
  List<String> _programs = ['All Programs'];
  List<String> _departments = ['All Departments'];

  @override
  void initState() {
    super.initState();
    _fetchAcademicFilters();
  }

  // Fetches the real Departments and Courses from your Academic Setup API
  Future<void> _fetchAcademicFilters() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.55/libgate_api/academic_api.php?action=fetch'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _departments = ['All Departments'];
            _programs = ['All Programs'];
            
            for (var dept in data['data']) {
              _departments.add(dept['code']); 
              if (dept['courses'] != null) {
                for (var course in dept['courses']) {
                  _programs.add(course['code']); 
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading filters: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> _getRealTimeAttendanceData() async* {
    while (true) {
      try {
        // Attempt to fetch data from the server (Updated IP to your real backend!)
        final response = await http.get(
          Uri.parse('http://192.168.1.55/libgate_api/get_attendance.php')
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          List<dynamic> jsonResponse = json.decode(response.body);
          // Yield the real-time data
          yield jsonResponse.map((item) => item as Map<String, dynamic>).toList();
        } else {
          // If server error, fall back to dummy data
          yield _getDummyData();
        }
      } catch (e) {
        // If connection error, fall back to dummy data
        yield _getDummyData();
      }
      
      // Delay for real-time polling
      await Future.delayed(const Duration(seconds: 3)); 
    }
  }

  // Fallback data if connection fails
  List<Map<String, dynamic>> _getDummyData() {
    return [
      {
        'date': '02/06/2026',
        'signIn': '10:00am',
        'signOut': '11:30am',
        'name': 'Mary Anne Labiscase',
        'studentId': '2024M1111',
        'year': '2',
        'course': 'BSCS',
        'department': 'CICT',
      },
      {
        'date': '02/06/2026',
        'signIn': '10:15am',
        'signOut': '12:00pm',
        'name': 'John Doe',
        'studentId': '2024M1112',
        'year': '1',
        'course': 'BSIT',
        'department': 'CICT',
      }
    ];
  }

  // Opens the Flutter Date Picker
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // Styling for the date picker (matching Blue accent)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87, 
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Clear dependent filters
        _selectedFilterCategory = null;
        _selectedFilterValue = null;
      });
    }
  }

  // Returns the dropdown items based on the selected category
  List<String> _getChoicesForCategory(String category) {
    switch (category) {
      case 'Program': return _programs;
      case 'Department': return _departments;
      case 'School Year': return _schoolYears;
      case 'Month': return _months;
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Original Background Color
      body: Row(
        children: [
          const SideBar(selectedIndex: 2),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER CONTAINER (Original Styling) ---
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFD6D6D6),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                    child: const Text(
                      "Attendance ",
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  // --- SUBTITLE ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 16, 24, 24),
                    child: Text(
                      'Daily student entry logs - Filtered by your selection',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),

                  // --- MAIN CONTENT WITH STREAM ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _getRealTimeAttendanceData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // Data and metric calculations
                          final attendanceData = snapshot.data ?? [];
                          final totalEntry = attendanceData.length.toString();
                          // Placeholder logic (needs real calculations)
                          const mostVisitedDept = 'CICT'; 
                          const mostVisitedCourse = 'BSCS';
                          const avgVisits = '1.3 visits';
                          const peakHour = '11:00am-12:40pm';

                          return ListView( 
                            children: [
                              _buildInteractiveFilters(),
                              const SizedBox(height: 20),
                              // Spanning metrics table (Full Width)
                              _buildMetricsTable(totalEntry, mostVisitedDept, mostVisitedCourse, avgVisits, peakHour),
                              const SizedBox(height: 16),
                              // Search bar aligned to right
                              _buildSearchBar(),
                              const SizedBox(height: 12),
                              // Main Data Table within a container for styling
                              Container(
                                width: double.infinity, // <-- ADDED THIS to force container stretch
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: LayoutBuilder( // <-- ADDED THIS to force table width
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth), // Matches parent width!
                                        child: _buildFixedDataTable(attendanceData),
                                      ),
                                    );
                                  }
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPagination(),
                              const SizedBox(height: 40), // Bottom padding
                            ],
                          );
                        },
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

  // --- COMPONENT WIDGETS ---

  Widget _buildInteractiveFilters() {
    return Wrap(
      spacing: 12, 
      runSpacing: 12, 
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => _pickDate(context),
          child: _buildSimpleFilterCard(
            icon: Icons.calendar_today,
            label: _selectedDate == null 
              ? 'Feb 06, 2026'
              : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
          ),
        ),

        _buildCustomDropdown(
          hint: 'Filter by...',
          value: _selectedFilterCategory,
          items: _filterCategories,
          onChanged: (val) {
            setState(() {
              _selectedFilterCategory = val;
              _selectedFilterValue = null;
              _selectedDate = null; 
            });
          },
        ),

        if (_selectedFilterCategory != null)
          _buildCustomDropdown(
            hint: 'Select $_selectedFilterCategory',
            value: _selectedFilterValue,
            items: _getChoicesForCategory(_selectedFilterCategory!),
            onChanged: (val) => setState(() => _selectedFilterValue = val),
          ),

        const Spacer(),

        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 16, color: Colors.white),
          label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleFilterCard({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({
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
          hint: Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 300, 
        height: 44,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search Student Name or ID...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            suffixIcon: const Icon(Icons.search, size: 20, color: Colors.blueAccent),
            filled: true, 
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: Colors.grey.shade300)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: Colors.grey.shade300)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsTable(String total, String dept, String course, String avg, String peak) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metric', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Value', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildMetricRow('Total entry', total),
          _buildMetricRow('Most visited by department', dept),
          _buildMetricRow('Most visited by course', course),
          _buildMetricRow('Average visits per student', avg),
          _buildMetricRow('Peak traffic hour', peak, isLast: true),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String metric, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200))),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.blueAccent), onPressed: () {}),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(6)),
          child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: () {}, child: const Text('2', style: TextStyle(color: Colors.black54))),
        TextButton(onPressed: () {}, child: const Text('3', style: TextStyle(color: Colors.black54))),
        IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent), onPressed: () {}),
      ],
    );
  }

  Widget _buildFixedDataTable(List<Map<String, dynamic>> attendanceData) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFDDEAF8)), 
      dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
      columnSpacing: 30, 
      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14),
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
      rows: attendanceData.map((item) => DataRow(
        cells: [
          DataCell(Text(item['date'] ?? '')),
          DataCell(Text(item['signIn'] ?? '')),
          DataCell(Text(item['signOut'] ?? '')),
          DataCell(Text(item['name'] ?? '')),
          DataCell(Text(item['studentId'] ?? '')),
          DataCell(Text(item['year'] ?? '')),
          DataCell(Text(item['course'] ?? '')),
          DataCell(Text(item['department'] ?? '')),
        ],
      )).toList(),
    );
  }
}