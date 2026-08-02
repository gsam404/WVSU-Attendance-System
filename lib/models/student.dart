class Student {
  final String studentId;
  final String firstName;
  final String lastName;
  final String middleName;
  final String program;
  final String year;
  final String section;
  final String birthDate;
  final String birthPlace;
  final String gender;
  final String email;

  const Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.program,
    required this.year,
    required this.section,
    required this.birthDate,
    required this.birthPlace,
    required this.gender,
    required this.email,
  });

  String get fullName {
    if (middleName.trim().isEmpty) {
      return "$lastName, $firstName";
    }
    return "$lastName, $firstName $middleName";
  }
}
