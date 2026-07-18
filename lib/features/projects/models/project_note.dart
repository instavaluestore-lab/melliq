class ProjectNote {
  const ProjectNote({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.noteType,
    required this.body,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.creatorEmail,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String noteType;
  final String body;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? creatorName;
  final String? creatorEmail;

  String get noteTypeLabel {
    return switch (noteType) {
      'general' => 'General Update',
      'field_update' => 'Field Update',
      'issue' => 'Issue',
      'delay' => 'Delay',
      'customer_note' => 'Customer Note',
      'weather_site' => 'Weather / Site',
      'next_step' => 'Next Step',
      _ => noteType.replaceAll('_', ' ').toUpperCase(),
    };
  }

  String get creatorLabel {
    final name = creatorName?.trim();
    final email = creatorEmail?.trim();

    if (name != null && name.isNotEmpty) return name;
    if (email != null && email.isNotEmpty) return email;

    return 'Unknown user';
  }

  factory ProjectNote.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    return ProjectNote(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      noteType: map['note_type'] as String? ?? 'general',
      body: map['body'] as String? ?? '',
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      creatorName: profile?['full_name'] as String?,
      creatorEmail: profile?['email'] as String?,
    );
  }
}
