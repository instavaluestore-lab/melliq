class UserNotification {
  const UserNotification({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.createdAt,
    this.body,
    this.projectId,
    this.taskId,
    this.actorUserId,
    this.readAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final String notificationType;
  final String title;
  final String? body;
  final String? projectId;
  final String? taskId;
  final String? actorUserId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  String get notificationTypeLabel {
    return switch (notificationType) {
      'task_assigned' => 'Task Assigned',
      'task_reassigned' => 'Task Reassigned',
      _ => notificationType.replaceAll('_', ' ').toUpperCase(),
    };
  }

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    final readAtValue = map['read_at'] as String?;

    return UserNotification(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      userId: map['user_id'] as String,
      notificationType: map['notification_type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      projectId: map['project_id'] as String?,
      taskId: map['task_id'] as String?,
      actorUserId: map['actor_user_id'] as String?,
      readAt: readAtValue == null ? null : DateTime.parse(readAtValue),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
