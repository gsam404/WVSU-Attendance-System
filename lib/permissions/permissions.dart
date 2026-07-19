import '../pages/admin_session.dart';

class Permissions {
  // Students
  static bool get canManageStudents =>
      AdminSession.isMainAdmin || AdminSession.isCampusAdmin;
  static bool get canEditStudents =>
      AdminSession.isMainAdmin || AdminSession.isCampusAdmin;
  static bool get canDeleteStudents => AdminSession.isMainAdmin;

  // Attendance
  static bool get canViewAttendance =>
      AdminSession.isMainAdmin ||
      AdminSession.isCampusAdmin ||
      AdminSession.isLibraryStaff;
  static bool get canExportAttendance =>
      AdminSession.isMainAdmin ||
      AdminSession.isCampusAdmin ||
      AdminSession.isLibraryStaff;

  // Analytics
  static bool get canViewAnalytics =>
      AdminSession.isMainAdmin || AdminSession.isCampusAdmin;

  // Admins
  static bool get canManageAdmins => AdminSession.isMainAdmin;

  // Academic Setup
  static bool get canManageAcademicSetup =>
      AdminSession.isMainAdmin || AdminSession.isCampusAdmin;
}
