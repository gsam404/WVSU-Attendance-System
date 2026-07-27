class ImportSummary {
  final int totalRows;
  final int imported;
  final int updated;
  final int skipped;
  final String timestamp;

  ImportSummary({
    required this.totalRows,
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.timestamp,
  });

  factory ImportSummary.fromJson(Map<String, dynamic> json) {
    return ImportSummary(
      totalRows: json['total_rows'],
      imported: json['imported'],
      updated: json['updated'],
      skipped: json['skipped'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class ImportErrorItem {
  final int row;
  final String type;
  final String field;
  final String message;
  final String? value;

  ImportErrorItem({
    required this.row,
    required this.type,
    required this.field,
    required this.message,
    this.value,
  });

  factory ImportErrorItem.fromJson(Map<String, dynamic> json) {
    return ImportErrorItem(
      row: json['row'],
      type: json['type'],
      field: json['field'] ?? '',
      message: json['message'],
      value: json['value'],
    );
  }
}
