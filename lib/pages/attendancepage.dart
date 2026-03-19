import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Index 2 is for Attendance in your sidebar list
          const SideBar(selectedIndex: 2), 
          
          // This Expanded widget fills the rest of the screen next to the sidebar
          const Expanded(
            child: Center(
              child: Text(
                'Attendance Content Goes Here',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}