import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'pages/adminLoginPage.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // <--- ADDED: Audio package import

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
      title: 'WVSU Library Attendance',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // Set the initial page to the AttendancePortal (the choice screen)
      home: const AttendancePortal(),
    );
  }
} 

/* ---------------------------------------------------------
      MAIN ATTENDANCE PORTAL PAGE (SELECTION SCREEN)
------------------------------------------------------------*/
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
                    _buildPortalCard(
                      context: context,
                      icon: Icons.person,
                      title: "Student Portal",
                      subtitle: "Display student info for sign in and sign out",
                      buttonText: "Go to student check-in →",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StudentCheckInPage()),
                        );
                      },
                    ),
                    const SizedBox(width: 50),
                    _buildPortalCard(
                      context: context,
                      icon: Icons.shield,
                      title: "Admin Portal",
                      subtitle: "Access administrative tools and analytics",
                      buttonText: "Login as Admin →",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminLoginPage()),
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

/* ---------------------------------------------------------
   HELPER METHOD TO BUILD THE PORTAL CARDS (STUDENT AND ADMIN)
------------------------------------------------------------*/
  static Widget _buildPortalCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 25, offset: Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: const Color(0xFF1A237E)),
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 133, 210),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------------------------------------
            Student Check-In Page (Scanner Page)
------------------------------------------------------------*/
class StudentCheckInPage extends StatefulWidget {
  const StudentCheckInPage({super.key});

  @override
  State<StudentCheckInPage> createState() => _StudentCheckInPageState();
}

