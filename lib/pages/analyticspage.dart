
import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  void attendance() {
    Text('Attendance Page');
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
          children: [
            SideBar(selectedIndex: 1),
          ],
        ),
    );
  }
}