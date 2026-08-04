import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/api_service.dart';
import 'pages/attendance_portal_page.dart';

void main() {
  runApp(const MyApp());
}

// fixed transition

class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

// CUSTOM PAGE TRANSITIONS BUILDER
class NoTransitionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
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
        // FIX: Removes janky slide animation on ALL page transitions (web-safe)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionPageTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionPageTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionPageTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionPageTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionPageTransitionsBuilder(),
          },
        ),
      ),
      // Initial page is the Student-Admin Portal (imported from pages/attendance_portal_page.dart)
      // NOTE: AttendancePortal is defined in pages/attendance_portal_page.dart.
      // Do NOT redefine a class named AttendancePortal in this file — it will
      // collide with the imported one and fail to compile.
      home: const AttendancePortal(),
    );
  } // Widget build
} // ------------------------------- End of MyApp

/* ---------------------------------------------------------
      MAIN ATTENDANCE PORTAL PAGE (SELECTION SCREEN)
------------------------------------------------------------*/
// REMOVED: The AttendancePortal widget used to be defined here, but it is
// now imported from pages/attendance_portal_page.dart (see import above).
// Keeping both would cause: "The name 'AttendancePortal' is already defined."
// If your pages/attendance_portal_page.dart file does NOT actually contain
// an AttendancePortal class yet, let me know and I'll move this widget's
// code back into that file for you.

/* ---------------------------------------------------------
            Student Check-In Page (Scanner Page)
------------------------------------------------------------*/
class StudentCheckInPage extends StatefulWidget {
  const StudentCheckInPage({super.key});

  @override
  State<StudentCheckInPage> createState() => _StudentCheckInPageState();
}

class _StudentCheckInPageState extends State<StudentCheckInPage> {
  // FocusNode and Controller to manage the "hidden" scanner input
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  // ADDED: Create the audio player for the scanner
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // ADDED: Request focus automatically when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  // Handles the barcode data
  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.trim().isEmpty) return;

    // RECHECK: This is where we check if the library is closed before we even call the API.
    // If it's closed, we show a message and stop execution here.
    // --- TIME CHECK IN THE SCANNER ---
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
      return; // Stops here and doesn't call the API if library is closed
    } // ---------

    try {
      var studentData = await ApiService().scanStudentID(barcode.trim());

      if (studentData != null &&
          studentData['status'] == 'success' &&
          mounted) {
        // --- ADDED: PLAY SUCCESS SOUND ---
        await _audioPlayer.play(AssetSource('audio/inout.wav'));

        Navigator.push(
          context,
          NoTransitionRoute(
            builder: (context) => StudentDisplaySignInPage(
              studentId: studentData['student_id']?.toString() ?? "N/A",
              studentName: studentData['full_name']?.toString() ?? "Unknown",
              program: studentData['program']?.toString() ?? "N/A",
              action: studentData['action']?.toString() ?? "In", // Added
              message: studentData['message']?.toString() ?? "", // Added
            ),
          ),
        );
      } else {
        // --- CONDITION: NO STUDENT ID PRESENT IN DATABASE ---
        // This happens when PHP returns "status": "error"
        if (mounted) {
          // --- ADDED: PLAY ERROR SOUND ---
          await _audioPlayer.play(AssetSource('audio/wrong.wav'));

          Navigator.push(
            context,
            NoTransitionRoute(
              builder: (context) => const StudentErrorPage(
                errorMessage: "Your student ID is not available. Try again.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      // --- CONDITION: NOT CONNECTED TO DATABASE / WIFI ISSUES ---
      // This happens if the server IP is wrong, MySQL is off, or Wifi is down
      if (mounted) {
        // --- ADDED: PLAY ERROR SOUND FOR NETWORK ---
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
      // FEAT: If the user clicks anywhere, refocus the scanner
      onTap: () => _barcodeFocusNode.requestFocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // 6. ADDED: The "Invisible" Listener
            Positioned(
              top: -50, // Hide it off-screen
              child: SizedBox(
                width: 1,
                child: TextField(
                  focusNode: _barcodeFocusNode,
                  controller: _barcodeController,
                  autofocus: true,
                  onSubmitted:
                      _handleBarcodeScan, // Triggered by scanner's "Enter"
                ),
              ),
            ),

            /* _________________________________________________________________________________________
        Student Check-In UI (Visible to users, but scanner input is hidden and auto-focused)
_____________________________________________________________________________________________*/
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
                              // Main instruction text
                              "Scan Your ID Barcode to Enter",
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              // Sub-instruction text
                              "Place your ID barcode under the scanner\nEnsure your card is active and not expired.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 60),
                            const Text(
                                // Manual input prompt
                                "No ID? Please enter your details manually below.",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                NoTransitionRoute(
                                    builder: (context) =>
                                        const ManualInputPage()),
                              ), // Navigate to ManualInputPage when button is pressed
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
                              ), // Style: Button to navigate to Manual Input Page
                              child: const Text("Manual Input",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ], // Children of the inner Column (the card content
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
                  ], // Children of the outer Column (the whole page content
                ),
              ),
            ),
          ], // Children of the Stack (the invisible scanner input and the visible UI)
        ),
      ),
    );
  } // Widget build
} // End of StudentCheckInPage ------------------------------------------

