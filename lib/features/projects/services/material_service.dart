import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/material_item.dart';

class MaterialService {
  MaterialService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<MaterialItem>> getMaterialsForProject({
    required String companyId,
    required String projectId,
  }) async {
    final rows = await _supabase
        .from('materials')
        .select()
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return rows.map<MaterialItem>(MaterialItem.fromMap).toList();
  }

  Future<MaterialItem> createMaterial({
    required String companyId,
    required String projectId,
    required String name,
    String? category,
    required double quantity,
    required String unit,
    required double unitCost,
    String? supplier,
    required String status,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final totalCost = quantity * unitCost;

    final row = await _supabase
        .from('materials')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'name': name.trim(),
          'category': category?.trim().isEmpty == true ? null : category?.trim(),
          'quantity': quantity,
          'unit': unit.trim().isEmpty ? 'each' : unit.trim(),
          'unit_cost': unitCost,
          'total_cost': totalCost,
          'supplier': supplier?.trim().isEmpty == true ? null : supplier?.trim(),
          'status': status,
          'created_by': currentUserId,
        })
        .select()
        .single();

    return MaterialItem.fromMap(row);
  }

  Future<MaterialItem> updateMaterial({
    required String id,
    required String name,
    String? category,
    required double quantity,
    required String unit,
    required double unitCost,
    String? supplier,
    required String status,
  }) async {
    final totalCost = quantity * unitCost;

    final row = await _supabase
        .from('materials')
        .update({
          'name': name.trim(),
          'category': category?.trim().isEmpty == true ? null : category?.trim(),
          'quantity': quantity,
          'unit': unit.trim().isEmpty ? 'each' : unit.trim(),
          'unit_cost': unitCost,
          'total_cost': totalCost,
          'supplier': supplier?.trim().isEmpty == true ? null : supplier?.trim(),
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return MaterialItem.fromMap(row);
  }

  Future<void> updateMaterialStatus({
    required String id,
    required String status,
  }) async {
    await _supabase
        .from('materials')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteMaterial(String id) async {
    await _supabase.from('materials').delete().eq('id', id);
  }
}
