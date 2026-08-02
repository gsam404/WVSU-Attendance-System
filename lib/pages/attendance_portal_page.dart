import 'package:flutter/material.dart';
import '../widgets/portal_card.dart';
import 'admin_login_page.dart';
import 'student_check_in_page.dart';

class AttendancePortal extends StatelessWidget {
  const AttendancePortal({super.key});

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/wvsu_logo.png', width: 130),
                const SizedBox(height: 30),
                const Text(
                  'WVSU Library Attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PortalCard(
                      icon: Icons.person,
                      title: 'Student Portal',
                      subtitle: 'Display student info for sign in and sign out',
                      buttonText: 'Go to student check-in →',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentCheckInPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 50),
                    PortalCard(
                      icon: Icons.shield,
                      title: 'Admin Portal',
                      subtitle: 'Access administrative tools and analytics',
                      buttonText: 'Login as Admin →',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLoginPage(),
                          ),
                        );
                      },
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
