class TeamMember {
  const TeamMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.status,
    this.invitedBy,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String companyId;
  final String userId;
  final String role;
  final String status;
  final String? invitedBy;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;

  String get displayName {
    final name = fullName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return email;
  }

  String get roleLabel {
    switch (role) {
      case 'primary_admin':
        return 'PRIMARY ADMIN';
      case 'cfo':
        return 'CFO';
      case 'admin':
        return 'ADMIN';
      case 'manager':
        return 'MANAGER';
      case 'field_user':
        return 'FIELD USER';
      case 'viewer':
        return 'VIEWER';
      default:
        return role.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get statusLabel {
    switch (status) {
      case 'invited':
        return 'INVITED';
      case 'active':
        return 'ACTIVE';
      case 'disabled':
        return 'DISABLED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool get isPrimaryAdmin => role == 'primary_admin';

  bool get isActive => status == 'active';

  bool get isDisabled => status == 'disabled';

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final createdAtText = map['created_at'] as String?;
    final updatedAtText = map['updated_at'] as String?;

    final createdAt = createdAtText == null
        ? DateTime.now()
        : DateTime.parse(createdAtText);

    return TeamMember(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'field_user',
      status: map['status'] as String? ?? 'active',
      invitedBy: map['invited_by'] as String?,
      joinedAt: map['joined_at'] == null
          ? null
          : DateTime.parse(map['joined_at'] as String),
      createdAt: createdAt,
      updatedAt: updatedAtText == null
          ? createdAt
          : DateTime.parse(updatedAtText),
      fullName: profile?['full_name'] as String?,
      email: profile?['email'] as String? ?? 'No email',
      phone: profile?['phone'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
