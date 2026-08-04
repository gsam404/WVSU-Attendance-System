class Student {
  final String studentId;
  final String lastName;
  final String firstName;
  final String middleName;
  final String program;
  final String year;
  final String section;
  final String email;

  Student({
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.program,
    required this.year,
    required this.section,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_number']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      program: json['program']?.toString() ?? '',
      year: json['year_level']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      email: json['email_address']?.toString() ?? '',
    );
  }
}