// FEAT: Check if library is closed based on current time (6 PM to 7 AM)
// commented out the actual time check for testing purposes, but this is where you would implement it.
// Adjust the hours as needed based on the library's actual operating hours.
bool isLibraryClosed() {
  final now = DateTime.now();
  // Returns true if it's 6 PM (18) or later, OR before 7 AM
  // Temporarily disabled for testing purposes. Uncomment the line below to enable time-based access control.
  return now.hour >= 18 || now.hour < 7;
  // (not sure what is the exact time range for the library, adjust as needed)
  // return false; // For testing purposes, always allow access
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
                                    // --- TIME CHECK ADDED HERE ---
                                    if (isLibraryClosed()) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'The library is closed. Operating hours are 6:00 AM to 6:00 PM.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return; // Stop execution so _isLoading never becomes true
                                    }
                                    // -----------------------------

                                    setState(() => _isLoading = true);

                                    // --- Manual Input Logic ---
                                    try {
                                      var studentData = await ApiService()
                                          .scanStudentID(enteredId);

                                      if (!mounted) return;
                                      setState(() => _isLoading = false);

                                      if (studentData != null &&
                                          studentData['status'] == 'success') {
                                        // --- ADDED: PLAY SUCCESS SOUND ---
                                        await _audioPlayer.play(
                                            AssetSource('audio/inout.wav'));

                                        Navigator.pushReplacement(
                                          context,
                                          NoTransitionRoute(
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
                                        ); // Navigate to StudentDisplaySignInPage on successful manual input
                                        _idController.clear();
                                      } else {
                                        if (mounted) {
                                          // --- ADDED: PLAY ERROR SOUND ---
                                          await _audioPlayer.play(
                                              AssetSource('audio/wrong.wav'));

                                          Navigator.pushReplacement(
                                            context,
                                            NoTransitionRoute(
                                              builder: (context) =>
                                                  const StudentErrorPage(
                                                errorMessage:
                                                    "Your student id is not available. Try again.",
                                              ),
                                            ),
                                          ); // Navigate to StudentErrorPage if manual input ID is not found in database
                                        }
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() => _isLoading = false);

                                      // --- ADDED: PLAY ERROR SOUND FOR NETWORK ---
                                      await _audioPlayer
                                          .play(AssetSource('audio/wrong.wav'));

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
  } // Widget build
} // End of ManualInputPage ------------------------------------------

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

// Timer logic is implemented here to automatically return to the scanner page after a couple seconds.
// The current time is also calculated and displayed on this page based on the time of the sign-in or sign-out action.
// The UI changes dynamically based on whether the student is logging in or out, showing different icons, messages, and status text accordingly.
class _StudentDisplaySignInPageState extends State<StudentDisplaySignInPage> {
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
    // --- FIXED TIME LOGIC HERE ---
    final now = DateTime.now();
    final hour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? "PM" : "AM";
    String currentTime = "$hour:$minute $period";
    // -----------------------------

    bool isLoggingIn = widget.action == "In";

    // Design the UI to show student info and whether they are logging in or out, along with the time of the action.
    // After a couple seconds, it will automatically return to the scanner page.
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
                // Icon changes based on action
                Icon(isLoggingIn ? Icons.verified : Icons.exit_to_app,
                    color: isLoggingIn ? Colors.lightBlue : Colors.orange,
                    size: 80),
                const SizedBox(height: 20),
                // Text changes based on action
                Text(
                    isLoggingIn
                        ? "Welcome to the Library" // logging in message
                        : "Goodbye! See you soon", // logging out message
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
                    // Status text changes based on action
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
  } // Widget build
} // End of StudentDisplaySignInPage -------------------------------------

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Auto close after 2 seconds
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

              // OUTER CARD
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
                      // RED WARNING TRIANGLE
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 90,
                      ),
                      const SizedBox(height: 20),

                      // TITLE (fixed text to match design)
                      const Text(
                        "Card Not Available",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // SUBTEXT
                      const Text(
                        "Your ID card could not be scanned.\n"
                        "Please try scanning again or enter your User ID\n"
                        "manually to proceed.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
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