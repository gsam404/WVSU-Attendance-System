import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/attendance_flow_service.dart';
import 'student_error_page.dart';
import 'student_result_page.dart';

class ManualInputPage extends StatefulWidget {
  const ManualInputPage({super.key});

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  final TextEditingController _idController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AttendanceFlowService _attendanceFlowService = AttendanceFlowService();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _audioPlayer.dispose();
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
                        const Text(
                          'Enter Your Student ID',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: 500,
                          child: TextField(
                            controller: _idController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'Enter Student ID (e.g., 2023M0523)',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 30),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final enteredId = _idController.text.trim();

                                  if (enteredId.isEmpty) {
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  final result = await _attendanceFlowService
                                      .submitStudentId(enteredId);

                                  if (!mounted) return;
                                  setState(() => _isLoading = false);

                                  if (result.isClosed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.message ??
                                              _attendanceFlowService
                                                  .getLibraryClosedMessage(),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }

                                  if (result.isSuccess && result.data != null) {
                                    await _audioPlayer
                                        .play(AssetSource('audio/inout.wav'));

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentDisplaySignInPage(
                                          studentId: result.data!['student_id']
                                                  ?.toString() ??
                                              'N/A',
                                          studentName: result.data!['full_name']
                                                  ?.toString() ??
                                              'Unknown',
                                          program: result.data!['program']
                                                  ?.toString() ??
                                              'N/A',
                                          action: result.data!['action']
                                                  ?.toString() ??
                                              'In',
                                          message: result.data!['message']
                                                  ?.toString() ??
                                              '',
                                        ),
                                      ),
                                    );
                                    _idController.clear();
                                  } else {
                                    await _audioPlayer
                                        .play(AssetSource('audio/wrong.wav'));

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentErrorPage(
                                          title: result.title ??
                                              'Card Not Available',
                                          errorMessage: result.message ??
                                              'Your student ID is not available. Try again.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 51, 133, 210),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 60, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 50),
                        const Text(
                          'Need help? Reach out to the service desk.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Back to Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
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
