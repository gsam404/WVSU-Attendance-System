import 'package:flutter/material.dart';

class StudentDisplaySignInPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String program;
  final String action;
  final String message;

  const StudentDisplaySignInPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.program,
    required this.action,
    required this.message,
  });

  @override
  State<StudentDisplaySignInPage> createState() =>
      _StudentDisplaySignInPageState();
}

class _StudentDisplaySignInPageState extends State<StudentDisplaySignInPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final currentTime = '$hour:$minute $period';
    final isLoggingIn = widget.action == 'In';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/blue_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLoggingIn ? Icons.verified : Icons.exit_to_app,
                  color: isLoggingIn ? Colors.lightBlue : Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  isLoggingIn
                      ? 'Welcome to the Library'
                      : 'Goodbye! See you soon',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.message,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE2F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.studentId,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.studentName,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.program,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      isLoggingIn
                          ? 'Logged in at $currentTime'
                          : 'Logged out at $currentTime',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
