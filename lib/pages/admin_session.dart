// admin_session.dart
// Static session store — used across the app

class AdminSession {
  static String id = '';
  static String name = '';
  static String email = '';
  static String role = '';
  static String profilePicUrl = '';
  static int? campusId;
  static String campusName = '';

  /// Set session after login
  static void set({
    required String adminId,
    required String fullName,
    required String adminEmail,
    required String adminRole,
    required int adminCampusId,
    String picUrl = '',
    String adminCampusName = '',
  }) {
    id = adminId;
    name = fullName;
    email = adminEmail;
    role = adminRole;
    profilePicUrl = picUrl;
    campusId = adminCampusId;
    campusName = adminCampusName;
    campusName = '';
  }

  /// Clear session on logout
  static void clear() {
    id = '';
    name = '';
    email = '';
    role = '';
    profilePicUrl = '';
    campusId = null;
    campusName = '';
  }

  /// Check if logged in
  static bool get isLoggedIn => id.isNotEmpty;

  /// Role checks
  static bool get isMainAdmin => role == 'main_admin';

  static bool get isCampusAdmin => role == 'campus_admin';

  static bool get isLibraryStaff => role == 'librarian_staff';
}
