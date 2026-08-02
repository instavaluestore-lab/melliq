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
        .or('company_id.is.null,company_id.eq.$companyId');

    if (structureType != null && structureType.trim().isNotEmpty) {
      query = query.eq('structure_type', structureType.trim());
    }

    final rows = await query
        .order('structure_type', ascending: true)
        .order('sort_order', ascending: true)
        .order('length_feet', ascending: true)
        .order('width_feet', ascending: true);

    final prices = rows
        .map<StandardStructurePrice>(StandardStructurePrice.fromMap)
        .toList();

    final byKey = <String, StandardStructurePrice>{};

    for (final price in prices) {
      final key = _priceKey(price);
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = price;
        continue;
      }

      final priceIsCompanyOverride = price.companyId == companyId;
      final existingIsGlobalDefault = existing.companyId == null;

      if (priceIsCompanyOverride && existingIsGlobalDefault) {
        byKey[key] = price;
      }
    }

    final dedupedPrices = byKey.values.where((price) => price.isActive).toList()
      ..sort((a, b) {
        final typeCompare = a.structureType.compareTo(b.structureType);
        if (typeCompare != 0) return typeCompare;

        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;

        final lengthCompare = a.lengthFeet.compareTo(b.lengthFeet);
        if (lengthCompare != 0) return lengthCompare;

        return a.widthFeet.compareTo(b.widthFeet);
      });

    return dedupedPrices;
  }

  Future<void> updatePrice({
    required String companyId,
    required StandardStructurePrice price,
    required double unitPrice,
  }) async {
    final existingCompanyRows = await _supabase
        .from('standard_structure_prices')
        .select('id')
        .eq('company_id', companyId)
        .eq('structure_type', price.structureType)
        .eq('length_feet', price.lengthFeet)
        .eq('width_feet', price.widthFeet)
        .limit(1);

    final now = DateTime.now().toIso8601String();

    if (existingCompanyRows.isNotEmpty) {
      final existingId = existingCompanyRows.first['id'] as String;

      await _supabase
          .from('standard_structure_prices')
          .update({
            'structure_name': price.structureName,
            'size_label': price.sizeOnlyLabel,
            'width_feet': price.widthFeet,
            'length_feet': price.lengthFeet,
            'price': unitPrice,
            'is_active': true,
            'sort_order': price.sortOrder,
            'updated_at': now,
          })
          .eq('id', existingId);

      return;
    }

    await _supabase.from('standard_structure_prices').insert({
      'company_id': companyId,
      'structure_type': price.structureType,
      'structure_name': price.structureName,
      'size_label': price.sizeOnlyLabel,
      'width_feet': price.widthFeet,
      'length_feet': price.lengthFeet,
      'price': unitPrice,
      'is_active': true,
      'sort_order': price.sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> addPrice({
    required String companyId,
    required String structureType,
    required String structureName,
    required double lengthFeet,
    required double widthFeet,
    required double unitPrice,
    required int sortOrder,
  }) async {
    final sizeLabel =
        '${_formatNumber(lengthFeet)} ft × ${_formatNumber(widthFeet)} ft';

    final existingCompanyRows = await _supabase
        .from('standard_structure_prices')
        .select('id')
        .eq('company_id', companyId)
        .eq('structure_type', structureType)
        .eq('length_feet', lengthFeet)
        .eq('width_feet', widthFeet)
        .limit(1);

    final now = DateTime.now().toIso8601String();

    if (existingCompanyRows.isNotEmpty) {
      final existingId = existingCompanyRows.first['id'] as String;

      await _supabase
          .from('standard_structure_prices')
          .update({
            'structure_name': structureName,
            'size_label': sizeLabel,
            'price': unitPrice,
            'is_active': true,
            'sort_order': sortOrder,
            'updated_at': now,
          })
          .eq('id', existingId);

      return;
    }

    await _supabase.from('standard_structure_prices').insert({
      'company_id': companyId,
      'structure_type': structureType,
      'structure_name': structureName,
      'size_label': sizeLabel,
      'width_feet': widthFeet,
      'length_feet': lengthFeet,
      'price': unitPrice,
      'is_active': true,
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> deletePrice({
    required String companyId,
    required StandardStructurePrice price,
  }) async {
    final existingCompanyRows = await _supabase
        .from('standard_structure_prices')
        .select('id')
        .eq('company_id', companyId)
        .eq('structure_type', price.structureType)
        .eq('length_feet', price.lengthFeet)
        .eq('width_feet', price.widthFeet)
        .limit(1);

    final now = DateTime.now().toIso8601String();

    if (existingCompanyRows.isNotEmpty) {
      final existingId = existingCompanyRows.first['id'] as String;

      await _supabase
          .from('standard_structure_prices')
          .delete()
          .eq('id', existingId);

      return;
    }

    await _supabase.from('standard_structure_prices').insert({
      'company_id': companyId,
      'structure_type': price.structureType,
      'structure_name': price.structureName,
      'size_label': price.sizeOnlyLabel,
      'width_feet': price.widthFeet,
      'length_feet': price.lengthFeet,
      'price': price.price,
      'is_active': false,
      'sort_order': price.sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  String _priceKey(StandardStructurePrice price) {
    return [
      price.structureType,
      price.lengthFeet.toString(),
      price.widthFeet.toString(),
    ].join('|');
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}
