class RecordAuditLog {
  const RecordAuditLog({
    required this.id,
    required this.companyId,
    required this.recordType,
    required this.recordId,
    required this.action,
    this.fieldName,
    this.oldValue,
    this.newValue,
    required this.summary,
    this.createdBy,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String companyId;
  final String recordType;
  final String recordId;
  final String action;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String summary;
  final String? createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory RecordAuditLog.fromMap(Map<String, dynamic> map) {
    return RecordAuditLog(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      recordType: map['record_type'] as String,
      recordId: map['record_id'] as String,
      action: map['action'] as String,
      fieldName: map['field_name'] as String?,
      oldValue: map['old_value'] as String?,
      newValue: map['new_value'] as String?,
      summary: map['summary'] as String,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      metadata: Map<String, dynamic>.from(
        (map['metadata'] as Map?) ?? const {},
      ),
    );
  }
}
