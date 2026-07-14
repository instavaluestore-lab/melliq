class CompanyContext {
  const CompanyContext({
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userEmail,
    required this.role,
    required this.status,
  });

  final String companyId;
  final String companyName;
  final String userId;
  final String userEmail;
  final String role;
  final String status;

  bool get canViewExpenses {
    return role == 'owner' || role == 'admin' || role == 'manager';
  }

  bool get canManageExpenses {
    return role == 'owner' || role == 'admin' || role == 'manager';
  }

  bool get isFieldUser {
    return role == 'field_user';
  }

  bool get isViewer {
    return role == 'viewer';
  }

  factory CompanyContext.fromMap(Map<String, dynamic> map) {
    return CompanyContext(
      companyId: map['company_id'] as String,
      companyName: map['company_name'] as String,
      userId: map['user_id'] as String,
      userEmail: map['user_email'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
    );
  }
}
