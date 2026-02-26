import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  void attendance() {
    Text('Attendance Page');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideBar(selectedIndex: 2),
        ]
      ),
    );
  }
}