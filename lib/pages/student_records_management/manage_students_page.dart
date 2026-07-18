import 'package:flutter/material.dart';

class ManageStudentsPage extends StatelessWidget {
  const ManageStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Students',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'View, search, and edit student records once import is complete.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 30),
            _ManageStudentsEmptyState(),
          ],
        ),
      ),
    );
  }
}

class _ManageStudentsEmptyState extends StatelessWidget {
  const _ManageStudentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Student management will be available here after import.',
        style: TextStyle(color: Color(0xFF4B5563)),
      ),
    );
  }
}
