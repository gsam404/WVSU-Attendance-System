import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Index 1 is for Analytics in your sidebar list
          const SideBar(selectedIndex: 1), 
          
          // This Expanded widget fills the rest of the screen next to the sidebar
          const Expanded(
            child: Center(
              child: Text(
                'Analytics Content Goes Here',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}