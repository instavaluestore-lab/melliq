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

  bool get isPrimaryAdmin {
    return role == 'primary_admin';
  }

  bool get isCfo {
    return role == 'cfo';
  }

  bool get isAdmin {
    return role == 'admin';
  }

  bool get isManager {
    return role == 'manager';
  }

  bool get isFieldUser {
    return role == 'field_user';
  }

  bool get isViewer {
    return role == 'viewer';
  }

  bool get isActive {
    return status == 'active';
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


  bool get hasExecutiveAccess {
    return isPrimaryAdmin || isCfo;
  }

  bool get canManageCompany {
    return hasExecutiveAccess;
  }

  bool get canManageTeam {
    return hasExecutiveAccess;
  }

  bool get canViewFinancials {
    return hasExecutiveAccess;
  }

  bool get canViewExpenses {
    return hasExecutiveAccess;
  }

  bool get canManageExpenses {
    return hasExecutiveAccess;
  }

  bool get canCreateCustomers {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canEditCustomers {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canDeleteCustomers {
    return isPrimaryAdmin || isCfo || isAdmin;
  }

  bool get canViewCustomers {
    return isPrimaryAdmin ||
        isCfo ||
        isAdmin ||
        isManager ||
        isFieldUser ||
        isViewer;
  }

  bool get canCreateProjects {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canEditProjects {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canDeleteProjects {
    return isPrimaryAdmin || isCfo || isAdmin;
  }

  bool get canViewProjects {
    return isPrimaryAdmin ||
        isCfo ||
        isAdmin ||
        isManager ||
        isFieldUser ||
        isViewer;
  }

  bool get canManageProjectFinancials {
    return hasExecutiveAccess;
  }

  bool get canCreateTasks {
    return isPrimaryAdmin || isCfo || isAdmin || isManager || isFieldUser;
  }

  bool get canAssignTasks {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canCompleteTasks {
    return isPrimaryAdmin || isCfo || isAdmin || isManager || isFieldUser;
  }

  bool get canUploadProjectFiles {
    return isPrimaryAdmin || isCfo || isAdmin || isManager || isFieldUser;
  }

  bool get canDeleteProjectFiles {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canCreateMaterials {
    return isPrimaryAdmin || isCfo || isAdmin || isManager || isFieldUser;
  }

  bool get canEditMaterials {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canDeleteMaterials {
    return isPrimaryAdmin || isCfo || isAdmin || isManager;
  }

  bool get canUpdateMaterialStatus {
    return isPrimaryAdmin || isCfo || isAdmin || isManager || isFieldUser;
  }

  bool get canViewTeamList {
    return isPrimaryAdmin ||
        isCfo ||
        isAdmin ||
        isManager ||
        isFieldUser ||
        isViewer;
  }

  bool get canViewOnly {
    return isViewer;
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
