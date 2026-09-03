class StatusLog {
  StatusLog({
    required this.id,
    required this.fieldName,
    required this.fieldNameLabel,
    required this.status,
    required this.statusLabel,
    required this.note,
    required this.createdByName,
    required this.createdAt,
  });

  final int id;
  final String fieldName;
  final String fieldNameLabel;
  final String status;
  final String statusLabel;
  final String note;
  final String createdByName;
  final DateTime createdAt;

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: json['id'] as int,
      fieldName: json['field_name'] as String? ?? 'status',
      fieldNameLabel: json['field_name_label'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_name': fieldName,
      'field_name_label': fieldNameLabel,
      'status': status,
      'status_label': statusLabel,
      'note': note,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
