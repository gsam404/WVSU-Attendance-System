import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/attendance_flow_service.dart';
import 'manual_input_page.dart';
import 'student_error_page.dart';
import 'student_result_page.dart';

class StudentCheckInPage extends StatefulWidget {
  const StudentCheckInPage({super.key});

  @override
  State<StudentCheckInPage> createState() => _StudentCheckInPageState();
}

class _StudentCheckInPageState extends State<StudentCheckInPage> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AttendanceFlowService _attendanceFlowService = AttendanceFlowService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.trim().isEmpty) return;

    final result = await _attendanceFlowService.submitStudentId(barcode);

    if (!mounted) return;

    if (result.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? _attendanceFlowService.getLibraryClosedMessage(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (result.isSuccess && result.data != null) {
      await _audioPlayer.play(AssetSource('audio/inout.wav'));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDisplaySignInPage(
            studentId: result.data!['student_id']?.toString() ?? 'N/A',
            studentName: result.data!['full_name']?.toString() ?? 'Unknown',
            program: result.data!['program']?.toString() ?? 'N/A',
            action: result.data!['action']?.toString() ?? 'In',
            message: result.data!['message']?.toString() ?? '',
          ),
        ),
      );
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.wav'));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentErrorPage(
            title: result.title ?? 'Card Not Available',
            errorMessage: result.message ??
                'Your student ID is not available. Try again.',
          ),
        ),
      );
    }

    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    _audioPlayer.dispose();
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
                  onSubmitted: _handleBarcodeScan,
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
                              'Scan Your ID Barcode to Enter',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              'Place your ID barcode under the scanner\nEnsure your card is active and not expired.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 60),
                            const Text(
                              'No ID? Please enter your details manually below.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManualInputPage(),
                                ),
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
                              child: const Text(
                                'Manual Input',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text(
                        'Back to Portal',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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
