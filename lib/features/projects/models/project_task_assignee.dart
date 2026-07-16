class ProjectTaskAssignee {
  const ProjectTaskAssignee({
    required this.userId,
    required this.role,
    required this.status,
    required this.fullName,
    required this.email,
  });

  final String userId;
  final String role;
  final String status;
  final String fullName;
  final String email;

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName;
    if (email.trim().isNotEmpty) return email;
    return 'Unknown user';
  }

  String get subtitle {
    final cleanRole = role.replaceAll('_', ' ').toUpperCase();

    if (email.trim().isEmpty) return cleanRole;

    return '$cleanRole • $email';
  }

  factory ProjectTaskAssignee.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    return ProjectTaskAssignee(
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'active',
      fullName: profile?['full_name'] as String? ?? '',
      email: profile?['email'] as String? ?? '',
    );
  }
}
