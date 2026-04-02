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

  
  final List<String> _programs = ['All Programs', 'BSCS', 'BSIT', 'BSIS', 'BLIS'];
  final List<String> _departments = ['All Departments', 'CAS', 'CBM', 'COD', 'COE', 'CICT', 'COL', 'COM', 'CON', 'PESCAR'];
  final List<String> _schoolYears = ['2024-2025', '2025-2026', '2026-2027'];
  final List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

 
  Stream<List<Map<String, dynamic>>> _getRealTimeAttendanceData() async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/get_attendance.php')
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          List<dynamic> jsonResponse = json.decode(response.body);
          yield jsonResponse.map((item) => item as Map<String, dynamic>).toList();
        } else {
          yield _getDummyData();
        }
      } catch (e) {
        yield _getDummyData();
      }
      
      await Future.delayed(const Duration(seconds: 3)); 
    }
  }

  
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

  // --- INTERACTIVE DATE PICKER ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        // Reset the dynamic dropdowns if a specific date is picked
        _selectedFilterCategory = null;
        _selectedFilterValue = null;
      });
    }
  }

  
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
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const SideBar(selectedIndex: 2),

          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6), 
              padding: const EdgeInsets.all(24.0), 
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getRealTimeAttendanceData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final attendanceData = snapshot.data ?? [];
                  final totalEntry = attendanceData.length.toString();
                  const mostVisitedDept = 'CICT'; 
                  const mostVisitedCourse = 'BSCS';
                  const avgVisits = '1.3 visits';
                  const peakHour = '11:00am-12:40pm';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily student entry logs - Filtered by your selection',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      // --- DYNAMIC FILTERS ARE BUILT HERE ---
                      _buildInteractiveFilters(),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: _buildMetricsTable(totalEntry, mostVisitedDept, mostVisitedCourse, avgVisits, peakHour),
                      ),
                      const SizedBox(height: 16),

                      _buildSearchBar(),
                      const SizedBox(height: 12),

                      Expanded(
                        child: Container(
                          width: double.infinity,
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
                          child: _buildDataTable(attendanceData),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildPagination(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildInteractiveFilters() {
    return Wrap(
      spacing: 12, 
      runSpacing: 12, 
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [

        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  _selectedDate == null 
                    ? 'Select Date' 
                    : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),

        // 2. Filter Category Dropdown
        _buildCustomDropdown(
          hint: 'Filter by...',
          value: _selectedFilterCategory,
          items: _filterCategories,
          onChanged: (val) {
            setState(() {
              _selectedFilterCategory = val;
              _selectedFilterValue = null; // Clear specific choice when category changes
              _selectedDate = null; // Optional: clear date if using categorical filter
            });
          },
        ),

        // 3. Dynamic Choices Dropdown (Only appears after category is selected)
        if (_selectedFilterCategory != null)
          _buildCustomDropdown(
            hint: 'Select $_selectedFilterCategory',
            value: _selectedFilterValue,
            items: _getChoicesForCategory(_selectedFilterCategory!),
            onChanged: (val) => setState(() => _selectedFilterValue = val),
          ),

        // 4. Export CSV Button
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

  Widget _buildDataTable(List<Map<String, dynamic>> realTimeData) {
    const headerStyle = TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold);
    const cellStyle = TextStyle(fontSize: 14, color: Colors.black87);

    List<DataRow> rows = realTimeData.map((data) {
      return DataRow(cells: [
        DataCell(Text(data['date']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['signIn']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['signOut']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['name']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['studentId']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['year']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['course']?.toString() ?? '', style: cellStyle)),
        DataCell(Text(data['department']?.toString() ?? '', style: cellStyle)),
      ]);
    }).toList();

    while (rows.length < 5) {
      rows.add(const DataRow(cells: [
        DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
        DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text(''))
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300), 
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFDDEAF8)),
                  border: TableBorder.all(color: Colors.grey.shade200),
                  columnSpacing: 40,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text('Date', style: headerStyle)),
                    DataColumn(label: Text('Sign in', style: headerStyle)),
                    DataColumn(label: Text('Sign out', style: headerStyle)),
                    DataColumn(label: Text('Name', style: headerStyle)),
                    DataColumn(label: Text('Student ID', style: headerStyle)),
                    DataColumn(label: Text('Year', style: headerStyle)),
                    DataColumn(label: Text('Course', style: headerStyle)),
                    DataColumn(label: Text('Department', style: headerStyle)),
                  ],
                  rows: rows,
                ),
              ),
            ),
          ),
        ),
      ],
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
}
