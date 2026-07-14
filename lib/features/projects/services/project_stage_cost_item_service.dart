import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_stage_cost_item.dart';

class ProjectStageCostItemService {
  ProjectStageCostItemService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProjectStageCostItem>> getItemsForProject({
    required String companyId,
    required String projectId,
  }) async {
    final response = await _supabase
        .from('project_stage_cost_items')
        .select('''
          id,
          company_id,
          project_id,
          stage_cost_id,
          item_type,
          description,
          estimated_cost,
          actual_cost
        ''')
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .order('created_at', ascending: true);

    return response
        .map<ProjectStageCostItem>(
          (item) => ProjectStageCostItem.fromMap(item),
        )
        .toList();
  }

  Future<ProjectStageCostItem> createAdditionalActualCostItem({
    required String companyId,
    required String projectId,
    required String stageCostId,
    required String createdBy,
  }) async {
    final response = await _supabase
        .from('project_stage_cost_items')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'stage_cost_id': stageCostId,
          'item_type': 'additional_actual',
          'description': null,
          'estimated_cost': 0,
          'actual_cost': 0,
          'created_by': createdBy,
        })
        .select('''
          id,
          company_id,
          project_id,
          stage_cost_id,
          item_type,
          description,
          estimated_cost,
          actual_cost
        ''')
        .single();

    return ProjectStageCostItem.fromMap(response);
  }

  Future<void> updateItem({
    required String itemId,
    required String description,
    required double actualCost,
  }) async {
    await _supabase.from('project_stage_cost_items').update({
      'description': _emptyToNull(description),
      'actual_cost': actualCost,
    }).eq('id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await _supabase.from('project_stage_cost_items').delete().eq('id', itemId);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
