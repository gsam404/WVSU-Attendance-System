// adminSession.dart
// Static session store — populated at login, read everywhere.

class AdminSession {
  static String id            = '';
  static String name          = '';
  static String email         = '';
  static String role          = '';  
  static String profilePicUrl = '';

  /// Call this on logout to wipe the session.
  static void clear() {
    id            = '';
    name          = '';
    email         = '';
    role          = '';
    profilePicUrl = '';
  }

  static bool get isMainAdmin => role == 'main_admin';
}