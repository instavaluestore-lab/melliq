import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_stage_cost.dart';

class ProjectStageCostService {
  ProjectStageCostService(this._supabase);

  final SupabaseClient _supabase;

  static const List<String> defaultStages = [
    'contract',
    'ordered_material',
    'structure_fabrication',
    'powder_coating',
    'equipment',
    'footers',
    'sail_fabrication',
    'installation',
    'final_invoice',
    'completed',
  ];

  Future<List<ProjectStageCost>> getStageCostsForProject({
    required String companyId,
    required String projectId,
  }) async {
    final response = await _supabase
        .from('project_stage_costs')
        .select('''
          id,
          company_id,
          project_id,
          stage,
          line_type,
          description,
          estimated_cost,
          actual_cost,
          notes,
          is_completed,
          people_count,
          hours_each,
          cost_per_hour,
          flat_fee,
          use_flat_fee,
          concrete_bag_count,
          concrete_bag_cost,
          concrete_unit_type,
          rebar_stick_count,
          rebar_stick_cost,
          anchor_bolt_count,
          anchor_bolt_cost,
          fabric_yards,
          fabric_cost_per_yard,
          hardware_count,
          hardware_cost_each,
          cable_feet,
          cable_cost_per_foot
        ''')
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .order('created_at', ascending: true);

    return response
        .map<ProjectStageCost>((item) => ProjectStageCost.fromMap(item))
        .toList();
  }

  Future<void> createDefaultStageCosts({
    required String companyId,
    required String projectId,
    required String createdBy,
  }) async {
    final existingStages = await _supabase
        .from('project_stage_costs')
        .select('stage')
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .eq('line_type', 'stage');

    final existingStageNames = existingStages
        .map<String>((row) => row['stage'] as String)
        .toSet();

    final missingStages = defaultStages
        .where((stage) => !existingStageNames.contains(stage))
        .map(
          (stage) => {
            'company_id': companyId,
            'project_id': projectId,
            'stage': stage,
            'line_type': 'stage',
            'estimated_cost': 0,
            'actual_cost': 0,
            'created_by': createdBy,
          },
        )
        .toList();

    if (missingStages.isNotEmpty) {
      await _supabase.from('project_stage_costs').insert(missingStages);
    }

    await createMiscellaneousExpense(
      companyId: companyId,
      projectId: projectId,
      createdBy: createdBy,
      description: 'Miscellaneous Expense',
    );
  }

  Future<void> createMiscellaneousExpense({
    required String companyId,
    required String projectId,
    required String createdBy,
    required String description,
  }) async {
    await _supabase.from('project_stage_costs').insert({
      'company_id': companyId,
      'project_id': projectId,
      'stage': 'miscellaneous',
      'line_type': 'miscellaneous',
      'description': description.trim().isEmpty
          ? 'Miscellaneous Expense'
          : description.trim(),
      'estimated_cost': 0,
      'actual_cost': 0,
      'created_by': createdBy,
    });
  }

  Future<void> updateStageCost({
    required String stageCostId,
    required String description,
    required double estimatedCost,
    required double actualCost,
    required String notes,
    required bool isCompleted,
    required int peopleCount,
    required double hoursEach,
    required double costPerHour,
    required double flatFee,
    required bool useFlatFee,
    required int concreteBagCount,
    required double concreteBagCost,
    required String concreteUnitType,
    required int rebarStickCount,
    required double rebarStickCost,
    required int anchorBoltCount,
    required double anchorBoltCost,
    required String? fabricType,
    required double fabricYards,
    required double fabricCostPerYard,
    required int hardwareCount,
    required double hardwareCostEach,
    required double cableFeet,
    required double cableCostPerFoot,
    required double installationMiles,
    required double installationCostPerMile,
  }) async {
    await _supabase
        .from('project_stage_costs')
        .update({
          'description': _emptyToNull(description),
          'estimated_cost': estimatedCost,
          'actual_cost': actualCost,
          'notes': _emptyToNull(notes),
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          'people_count': peopleCount,
          'hours_each': hoursEach,
          'cost_per_hour': costPerHour,
          'flat_fee': flatFee,
          'use_flat_fee': useFlatFee,
          'concrete_bag_count': concreteBagCount,
          'concrete_bag_cost': concreteBagCost,
          'concrete_unit_type': concreteUnitType,
          'rebar_stick_count': rebarStickCount,
          'rebar_stick_cost': rebarStickCost,
          'anchor_bolt_count': anchorBoltCount,
          'anchor_bolt_cost': anchorBoltCost,
          'fabric_type': _emptyToNull(fabricType ?? ''),
          'fabric_yards': fabricYards,
          'fabric_cost_per_yard': fabricCostPerYard,
          'hardware_count': hardwareCount,
          'hardware_cost_each': hardwareCostEach,
          'cable_feet': cableFeet,
          'cable_cost_per_foot': cableCostPerFoot,
          'installation_miles': installationMiles,
          'installation_cost_per_mile': installationCostPerMile,
        })
        .eq('id', stageCostId);
  }

  Future<void> updateProjectFinancialTotals({
    required String projectId,
    required double contractAmount,
    required double estimatedCost,
    required double actualCost,
  }) async {
    await _supabase
        .from('projects')
        .update({
          'contract_amount': contractAmount,
          'estimated_cost': estimatedCost,
          'actual_cost': actualCost,
          'estimated_profit': contractAmount - estimatedCost,
          'actual_profit': contractAmount - actualCost,
        })
        .eq('id', projectId);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
