import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/standard_structure_price.dart';

class StandardStructurePriceService {
  StandardStructurePriceService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<StandardStructurePrice>> getActivePrices({
    required String companyId,
    String? structureType,
  }) async {
    var query = _supabase
        .from('standard_structure_prices')
        .select()
        .or('company_id.is.null,company_id.eq.$companyId')
        .eq('is_active', true);

    if (structureType != null && structureType.trim().isNotEmpty) {
      query = query.eq('structure_type', structureType.trim());
    }

    final rows = await query
        .order('structure_type', ascending: true)
        .order('sort_order', ascending: true)
        .order('length_feet', ascending: true)
        .order('width_feet', ascending: true);

    return rows
        .map<StandardStructurePrice>(StandardStructurePrice.fromMap)
        .toList();
  }
}
