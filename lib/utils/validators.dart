class Validators {
  /// Removes extra spaces from the beginning, end,
  /// and between words.
  static String normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Checks if a field is empty.
  static String? required(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return "$fieldName is required.";
    }
    return null;
  }

  /// Allows letters (A-Z, a-z) and spaces only.
  static String? lettersOnly(String value, String fieldName) {
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value.trim())) {
      return "$fieldName can only contain letters and spaces.";
    }
    return null;
  }

  /// Checks if a value already exists (case-insensitive). Works differently for adding and editing. When adding, it checks if the value exists in the list.
  /// When editing, it ignores the current value being edited.
  static bool isDuplicate(
    String value,
    Iterable<String> existingValues, {
    String? ignore,
  }) {
    final normalizedValue = normalize(value).toLowerCase();
    final normalizedIgnore =
        ignore == null ? null : normalize(ignore).toLowerCase();

    return existingValues.any((item) {
      final normalizedItem = normalize(item).toLowerCase();

      if (normalizedIgnore != null && normalizedItem == normalizedIgnore) {
        return false;
      }

      return normalizedItem == normalizedValue;
    });
  }
}
