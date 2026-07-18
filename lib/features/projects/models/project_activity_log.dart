class ProjectActivityLog {
  const ProjectActivityLog({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.activityType,
    required this.title,
    required this.createdAt,
    this.body,
    this.createdBy,
    this.creatorName,
    this.creatorEmail,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String activityType;
  final String title;
  final String? body;
  final String? createdBy;
  final DateTime createdAt;
  final String? creatorName;
  final String? creatorEmail;

  String get activityTypeLabel {
    return switch (activityType) {
      'status_changed' => 'Status Changed',
      'material_created' => 'Material Added',
      'material_status_changed' => 'Material Status',
      'task_created' => 'Task Added',
      'task_completed' => 'Task Completed',
      'task_reopened' => 'Task Reopened',
      'task_deleted' => 'Task Deleted',
      'note_created' => 'Note Added',
      'note_deleted' => 'Note Deleted',
      'file_uploaded' => 'File Uploaded',
      'file_deleted' => 'File Deleted',
      'project_updated' => 'Project Updated',
      _ => activityType.replaceAll('_', ' ').toUpperCase(),
    };
  }

  String get creatorLabel {
    final name = creatorName?.trim();
    final email = creatorEmail?.trim();

    if (name != null && name.isNotEmpty) return name;
    if (email != null && email.isNotEmpty) return email;

    return 'System';
  }

  factory ProjectActivityLog.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    return ProjectActivityLog(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      activityType: map['activity_type'] as String? ?? 'project_updated',
      title: map['title'] as String? ?? '',
      body: map['body'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      creatorName: profile?['full_name'] as String?,
      creatorEmail: profile?['email'] as String?,
    );
  }
}
