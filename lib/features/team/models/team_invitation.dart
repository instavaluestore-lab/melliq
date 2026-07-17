class TeamInvitation {
  const TeamInvitation({
    required this.id,
    required this.companyId,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.invitedBy,
    this.acceptedBy,
    this.acceptedAt,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final String status;
  final String? invitedBy;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final trimmedName = fullName?.trim();

    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }

    return email;
  }

  String get roleLabel {
    return switch (role) {
      'primary_admin' => 'PRIMARY ADMIN',
      'cfo' => 'CFO',
      'admin' => 'ADMIN',
      'manager' => 'MANAGER',
      'field_user' => 'FIELD USER',
      'viewer' => 'VIEWER',
      _ => role.toUpperCase(),
    };
  }

  String get statusLabel {
    return switch (status) {
      'pending' => 'PENDING',
      'accepted' => 'ACCEPTED',
      'canceled' => 'CANCELED',
      _ => status.toUpperCase(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isCanceled => status == 'canceled';
  bool get isAccepted => status == 'accepted';

  factory TeamInvitation.fromMap(Map<String, dynamic> map) {
    final createdAtText = map['created_at'] as String?;
    final updatedAtText = map['updated_at'] as String?;

    final createdAt = createdAtText == null
        ? DateTime.now()
        : DateTime.parse(createdAtText);

    return TeamInvitation(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      email: map['email'] as String? ?? 'No email',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'field_user',
      status: map['status'] as String? ?? 'pending',
      invitedBy: map['invited_by'] as String?,
      acceptedBy: map['accepted_by'] as String?,
      acceptedAt: map['accepted_at'] == null
          ? null
          : DateTime.parse(map['accepted_at'] as String),
      canceledAt: map['canceled_at'] == null
          ? null
          : DateTime.parse(map['canceled_at'] as String),
      createdAt: createdAt,
      updatedAt: updatedAtText == null
          ? createdAt
          : DateTime.parse(updatedAtText),
    );
  }
}
