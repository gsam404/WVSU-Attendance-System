import 'api_service.dart';

class AttendanceFlowResult {
  final bool isSuccess;
  final bool isClosed;
  final String? title;
  final String? message;
  final Map<String, dynamic>? data;
  final Object? error;

  const AttendanceFlowResult({
    required this.isSuccess,
    this.isClosed = false,
    this.title,
    this.message,
    this.data,
    this.error,
  });
}

class AttendanceFlowService {
  static const int openingHour = 7;
  static const int closingHour = 18;

  final ApiService _apiService = ApiService();

  bool isLibraryClosed() {
    final now = DateTime.now();
    return now.hour >= closingHour || now.hour < openingHour;
  }

  String getLibraryClosedMessage() {
    return 'The library is closed. Operating hours are ${openingHour.toString().padLeft(2, '0')}:00 AM to ${closingHour.toString().padLeft(2, '0')}:00 PM.';
  }

  Future<AttendanceFlowResult> submitStudentId(String inputId) async {
    final normalizedId = inputId.trim();

    // 1) Validate input first (empty / length) before checking library hours.
    if (normalizedId.isEmpty) {
      return const AttendanceFlowResult(
        isSuccess: false,
        title: 'Invalid Input',
        message: 'Please enter a student ID.',
      );
    }

    // Require student ID to be 9 characters (adjust if your IDs differ)
    if (normalizedId.length != 9) {
      return const AttendanceFlowResult(
        isSuccess: false,
        title: 'Invalid ID',
        message: 'The Student ID must be 9 characters. Please check and try again.',
      );
    }

    // 2) Library hours check after validation
    if (isLibraryClosed()) {
      return AttendanceFlowResult(
        isSuccess: false,
        isClosed: true,
        title: 'Library Closed',
        message: getLibraryClosedMessage(),
      );
    }

    try {
      final studentData = await _apiService.scanStudentID(normalizedId);

      if (studentData != null && studentData['status'] == 'success') {
        return AttendanceFlowResult(
          isSuccess: true,
          data: studentData,
        );
      }

      // If server returned JSON with a message, surface it.
      if (studentData != null && studentData['message'] != null) {
        return AttendanceFlowResult(
          isSuccess: false,
          title: studentData['title'] ?? 'Card Not Available',
          message: studentData['message'].toString(),
          data: studentData,
        );
      }

      return const AttendanceFlowResult(
        isSuccess: false,
        title: 'Card Not Available',
        message:
            'Your card is not available. Please try scanning again or enter your User ID manually to proceed.',
      );
    } catch (e) {
      return const AttendanceFlowResult(
        isSuccess: false,
        title: 'Connection Problem',
        message:
            'Your card could not be scanned because of network issues. Please try again later.',
      );
    }
  }
}