class _StudentCheckInPageState extends State<StudentCheckInPage> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  
  // ADDED: Create the audio player for the scanner
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  // Handles the barcode data
  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.trim().isEmpty) return;

    if (isLibraryClosed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'The library is closed. Operating hours are 6:00 AM to 6:00 PM.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
      return; 
    }

    try {
      var studentData = await ApiService().scanStudentID(barcode.trim());

      if (studentData != null &&
          studentData['status'] == 'success' &&
          mounted) {
            
        // --- ADDED: PLAY SUCCESS SOUND ---
        await _audioPlayer.play(AssetSource('audio/inout.wav'));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDisplaySignInPage(
              studentId: studentData['student_id']?.toString() ?? "N/A",
              studentName: studentData['full_name']?.toString() ?? "Unknown",
              program: studentData['program']?.toString() ?? "N/A",
              action: studentData['action']?.toString() ?? "In", 
              message: studentData['message']?.toString() ?? "", 
            ),
          ),
        );
      } else {
        if (mounted) {
          
          // --- ADDED: PLAY ERROR SOUND ---
          await _audioPlayer.play(AssetSource('audio/wrong.wav'));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentErrorPage(
                errorMessage: "Your student ID is not available. Try again.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        
        // --- ADDED: PLAY ERROR SOUND FOR NETWORK ISSUES ---
        await _audioPlayer.play(AssetSource('audio/wrong.wav'));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The system is encountering connectivity issues.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    _audioPlayer.dispose(); // ADDED: Cleanup audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _barcodeFocusNode.requestFocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: -50, 
              child: SizedBox(
                width: 1,
                child: TextField(
                  focusNode: _barcodeFocusNode,
                  controller: _barcodeController,
                  autofocus: true,
                  onSubmitted:
                      _handleBarcodeScan, 
                ),
              ),
            ),
            Container(
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
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6DDF0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Scan Your ID Barcode to Enter",
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              "Place your ID barcode under the scanner\nEnsure your card is active and not expired.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 60),
                            const Text(
                                "No ID? Please enter your details manually below.",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ManualInputPage()),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF438EE4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: Colors.black87, width: 1),
                                ),
                                elevation: 0,
                              ),
                              child: const Text("Manual Input",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text("Back to Portal",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool isLibraryClosed() {
  return false; 
}

/* ---------------------------------------------------------
      Manual Input Page (For students without barcodes)
------------------------------------------------------------*/
class ManualInputPage extends StatefulWidget {
  const ManualInputPage({super.key});

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  final TextEditingController _idController = TextEditingController();
  
  // ADDED: Create the audio player for the manual input screen too
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _audioPlayer.dispose(); // ADDED: Cleanup audio player
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/wvsu_logo.png', width: 130),
                const SizedBox(height: 40),
                Container(
                  width: 900,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E9F2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 50),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFD9E8),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Enter Your Student ID",
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: 500,
                          child: TextField(
                            controller: _idController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: "Enter Student ID (e.g., 2023M0523)",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 30),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  String enteredId = _idController.text.trim();

                                  if (enteredId.isNotEmpty) {
                                    if (isLibraryClosed()) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'The library is closed. Operating hours are 6:00 AM to 6:00 PM.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return; 
                                    }

                                    setState(() => _isLoading = true);

                                    try {
                                      var studentData = await ApiService()
                                          .scanStudentID(enteredId);

                                      if (!mounted) return;
                                      setState(() => _isLoading = false);

                                      if (studentData != null &&
                                          studentData['status'] == 'success') {
                                            
                                        // --- ADDED: PLAY SUCCESS SOUND ---
                                        await _audioPlayer.play(AssetSource('audio/inout.wav'));

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StudentDisplaySignInPage(
                                              studentId:
                                                  studentData['student_id']
                                                          ?.toString() ??
                                                      "N/A",
                                              studentName:
                                                  studentData['full_name']
                                                          ?.toString() ??
                                                      "Unknown",
                                              program: studentData['program']
                                                      ?.toString() ??
                                                  "N/A",
                                              action: studentData['action']
                                                      ?.toString() ??
                                                  "In",
                                              message: studentData['message']
                                                      ?.toString() ??
                                                  "",
                                            ),
                                          ),
                                        ); 
                                        _idController.clear();
                                      } else {
                                        if (mounted) {
                                          
                                          // --- ADDED: PLAY ERROR SOUND ---
                                          await _audioPlayer.play(AssetSource('audio/wrong.wav'));

                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const StudentErrorPage(
                                                errorMessage:
                                                    "Your student id is not available. Try again.",
                                              ),
                                            ),
                                          ); 
                                        }
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() => _isLoading = false);
                                      
                                      // --- ADDED: PLAY ERROR SOUND FOR NETWORK ---
                                      await _audioPlayer.play(AssetSource('audio/wrong.wav'));

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Connection Error: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 51, 133, 210),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 60, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3))
                              : const Text("SUBMIT",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                        const SizedBox(height: 50),
                        const Text("Need help? Reach out to the service desk.",
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text("Back to Scanner",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: TextButton.styleFrom(backgroundColor: Colors.black26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------
      Student Display Sign-In Page (Shows student info after scanning)
---------------------------------------------------------------------*/
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
    final period = now.hour >= 12 ? "PM" : "AM";
    String currentTime = "$hour:$minute $period";

    bool isLoggingIn = widget.action == "In";

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
                Icon(isLoggingIn ? Icons.verified : Icons.exit_to_app,
                    color: isLoggingIn ? Colors.lightBlue : Colors.orange,
                    size: 80),
                const SizedBox(height: 20),
                Text(
                    isLoggingIn
                        ? "Welcome to the Library"
                        : "Goodbye! See you soon",
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(widget.message,
                    style:
                        const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDE2F4),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text(widget.studentId,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.studentName,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text(widget.program,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black54)),
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
                          ? "Logged in at $currentTime"
                          : "Logged out at $currentTime",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54),
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

/* ------------------------------------------------------------------
      Student Error Page (Shows when ID is invalid)
---------------------------------------------------------------------*/
class StudentErrorPage extends StatefulWidget {
  final String errorMessage;

  const StudentErrorPage({
    super.key,
    required this.errorMessage,
  });

  @override
  State<StudentErrorPage> createState() => _StudentErrorPageState();
}

class _StudentErrorPageState extends State<StudentErrorPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
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
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                const Text("Scan Failed",
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(
                  widget.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}