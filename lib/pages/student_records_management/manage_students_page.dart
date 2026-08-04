import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wvsu_attendance_system/config/api_config.dart';
import 'package:wvsu_attendance_system/pages/admin_session.dart';
import '../../models/student.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  static const int pageSize = 15;

  // Fixed widths per column so the table layout never shifts between pages,
  // regardless of how long or short the content in each cell is.
  static const Map<String, double> _columnWidths = {
    'Student Number': 160,
    'Last Name': 160,
    'First Name': 160,
    'Middle Name': 160,
    'Program': 120,
    'Year Level': 110,
    'Section': 110,
    'Email': 260,
  };

  final TextEditingController searchController = TextEditingController();
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  String searchQuery = "";
  int currentPage = 0;

  bool isLoading = true;
  String? loadError;

  List<Student> students = [];

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
        currentPage = 0;
      });
    });

    _loadStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // FETCH IMPORTED STUDENTS
  // Every admin (including main_admin) is strictly scoped to their own
  // campus_id — students only appear under the campus they were uploaded to.
  // ---------------------------------------------------------------------
  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      if (AdminSession.campusId == null) {
        setState(() {
          loadError = "No campus assigned to this account.";
          isLoading = false;
        });
        return;
      }

      final uri = Uri.parse(ApiConfig.students).replace(queryParameters: {
        'campus_id': AdminSession.campusId.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map && decoded['status'] == 'error') {
          setState(() {
            loadError = decoded['message']?.toString() ?? 'Failed to load students.';
            isLoading = false;
          });
          return;
        }

        final List<dynamic> rows =
            decoded is List ? decoded : (decoded['data'] as List? ?? []);

        setState(() {
          students = rows
              .map((row) => Student.fromJson(row as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          loadError = "Server error (${response.statusCode}).";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        loadError = "Could not load students: $e";
        isLoading = false;
      });
    }
  }

  List<Student> get _filteredStudents {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return students;

    return students.where((s) {
      return s.studentId.toLowerCase().contains(query) ||
          s.firstName.toLowerCase().contains(query) ||
          s.lastName.toLowerCase().contains(query) ||
          s.middleName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  int get _pageCount {
    final count = _filteredStudents.length;
    return count == 0 ? 1 : (count + pageSize - 1) ~/ pageSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Students",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: isLoading ? null : _loadStudents,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search Student",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loadError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Text(
          "No students found.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildFixedTable()),
        const SizedBox(height: 10),
        _buildPagination(),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FIXED-WIDTH TABLE
  // Column widths never change based on cell content (no reflow between
  // pages). Header row is pinned; only the body rows scroll vertically if
  // they don't fit, and the whole table scrolls horizontally if needed.
  // ---------------------------------------------------------------------
  Widget _buildFixedTable() {
    final page = currentPage >= _pageCount ? _pageCount - 1 : currentPage;
    final pageRows = _filteredStudents
        .skip(page * pageSize)
        .take(pageSize)
        .toList(growable: false);

    final tableWidth = _columnWidths.values.reduce((a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        notificationPredicate: (notif) => notif.depth == 0,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pinned header — never scrolls vertically
                _buildRow(
                  _columnWidths.keys.toList(),
                  isHeader: true,
                ),
                // Scrollable body rows
                Flexible(
                  child: Scrollbar(
                    controller: verticalController,
                    thumbVisibility: true,
                    notificationPredicate: (notif) => notif.depth == 0,
                    child: SingleChildScrollView(
                      controller: verticalController,
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: pageRows
                            .map(
                              (s) => _buildRow([
                                s.studentId,
                                s.lastName,
                                s.firstName,
                                s.middleName,
                                s.program,
                                s.year,
                                s.section,
                                s.email,
                              ]),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> values, {bool isHeader = false}) {
    final widths = _columnWidths.values.toList();

    return SizedBox(
      height: 40,
      child: Row(
        children: List.generate(widths.length, (index) {
          final value = index < values.length ? values[index] : '';
          return SizedBox(
            width: widths[index],
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
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

  // ---------------------------------------------------------------------
  // CENTERED PAGINATION
  // ---------------------------------------------------------------------
  Widget _buildPagination() {
    final page = currentPage >= _pageCount ? _pageCount - 1 : currentPage;
    final hasPrevious = page > 0;
    final hasNext = page < _pageCount - 1;
    final total = _filteredStudents.length;
    final startRow = total == 0 ? 0 : page * pageSize + 1;
    final endRow = (page * pageSize + pageSize) > total ? total : page * pageSize + pageSize;

    return Column(
      children: [
        Text(
          "Showing $startRow-$endRow of $total students",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: hasPrevious ? () => setState(() => currentPage = page - 1) : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text("Previous"),
            ),
            const SizedBox(width: 12),
            Text('Page ${page + 1} of $_pageCount',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: hasNext ? () => setState(() => currentPage = page + 1) : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text("Next"),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ],
    );
  }
}