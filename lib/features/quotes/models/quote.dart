import 'quote_line_item.dart';

class Quote {
  const Quote({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.quoteNumber,
    required this.title,
    required this.status,
    required this.subtotal,
    required this.markupPercent,
    required this.markupAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.estimatedCost,
    required this.estimatedProfit,
    required this.estimatedMarginPercent,
    required this.createdAt,
    required this.updatedAt,
    this.leadId,
    this.notes,
    this.validUntil,
    this.createdBy,
    this.archivedAt,
    this.lineItems = const [],
  });

  final String id;
  final String companyId;
  final String customerId;
  final String? leadId;
  final String quoteNumber;
  final String title;
  final String status;
  final double subtotal;
  final double markupPercent;
  final double markupAmount;
  final double taxPercent;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double estimatedCost;
  final double estimatedProfit;
  final double estimatedMarginPercent;
  final String? notes;
  final DateTime? validUntil;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final List<QuoteLineItem> lineItems;

  bool get isArchived => archivedAt != null;

  String get statusLabel {
    return switch (status) {
      'draft' => 'Draft',
      'sent' => 'Sent',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => _titleCase(status),
    };
  }

  Quote copyWith({
    List<QuoteLineItem>? lineItems,
  }) {
    return Quote(
      id: id,
      companyId: companyId,
      customerId: customerId,
      leadId: leadId,
      quoteNumber: quoteNumber,
      title: title,
      status: status,
      subtotal: subtotal,
      markupPercent: markupPercent,
      markupAmount: markupAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      estimatedCost: estimatedCost,
      estimatedProfit: estimatedProfit,
      estimatedMarginPercent: estimatedMarginPercent,
      notes: notes,
      validUntil: validUntil,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      customerId: map['customer_id'] as String,
      leadId: map['lead_id'] as String?,
      quoteNumber: map['quote_number'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: map['status'] as String? ?? 'draft',
      subtotal: _toDouble(map['subtotal']),
      markupPercent: _toDouble(map['markup_percent']),
      markupAmount: _toDouble(map['markup_amount']),
      taxPercent: _toDouble(map['tax_percent']),
      taxAmount: _toDouble(map['tax_amount']),
      discountAmount: _toDouble(map['discount_amount']),
      totalAmount: _toDouble(map['total_amount']),
      estimatedCost: _toDouble(map['estimated_cost']),
      estimatedProfit: _toDouble(map['estimated_profit']),
      estimatedMarginPercent: _toDouble(map['estimated_margin_percent']),
      notes: map['notes'] as String?,
      validUntil: map['valid_until'] == null
          ? null
          : DateTime.parse(map['valid_until'] as String),
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: map['archived_at'] == null
          ? null
          : DateTime.parse(map['archived_at'] as String),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  static String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
