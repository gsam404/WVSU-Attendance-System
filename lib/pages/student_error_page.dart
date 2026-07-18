import 'dart:async';
import 'package:flutter/material.dart';

class StudentErrorPage extends StatefulWidget {
  final String title;
  final String errorMessage;

  const StudentErrorPage({
    super.key,
    required this.title,
    required this.errorMessage,
  });

  @override
  State<StudentErrorPage> createState() => _StudentErrorPageState();
}

class _StudentErrorPageState extends State<StudentErrorPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/wvsu_logo.png', width: 130),
              const SizedBox(height: 30),
              Container(
                width: 950,
                height: 500,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F8),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DDF0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: Colors.red, size: 90),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.errorMessage.isNotEmpty
                            ? widget.errorMessage
                            : 'Your ID card could not be scanned.\nPlease try scanning again or enter your User ID\nmanually to proceed.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
