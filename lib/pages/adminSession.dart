// admin_session.dart
// Static session store — used across the app

class AdminSession {
  static String id = '';
  static String name = '';
  static String email = '';
  static String role = '';
  static String profilePicUrl = '';

  /// Set session after login
  static void set({
    required String adminId,
    required String fullName,
    required String adminEmail,
    required String adminRole,
    String picUrl = '',
  }) {
    id = adminId;
    name = fullName;
    email = adminEmail;
    role = adminRole;
    profilePicUrl = picUrl;
  }

  /// Clear session on logout
  static void clear() {
    id = '';
    name = '';
    email = '';
    role = '';
    profilePicUrl = '';
  }

  /// Check if logged in
  static bool get isLoggedIn => id.isNotEmpty;

  /// Role check
  static bool get isMainAdmin => role == 'main_admin';
}