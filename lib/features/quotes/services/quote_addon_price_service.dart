import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quote_addon_price.dart';

class QuoteAddonPriceService {
  QuoteAddonPriceService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<QuoteAddonPrice>> getActivePrices({
    required String companyId,
  }) async {
    final rows = await _supabase
        .from('quote_addon_prices')
        .select()
        .or('company_id.is.null,company_id.eq.$companyId')
        .order('addon_type', ascending: true)
        .order('sort_order', ascending: true);

    final prices = rows.map<QuoteAddonPrice>(QuoteAddonPrice.fromMap).toList();

    final byKey = <String, QuoteAddonPrice>{};

    for (final price in prices) {
      final existing = byKey[price.addonKey];

      if (existing == null) {
        byKey[price.addonKey] = price;
        continue;
      }

      final priceIsCompanyOverride = price.companyId == companyId;
      final existingIsGlobalDefault = existing.companyId == null;

      if (priceIsCompanyOverride && existingIsGlobalDefault) {
        byKey[price.addonKey] = price;
      }
    }

    final dedupedPrices = byKey.values.where((price) => price.isActive).toList()
      ..sort((a, b) {
        final typeCompare = a.addonType.compareTo(b.addonType);
        if (typeCompare != 0) return typeCompare;

        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;

        return a.addonName.compareTo(b.addonName);
      });

    return dedupedPrices;
  }

  Future<void> deletePrice({
    required String companyId,
    required QuoteAddonPrice price,
  }) async {
    final existingCompanyRows = await _supabase
        .from('quote_addon_prices')
        .select('id')
        .eq('company_id', companyId)
        .eq('addon_key', price.addonKey)
        .limit(1);

    final now = DateTime.now().toIso8601String();

    if (existingCompanyRows.isNotEmpty) {
      final existingId = existingCompanyRows.first['id'] as String;

      await _supabase.from('quote_addon_prices').delete().eq('id', existingId);

      return;
    }

    await _supabase.from('quote_addon_prices').insert({
      'company_id': companyId,
      'addon_key': price.addonKey,
      'addon_name': price.addonName,
      'addon_type': price.addonType,
      'unit': price.unit,
      'unit_price': price.unitPrice,
      'is_active': false,
      'sort_order': price.sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updatePrice({
    required String companyId,
    required QuoteAddonPrice price,
    required double unitPrice,
  }) async {
    final existingCompanyRows = await _supabase
        .from('quote_addon_prices')
        .select('id')
        .eq('company_id', companyId)
        .eq('addon_key', price.addonKey)
        .limit(1);

    final now = DateTime.now().toIso8601String();

    if (existingCompanyRows.isNotEmpty) {
      final existingId = existingCompanyRows.first['id'] as String;

      await _supabase
          .from('quote_addon_prices')
          .update({
            'addon_name': price.addonName,
            'addon_type': price.addonType,
            'unit': price.unit,
            'unit_price': unitPrice,
            'is_active': true,
            'sort_order': price.sortOrder,
            'updated_at': now,
          })
          .eq('id', existingId);

      return;
    }

    await _supabase.from('quote_addon_prices').insert({
      'company_id': companyId,
      'addon_key': price.addonKey,
      'addon_name': price.addonName,
      'addon_type': price.addonType,
      'unit': price.unit,
      'unit_price': unitPrice,
      'is_active': true,
      'sort_order': price.sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }
}
