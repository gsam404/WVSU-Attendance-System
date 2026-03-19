import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> scanStudentID(String scannedId) async {
  final String apiUrl = kIsWeb
      ? 'http://192.168.1.45/libgate_api/scan.php'
      : Platform.isAndroid
          ? 'http://10.0.2.2/libgate_api/scan.php'
          : 'http://192.168.1.45/libgate_api/scan.php';

  print("Sending scanned ID: $scannedId to $apiUrl");

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'scanned_id': scannedId.trim()}, // form POST
    ).timeout(const Duration(seconds: 5));

    print("HTTP Status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        print("Student found: ${data['student_id']} - ${data['full_name']}");
        return data;
      } else {
        print("API Error: ${data['message']}");
        return null;
      }
    }
  } catch (e) {
    print("Connection Error: $e");
  }
  return null;
}