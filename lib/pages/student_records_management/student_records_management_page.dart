import 'package:flutter/material.dart';

import '../sidebar.dart';
import 'import_page.dart';
import 'manage_students_page.dart';

/// The shared Student Records shell. Each tab has its own page widget so the
/// import and student-management features can grow independently.
class StudentRecordsManagementPage extends StatefulWidget {
  const StudentRecordsManagementPage({super.key});

  @override
  State<StudentRecordsManagementPage> createState() =>
      _StudentRecordsManagementPageState();
}

class _StudentRecordsManagementPageState
    extends State<StudentRecordsManagementPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFE5E5E5),
        body: Row(
          children: [
            const SideBar(selectedIndex: 4),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    color: Colors.white,
                    child: const Text(
                      'Student Records Management',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                    child: _buildTabBar(),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: const [ImportPage(), ManageStudentsPage()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() => Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF6C91C2)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            _buildTab(label: 'Import Students', index: 0),
            _buildTab(label: 'Manage Students', index: 1),
          ],
        ),
      );

  Widget _buildTab({required String label, required int index}) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          color: selected ? const Color(0xFF3977C8) : Colors.white,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
