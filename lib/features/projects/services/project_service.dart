import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
import 'project_stage_cost_service.dart';

class ProjectDashboardMetrics {
  const ProjectDashboardMetrics({
    required this.activeProjects,
    required this.projectExpenses,
    required this.openProjectTotalValue,
    required this.totalOpenProjectProfit,
    required this.totalAnnualProjectProfit,
  });

  final int activeProjects;
  final double projectExpenses;
  final double openProjectTotalValue;
  final double totalOpenProjectProfit;
  final double totalAnnualProjectProfit;
}

class ProjectService {
  ProjectService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Project>> getProjectsForCustomer({
    required String companyId,
    required String customerId,
  }) async {
    final response = await _supabase
        .from('projects')
        .select('''
          id,
          company_id,
          customer_id,
          project_number,
          name,
          status,
          priority,
          address_line_1,
          address_line_2,
          city,
          state,
          postal_code,
          country,
          contract_amount,
          estimated_cost,
          actual_cost,
          estimated_profit,
          actual_profit,
          notes
        ''')
        .eq('company_id', companyId)
        .eq('customer_id', customerId)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false);

    return response
        .map<Project>(
          (item) => Project.fromMap(item),
        )
        .toList();
  }

  Future<List<Project>> getProjectsForCompany({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('projects')
        .select('''
          id,
          company_id,
          customer_id,
          project_number,
          name,
          status,
          priority,
          address_line_1,
          address_line_2,
          city,
          state,
          postal_code,
          country,
          contract_amount,
          estimated_cost,
          actual_cost,
          estimated_profit,
          actual_profit,
          notes
        ''')
        .eq('company_id', companyId)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false);

    return response
        .map<Project>(
          (item) => Project.fromMap(item),
        )
        .toList();
  }

  Future<Project> getProjectById(String projectId) async {
    final response = await _supabase
        .from('projects')
        .select('''
          id,
          company_id,
          customer_id,
          project_number,
          name,
          status,
          priority,
          address_line_1,
          address_line_2,
          city,
          state,
          postal_code,
          country,
          contract_amount,
          estimated_cost,
          actual_cost,
          estimated_profit,
          actual_profit,
          notes
        ''')
        .eq('id', projectId)
        .single();

    return Project.fromMap(response);
  }

  Future<void> updateProjectStatus({
    required String projectId,
    required String status,
  }) async {
    await _supabase.from('projects').update({
      'status': status,
    }).eq('id', projectId);
  }


  Future<String> getNextProjectNumber({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('projects')
        .select('project_number')
        .eq('company_id', companyId)
        .like('project_number', 'MS26-%');

    final rows = response.cast<Map<String, dynamic>>();
    var highestNumber = 6999;

    final pattern = RegExp(r'^MS26-(\d+)$');

    for (final row in rows) {
      final value = row['project_number']?.toString().trim() ?? '';
      final match = pattern.firstMatch(value);

      if (match == null) {
        continue;
      }

      final number = int.tryParse(match.group(1) ?? '');

      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'MS26-${highestNumber + 1}';
  }

  Future<String> createProjectForCustomer({
    required String companyId,
    required String customerId,
    required String createdBy,
    required String projectName,
    required String projectNumber,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String status,
    required String priority,
    required String notes,
    double contractAmount = 0,
    double estimatedCost = 0,
    double estimatedProfit = 0,
  }) async {
    final createdProject = await _supabase
        .from('projects')
        .insert({
          'company_id': companyId,
          'customer_id': customerId,
          'created_by': createdBy,
          'project_number': projectNumber.trim(),
          'name': projectName.trim(),
          'status': status,
          'priority': priority,
          'address_line_1': _emptyToNull(addressLine1),
          'address_line_2': _emptyToNull(addressLine2),
          'city': _emptyToNull(city),
          'state': _emptyToNull(state),
          'postal_code': _emptyToNull(postalCode),
          'country': country.trim().isEmpty ? 'USA' : country.trim(),
          'contract_amount': contractAmount,
          'estimated_cost': estimatedCost,
          'actual_cost': 0,
          'estimated_profit': estimatedProfit,
          'actual_profit': 0,
          'notes': _emptyToNull(notes),
        })
        .select('id')
        .single();

    final projectId = createdProject['id'] as String;

    await ProjectStageCostService(_supabase).createDefaultStageCosts(
      companyId: companyId,
      projectId: projectId,
      createdBy: createdBy,
    );

    return projectId;
  }

  Future<ProjectDashboardMetrics> getCompanyDashboardMetrics({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('projects')
        .select('''
          id,
          status,
          contract_amount,
          actual_cost,
          actual_profit,
          completed_date,
          created_at,
          archived_at
        ''')
        .eq('company_id', companyId)
        .isFilter('archived_at', null);

    final rows = response.cast<Map<String, dynamic>>();
    final currentYear = DateTime.now().year;

    final openProjects = rows.where((project) {
      return (project['status'] as String?) != 'completed';
    }).toList();

    final activeProjects = openProjects.length;

    final projectExpenses = rows.fold<double>(
      0,
      (total, project) => total + _toDouble(project['actual_cost']),
    );

    final openProjectTotalValue = openProjects.fold<double>(
      0,
      (total, project) => total + _toDouble(project['contract_amount']),
    );

    final totalOpenProjectProfit = openProjects.fold<double>(
      0,
      (total, project) => total + _toDouble(project['actual_profit']),
    );

    final totalAnnualProjectProfit = rows.where((project) {
      final completedDate = _parseDate(project['completed_date']);
      final createdAt = _parseDate(project['created_at']);

      return completedDate?.year == currentYear || createdAt?.year == currentYear;
    }).fold<double>(
      0,
      (total, project) => total + _toDouble(project['actual_profit']),
    );

    return ProjectDashboardMetrics(
      activeProjects: activeProjects,
      projectExpenses: projectExpenses,
      openProjectTotalValue: openProjectTotalValue,
      totalOpenProjectProfit: totalOpenProjectProfit,
      totalAnnualProjectProfit: totalAnnualProjectProfit,
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
