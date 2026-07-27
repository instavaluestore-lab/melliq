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
        .eq('is_active', true)
        .order('addon_type', ascending: true)
        .order('sort_order', ascending: true);

    return rows.map<QuoteAddonPrice>(QuoteAddonPrice.fromMap).toList();
  }
}
