class QuoteLineItem {
  const QuoteLineItem({
    required this.id,
    required this.companyId,
    required this.quoteId,
    required this.itemType,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.unitPrice,
    required this.totalCost,
    required this.totalPrice,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String companyId;
  final String quoteId;
  final String itemType;
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double unitCost;
  final double unitPrice;
  final double totalCost;
  final double totalPrice;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get itemTypeLabel {
    return switch (itemType) {
      'labor' => 'Labor',
      'material' => 'Material',
      'equipment' => 'Equipment',
      'subcontractor' => 'Subcontractor',
      'other' => 'Other',
      _ => _titleCase(itemType),
    };
  }

  factory QuoteLineItem.fromMap(Map<String, dynamic> map) {
    return QuoteLineItem(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      quoteId: map['quote_id'] as String,
      itemType: map['item_type'] as String? ?? 'material',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      quantity: _toDouble(map['quantity']),
      unit: map['unit'] as String? ?? 'each',
      unitCost: _toDouble(map['unit_cost']),
      unitPrice: _toDouble(map['unit_price']),
      totalCost: _toDouble(map['total_cost']),
      totalPrice: _toDouble(map['total_price']),
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
