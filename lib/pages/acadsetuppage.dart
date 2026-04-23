import 'package:flutter/material.dart';
import 'package:wvsu_attendance_system/pages/sidebar.dart';

class AcadSetupPage extends StatelessWidget {
  const AcadSetupPage({super.key});

  void acads() {
    Text('Academic Setup Page');
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
          children: [
            SideBar(selectedIndex: 4),
          ],
        ),
    );
  }
}