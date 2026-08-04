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

  // ADDED: for Manage Students page
  static const String students = "$baseUrl/get_students.php";
}