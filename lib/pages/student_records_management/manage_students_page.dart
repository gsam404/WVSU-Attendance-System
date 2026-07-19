import 'package:flutter/material.dart';
import '../../models/student.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  static const int pageSize = 15;

  final TextEditingController searchController = TextEditingController();

  final ScrollController horizontalController = ScrollController();

  Student? selectedStudent;

  String searchQuery = "";

  int currentPage = 0;

  late List<Student> students;

  @override
  void initState() {
    super.initState();

    students = List.generate(
      35,
      (index) => Student(
        studentId: "2024-${1000 + index}",
        firstName: "First$index",
        lastName: "Last$index",
        middleName: "",
        program: index % 2 == 0 ? "BSCS" : "BSIT",
        year: "${(index % 4) + 1}",
        section: "A",
        birthDate: "January 1, 2000",
        birthPlace: "Iloilo",
        gender: index % 2 == 0 ? "Male" : "Female",
        email: "student$index@email.com",
      ),
    );

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
        currentPage = 0;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    horizontalController.dispose();
    super.dispose();
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
            const Text(
              "Students",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text("Add Student"),
                ),
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
              child: Center(
                child: Text(
                  "Student table goes here",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
