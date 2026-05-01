import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wvsu_attendance_system/pages/sidebar.dart';
import 'package:wvsu_attendance_system/pages/adminSession.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class CourseModel {
  int? id;
  String name;
  String code;
  CourseModel({this.id, required this.name, required this.code});
}

class DepartmentModel {
  int? id;
  String name;
  String code;
  bool isExpanded;
  List<CourseModel> courses;
  TextEditingController courseNameCtrl;
  TextEditingController courseCodeCtrl;

  DepartmentModel({
    this.id,
    required this.name,
    required this.code,
    this.isExpanded = false,
    List<CourseModel>? courses,
  })  : courses = courses ?? [],
        courseNameCtrl = TextEditingController(),
        courseCodeCtrl = TextEditingController();

  void dispose() {
    courseNameCtrl.dispose();
    courseCodeCtrl.dispose();
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────

class AcadSetupPage extends StatefulWidget {
  const AcadSetupPage({super.key});

  @override
  State<AcadSetupPage> createState() => _AcadSetupPageState();
}

class _AcadSetupPageState extends State<AcadSetupPage> {
  final List<DepartmentModel> _departments = [];

  // IMPORTANT: Change this to your computer's IP address if testing on a real phone!
  final String apiUrl = 'http://localhost/libgate_api/academic_api.php';

  bool _isLoading = true;

  final _deptNameCtrl = TextEditingController();
  final _deptCodeCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _searchQuery = '';

  // Convenience getter so every call picks up the current session ID
  String get _adminId => AdminSession.id;

  int get _totalCourses =>
      _departments.fold(0, (sum, d) => sum + d.courses.length);

  List<DepartmentModel> get _filtered {
    if (_searchQuery.isEmpty) return _departments;
    final q = _searchQuery.toLowerCase();
    return _departments.where((d) {
      if (d.name.toLowerCase().contains(q) ||
          d.code.toLowerCase().contains(q)) {
        return true;
      }
      return d.courses.any(
          (c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ─── API CALLS ──────────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?action=fetch&admin_id=$_adminId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _departments.clear();
          for (var d in data['data']) {
            List<CourseModel> coursesList = [];
            if (d['courses'] != null) {
              for (var c in d['courses']) {
                coursesList.add(CourseModel(
                  id: int.parse(c['id'].toString()),
                  name: c['name'],
                  code: c['code'],
                ));
              }
            }
            _departments.add(DepartmentModel(
              id: int.parse(d['id'].toString()),
              name: d['name'],
              code: d['code'],
              courses: coursesList,
            ));
          }
        }
      }
    } catch (e) {
      _showSnack('Error loading data from database');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDepartment() async {
    final name = _deptNameCtrl.text.trim();
    final code = _deptCodeCtrl.text.trim();
    if (name.isEmpty || code.isEmpty) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'add_dept',
        'name': name,
        'code': code,
        'admin_id': _adminId,
      });
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _departments.add(DepartmentModel(id: data['id'], name: name, code: code));
          _deptNameCtrl.clear();
          _deptCodeCtrl.clear();
        });
        _showSnack('Department "$code" added successfully.');
      } else {
        _showSnack('Failed to save to database.');
      }
    } catch (e) {
      _showSnack('Network Error: Could not connect to server.');
    }
  }

  Future<void> _deleteDepartment(DepartmentModel dept) async {
    if (dept.id == null) return;
    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'delete_dept',
        'id': dept.id.toString(),
        'admin_id': _adminId,
      });
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() => _departments.remove(dept));
        dept.dispose();
        _showSnack('Department "${dept.code}" removed.');
      }
    } catch (e) {
      _showSnack('Failed to delete.');
    }
  }

  Future<void> _addCourse(DepartmentModel dept) async {
    final name = dept.courseNameCtrl.text.trim();
    final code = dept.courseCodeCtrl.text.trim();
    if (name.isEmpty || code.isEmpty || dept.id == null) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'add_course',
        'department_id': dept.id.toString(),
        'name': name,
        'code': code,
        'admin_id': _adminId,
      });
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          dept.courses.add(CourseModel(id: data['id'], name: name, code: code));
          dept.courseNameCtrl.clear();
          dept.courseCodeCtrl.clear();
        });
        _showSnack('Course "$code" added under ${dept.code}.');
      }
    } catch (e) {
      _showSnack('Failed to add course.');
    }
  }

  Future<void> _deleteCourse(DepartmentModel dept, CourseModel course) async {
    if (course.id == null) return;
    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'action': 'delete_course',
        'id': course.id.toString(),
        'admin_id': _adminId,
      });
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() => dept.courses.remove(course));
      }
    } catch (e) {
      _showSnack('Failed to delete course.');
    }
  }

  void _editDepartment(DepartmentModel dept) {
    final nameCtrl = TextEditingController(text: dept.name);
    final codeCtrl = TextEditingController(text: dept.code);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Department Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Department Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            onPressed: () async {
              try {
                final response = await http.post(Uri.parse(apiUrl), body: {
                  'action': 'edit_dept',
                  'id': dept.id.toString(),
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'admin_id': _adminId,
                });
                final data = jsonDecode(response.body);
                if (data['status'] == 'success') {
                  setState(() {
                    dept.name = nameCtrl.text.trim();
                    dept.code = codeCtrl.text.trim();
                  });
                  _showSnack('Department updated.');
                }
              } catch (e) {
                _showSnack('Failed to update.');
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _deptNameCtrl.dispose();
    _deptCodeCtrl.dispose();
    _searchCtrl.dispose();
    for (final d in _departments) {
      d.dispose();
    }
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

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
                // HEADER
                Container(
                  width: double.infinity,
                  color: const Color(0xFFD6D6D6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: const Text(
                    'Academic Setup',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),

                // BODY
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Department Directory ──────────────────
                              Expanded(
                                flex: 3,
                                child: _DepartmentDirectory(
                                  departments: _filtered,
                                  totalDepts: _departments.length,
                                  totalCourses: _totalCourses,
                                  searchCtrl: _searchCtrl,
                                  onSearch: (v) =>
                                      setState(() => _searchQuery = v),
                                  onDelete: _deleteDepartment,
                                  onEdit: _editDepartment,
                                  onAddCourse: _addCourse,
                                  onDeleteCourse: _deleteCourse,
                                  onToggle: (dept) => setState(
                                      () => dept.isExpanded = !dept.isExpanded),
                                ),
                              ),

                              const SizedBox(width: 20),

                              // ── RIGHT: Info + Create Form ───────────────────
                              SizedBox(
                                width: 260,
                                child: Column(
                                  children: [
                                    _HowItWorksCard(),
                                    const SizedBox(height: 16),
                                    _CreateDepartmentCard(
                                      nameCtrl: _deptNameCtrl,
                                      codeCtrl: _deptCodeCtrl,
                                      onSave: _saveDepartment,
                                    ),
                                    const SizedBox(height: 16),
                                    _AddingCourseCard(),
                                  ],
                                ),
                              ),
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
}

// ─── Department Directory Card ────────────────────────────────────────────────

class _DepartmentDirectory extends StatelessWidget {
  final List<DepartmentModel> departments;
  final int totalDepts;
  final int totalCourses;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final void Function(DepartmentModel) onDelete;
  final void Function(DepartmentModel) onEdit;
  final void Function(DepartmentModel) onAddCourse;
  final void Function(DepartmentModel, CourseModel) onDeleteCourse;
  final void Function(DepartmentModel) onToggle;

  const _DepartmentDirectory({
    required this.departments,
    required this.totalDepts,
    required this.totalCourses,
    required this.searchCtrl,
    required this.onSearch,
    required this.onDelete,
    required this.onEdit,
    required this.onAddCourse,
    required this.onDeleteCourse,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Department Directory',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937))),
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search dept. or course',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Departments',
                value: totalDepts,
                color: const Color(0xFFE3F2FD),
                textColor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Courses',
                value: totalCourses,
                color: const Color(0xFFE8F5E9),
                textColor: const Color(0xFF2E7D32),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Department list
          if (departments.isEmpty)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.school_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No departments yet.',
                      style: TextStyle(color: Colors.grey.shade500)),
                  Text('Add one using the form on the right.',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: departments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DepartmentTile(
                dept: departments[i],
                onDelete: onDelete,
                onEdit: onEdit,
                onAddCourse: onAddCourse,
                onDeleteCourse: onDeleteCourse,
                onToggle: onToggle,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Department Tile ──────────────────────────────────────────────────────────

class _DepartmentTile extends StatelessWidget {
  final DepartmentModel dept;
  final void Function(DepartmentModel) onDelete;
  final void Function(DepartmentModel) onEdit;
  final void Function(DepartmentModel) onAddCourse;
  final void Function(DepartmentModel, CourseModel) onDeleteCourse;
  final void Function(DepartmentModel) onToggle;

  const _DepartmentTile({
    required this.dept,
    required this.onDelete,
    required this.onEdit,
    required this.onAddCourse,
    required this.onDeleteCourse,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Department header row
          InkWell(
            onTap: () => onToggle(dept),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Code badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dept.code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dept.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Course count chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dept.courses.length} courses',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF1565C0),
                    onTap: () => onEdit(dept),
                  ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: () => onDelete(dept),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    dept.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded courses list + add row
          if (dept.isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8)),
              ),
              child: Column(
                children: [
                  if (dept.courses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No courses yet. Add one below.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  else
                    ...dept.courses.map((c) => _CourseTile(
                          course: c,
                          onDelete: () => onDeleteCourse(dept, c),
                        )),

                  // Add course row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _SmallField(
                            ctrl: dept.courseNameCtrl,
                            hint: 'New Course name under ${dept.code}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SmallField(
                            ctrl: dept.courseCodeCtrl,
                            hint: 'Code',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => onAddCourse(dept),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Course',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Course Tile ──────────────────────────────────────────────────────────────

class _CourseTile extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onDelete;

  const _CourseTile({required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: Color(0xFF1565C0), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(course.code,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
          ),
          Expanded(
            child: Text(course.name,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ),
          _IconBtn(
            icon: Icons.close,
            color: Colors.red,
            size: 16,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── How It Works Card ────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How this works',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('A simpler way to organize academic data.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          _HowStep(
              num: '1',
              label: 'Create a department',
              color: const Color(0xFF1565C0)),
          const SizedBox(height: 8),
          _HowStep(
              num: '2',
              label: 'Add course inside the department',
              color: const Color(0xFF1565C0)),
          const SizedBox(height: 8),
          _HowStep(
              num: '3',
              label: 'Edit or remove anytime',
              color: const Color(0xFF1565C0)),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String num;
  final String label;
  final Color color;

  const _HowStep(
      {required this.num, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
            radius: 10,
            backgroundColor: color.withOpacity(0.15),
            child: Text(num,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
      ],
    );
  }
}

// ─── Create Department Card ───────────────────────────────────────────────────

class _CreateDepartmentCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final VoidCallback onSave;

  const _CreateDepartmentCard({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Department',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          _FormLabel('Department Name'),
          const SizedBox(height: 4),
          _FormField(ctrl: nameCtrl, hint: 'e.g. College of Nursing'),
          const SizedBox(height: 10),
          _FormLabel('Department Code'),
          const SizedBox(height: 4),
          _FormField(ctrl: codeCtrl, hint: 'e.g. CON'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save Department'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Adding a Course Info Card ────────────────────────────────────────────────

class _AddingCourseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adding a Course',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          _InfoStep(
              icon: Icons.touch_app_outlined,
              text: 'Open the department card where the course belongs.'),
          const SizedBox(height: 10),
          _InfoStep(
              icon: Icons.edit_outlined,
              text:
                  'Type the course name and code in the add row at the bottom.'),
          const SizedBox(height: 10),
          _InfoStep(
              icon: Icons.check_circle_outline,
              text:
                  'Click Add Course to save it under the selected department.'),
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
      ],
    );
  }
}

// ─── Reusable Small Widgets ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color textColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 2),
          Text('$value',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _SmallField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)));
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _FormField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}