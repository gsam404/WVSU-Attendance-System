import 'package:flutter/material.dart';
import 'pages/attendance_portal_page.dart';

void main() {
  runApp(const MyApp());
}

/* ---------------------------------------------------------
                            MyApp 
------------------------------------------------------------*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WVSU  Library Attendance',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // Initial page to the Student-Admin Portal
      home: const AttendancePortal(),
    );
  } // Widget build
} // ------------------------------- End of MyApp