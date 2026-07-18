import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quote.dart';
import '../models/quote_line_item.dart';

class QuoteDraftLineItem {
  const QuoteDraftLineItem({
    required this.itemType,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.unitPrice,
    required this.sortOrder,
    this.description,
  });

  final String itemType;
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double unitCost;
  final double unitPrice;
  final int sortOrder;

  double get totalCost => quantity * unitCost;
  double get totalPrice => quantity * unitPrice;
}

class QuoteTotals {
  const QuoteTotals({
    required this.subtotal,
    required this.markupAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.estimatedCost,
    required this.estimatedProfit,
    required this.estimatedMarginPercent,
  });

  final double subtotal;
  final double markupAmount;
  final double taxAmount;
  final double totalAmount;
  final double estimatedCost;
  final double estimatedProfit;
  final double estimatedMarginPercent;
}

class QuoteService {
  QuoteService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Quote>> getQuotesForCompany({
    required String companyId,
    bool includeArchived = false,
  }) async {
    var query = _supabase
        .from('quotes')
        .select()
        .eq('company_id', companyId);

    if (!includeArchived) {
      query = query.isFilter('archived_at', null);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('updated_at', ascending: false);

    return rows.map<Quote>(Quote.fromMap).toList();
  }

  Future<List<QuoteLineItem>> getQuoteLineItems({
    required String quoteId,
  }) async {
    final rows = await _supabase
        .from('quote_line_items')
        .select()
        .eq('quote_id', quoteId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    return rows.map<QuoteLineItem>(QuoteLineItem.fromMap).toList();
  }

  Future<String> getNextQuoteNumber({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('quotes')
        .select('quote_number')
        .eq('company_id', companyId)
        .like('quote_number', 'Q26-%');

    final rows = response.cast<Map<String, dynamic>>();
    var highestNumber = 999;

    final pattern = RegExp(r'^Q26-(\\d+)$');

    for (final row in rows) {
      final value = row['quote_number']?.toString().trim() ?? '';
      final match = pattern.firstMatch(value);

      if (match == null) continue;

      final number = int.tryParse(match.group(1) ?? '');
      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'Q26-${highestNumber + 1}';
  }

  Future<Quote> createQuote({
    required String companyId,
    required String customerId,
    required String title,
    required String status,
    required double markupPercent,
    required double taxPercent,
    required double discountAmount,
    required List<QuoteDraftLineItem> lineItems,
    String? leadId,
    String? notes,
    DateTime? validUntil,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final quoteNumber = await getNextQuoteNumber(companyId: companyId);
    final totals = calculateTotals(
      lineItems: lineItems,
      markupPercent: markupPercent,
      taxPercent: taxPercent,
      discountAmount: discountAmount,
    );

    final quoteRow = await _supabase
        .from('quotes')
        .insert({
          'company_id': companyId,
          'customer_id': customerId,
          'lead_id': leadId,
          'quote_number': quoteNumber,
          'title': title.trim(),
          'status': status,
          'subtotal': totals.subtotal,
          'markup_percent': markupPercent,
          'markup_amount': totals.markupAmount,
          'tax_percent': taxPercent,
          'tax_amount': totals.taxAmount,
          'discount_amount': discountAmount,
          'total_amount': totals.totalAmount,
          'estimated_cost': totals.estimatedCost,
          'estimated_profit': totals.estimatedProfit,
          'estimated_margin_percent': totals.estimatedMarginPercent,
          'notes': _emptyToNull(notes),
          'valid_until': validUntil?.toIso8601String().split('T').first,
          'created_by': userId,
        })
        .select()
        .single();

    final quote = Quote.fromMap(quoteRow);

    await _replaceLineItems(
      companyId: companyId,
      quoteId: quote.id,
      lineItems: lineItems,
    );

    final savedLineItems = await getQuoteLineItems(quoteId: quote.id);

    return quote.copyWith(lineItems: savedLineItems);
  }

  Future<Quote> updateQuote({
    required String quoteId,
    required String companyId,
    required String customerId,
    required String title,
    required String status,
    required double markupPercent,
    required double taxPercent,
    required double discountAmount,
    required List<QuoteDraftLineItem> lineItems,
    String? leadId,
    String? notes,
    DateTime? validUntil,
  }) async {
    final totals = calculateTotals(
      lineItems: lineItems,
      markupPercent: markupPercent,
      taxPercent: taxPercent,
      discountAmount: discountAmount,
    );

    final quoteRow = await _supabase
        .from('quotes')
        .update({
          'customer_id': customerId,
          'lead_id': leadId,
          'title': title.trim(),
          'status': status,
          'subtotal': totals.subtotal,
          'markup_percent': markupPercent,
          'markup_amount': totals.markupAmount,
          'tax_percent': taxPercent,
          'tax_amount': totals.taxAmount,
          'discount_amount': discountAmount,
          'total_amount': totals.totalAmount,
          'estimated_cost': totals.estimatedCost,
          'estimated_profit': totals.estimatedProfit,
          'estimated_margin_percent': totals.estimatedMarginPercent,
          'notes': _emptyToNull(notes),
          'valid_until': validUntil?.toIso8601String().split('T').first,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quoteId)
        .select()
        .single();

    await _replaceLineItems(
      companyId: companyId,
      quoteId: quoteId,
      lineItems: lineItems,
    );

    final savedLineItems = await getQuoteLineItems(quoteId: quoteId);

    return Quote.fromMap(quoteRow).copyWith(lineItems: savedLineItems);
  }

  Future<void> archiveQuote(String quoteId) async {
    await _supabase
        .from('quotes')
        .update({
          'archived_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quoteId);
  }

  Future<void> _replaceLineItems({
    required String companyId,
    required String quoteId,
    required List<QuoteDraftLineItem> lineItems,
  }) async {
    await _supabase
        .from('quote_line_items')
        .delete()
        .eq('quote_id', quoteId);

    if (lineItems.isEmpty) return;

    await _supabase.from('quote_line_items').insert(
          lineItems
              .asMap()
              .entries
              .map(
                (entry) => {
                  'company_id': companyId,
                  'quote_id': quoteId,
                  'item_type': entry.value.itemType,
                  'name': entry.value.name.trim(),
                  'description': _emptyToNull(entry.value.description),
                  'quantity': entry.value.quantity,
                  'unit': entry.value.unit.trim().isEmpty
                      ? 'each'
                      : entry.value.unit.trim(),
                  'unit_cost': entry.value.unitCost,
                  'unit_price': entry.value.unitPrice,
                  'total_cost': entry.value.totalCost,
                  'total_price': entry.value.totalPrice,
                  'sort_order': entry.key,
                },
              )
              .toList(),
        );
  }

  QuoteTotals calculateTotals({
    required List<QuoteDraftLineItem> lineItems,
    required double markupPercent,
    required double taxPercent,
    required double discountAmount,
  }) {
    final subtotal = lineItems.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final estimatedCost = lineItems.fold<double>(
      0,
      (total, item) => total + item.totalCost,
    );
    final markupAmount = subtotal * (markupPercent / 100);
    final taxableAmount = subtotal + markupAmount - discountAmount;
    final taxAmount = taxableAmount <= 0 ? 0.0 : taxableAmount * (taxPercent / 100);
    final totalAmount = taxableAmount + taxAmount;
    final estimatedProfit = totalAmount - estimatedCost;
    final estimatedMarginPercent =
        totalAmount <= 0 ? 0.0 : (estimatedProfit / totalAmount) * 100;

    return QuoteTotals(
      subtotal: subtotal,
      markupAmount: markupAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      estimatedCost: estimatedCost,
      estimatedProfit: estimatedProfit,
      estimatedMarginPercent: estimatedMarginPercent,
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }
}
