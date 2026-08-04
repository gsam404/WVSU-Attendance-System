import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Use your local IP address for physical devices/Web
  // Use 10.0.2.2 for Android Emulator (the emulator maps this to your host machine's localhost)
  final String baseUrl = kIsWeb
      ? 'http://192.168.1.72/libgate_api'
      : Platform.isAndroid
          ? 'http://192.168.1.72/libgate_api' // change to 'http://10.0.2.2/libgate_api' if testing on an emulator
          : 'http://192.168.1.72/libgate_api';

  // --- 1. SCAN STUDENT ID (For the Scanner/Entry Gate) ---
  Future<Map<String, dynamic>?> scanStudentID(String scannedId) async {
    final String apiUrl = '$baseUrl/scan.php';

    print("Sending scanned ID: $scannedId to $apiUrl");

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'scanned_id': scannedId.trim()
      }).timeout(const Duration(seconds: 5));

      print("HTTP Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Always return decoded JSON when the server responds 200.
        // The caller can inspect `status` and use `message` to inform the user.
        if (data is Map<String, dynamic>) {
          if (data['status'] == 'success') {
            print(
                "Student found: ${data['student_id']} - ${data['full_name']}");
          } else {
            print("API Error: ${data['message']}");
          }
          return data;
        }
      }
    } catch (e) {
      print("Connection Error (Scan): $e");
    }
    return null;
  }

  // --- 2. RAW POST helper ---
  Future<Map<String, dynamic>?> rawPost(
    String url,
    Map<String, String> body,
  ) async {
    try {
      final response = await http
          .post(Uri.parse(url), body: body)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Connection Error (rawPost): $e");
    }
    return null;
  }

  // --- 3. GET DASHBOARD STATS (For the Dashboard Cards & Pie Chart) ---
  Future<Map<String, dynamic>?> getDashboardStats() async {
    final String apiUrl = '$baseUrl/get_dashboard_stats.php';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Dashboard stats fetched successfully");
        return data;
      } else {
        print("Server Error (Stats): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Connection Error (Stats): $e");
      return null;
    }
  }

  // --- 4. GET ATTENDANCE LOGS (For the Attendance Table) ---
  Future<List<dynamic>> getAttendanceLogs() async {
    final String apiUrl = '$baseUrl/get_attendance.php';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching attendance: $e");
    }
    return [];
  }

  // --- 5. GET ANALYTICS (For the Analytics Page) ---
  Future<Map<String, dynamic>?> getAnalytics() async {
    final String apiUrl = '$baseUrl/get_analytics.php';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Analytics API: $data");
        return data;
      } else {
        print("Server Error (Analytics): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Connection Error (Analytics): $e");
      return null;
    }
  }

  // --- 6. GET PROFILE (For the Sidebar user info) ---
  Future<Map<String, dynamic>?> getProfile() async {
    final String apiUrl = '$baseUrl/get_profile.php';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Profile fetched: $data");
        return data;
      } else {
        print("Server Error (Profile): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Connection Error (Profile): $e");
      return null;
    }
  }
}