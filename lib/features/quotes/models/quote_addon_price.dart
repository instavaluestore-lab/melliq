class QuoteAddonPrice {
  const QuoteAddonPrice({
    required this.id,
    required this.addonKey,
    required this.addonName,
    required this.addonType,
    required this.unit,
    required this.unitPrice,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.companyId,
  });

  final String id;
  final String? companyId;
  final String addonKey;
  final String addonName;
  final String addonType;
  final String unit;
  final double unitPrice;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QuoteAddonPrice.fromMap(Map<String, dynamic> map) {
    return QuoteAddonPrice(
      id: map['id'] as String,
      companyId: map['company_id'] as String?,
      addonKey: map['addon_key'] as String? ?? '',
      addonName: map['addon_name'] as String? ?? '',
      addonType: map['addon_type'] as String? ?? '',
      unit: map['unit'] as String? ?? 'each',
      unitPrice: _toDouble(map['unit_price']),
      isActive: map['is_active'] as bool? ?? true,
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
}
