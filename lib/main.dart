
import 'package:flutter/material.dart';
import './pages/sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', //Universal Font

        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 20.0,
          ),
        ),
      ),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
          children: [
            SideBar(selectedIndex: 0),
          ],
        ),
    );
  }

}

