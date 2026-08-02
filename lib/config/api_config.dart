class ApiConfig {
  static const String baseUrl = "http://localhost/libgate_api";

  static const String upload = "$baseUrl/upload.php";
  static const String academic = "$baseUrl/academic_api.php";
  static const String manageAdmins = "$baseUrl/manage_admins.php";
  static const String adminLogin = "$baseUrl/admin_login.php";
  static const String attendance = "$baseUrl/get_attendance.php";
  static const String changePassword = "$baseUrl/change_password.php";
  static const String analytics = "$baseUrl/get_analytics.php";

  static const String dashboardStats = "$baseUrl/get_dashboard_stats.php";
}

/* 


import 'package:wvsu_attendance_system/config/api_config.dart';

final uri = Uri.parse('http://localhost/libgate_api/upload.php');
final String apiUrl = 'http://localhost/libgate_api/academic_api.php';
const String _apiUrl = "http://localhost/libgate_api/manage_admins.php";
 Uri.parse('http://localhost/libgate_api/admin_login.php'),



--- static const String _base = 'http://localhost/libgate_api';
'http://localhost/libgate_api/get_attendance.php'; 
static const String _base = 'http://localhost/libgate_api';
Uri.parse('http://localhost/libgate_api/change_password.php'),


final String baseUrl = 'http://localhost/libgate_api';


*/
