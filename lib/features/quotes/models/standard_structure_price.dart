class StandardStructurePrice {
  const StandardStructurePrice({
    required this.id,
    required this.structureType,
    required this.structureName,
    required this.sizeLabel,
    required this.widthFeet,
    required this.lengthFeet,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.companyId,
  });

  final String id;
  final String? companyId;
  final String structureType;
  final String structureName;
  final String sizeLabel;
  final double widthFeet;
  final double lengthFeet;
  final double price;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get sizeOnlyLabel =>
      '$lengthFeetFormatted ft × $widthFeetFormatted ft';

  String get displayLabel => '$sizeOnlyLabel — \$${price.toStringAsFixed(2)}';

  String get quoteLineName =>
      '$structureName $lengthFeetFormatted ft × $widthFeetFormatted ft';

  String get lengthFeetFormatted => _formatNumber(lengthFeet);

  String get widthFeetFormatted => _formatNumber(widthFeet);

  factory StandardStructurePrice.fromMap(Map<String, dynamic> map) {
    return StandardStructurePrice(
      id: map['id'] as String,
      companyId: map['company_id'] as String?,
      structureType: map['structure_type'] as String? ?? '',
      structureName: map['structure_name'] as String? ?? '',
      sizeLabel: map['size_label'] as String? ?? '',
      widthFeet: _toDouble(map['width_feet']),
      lengthFeet: _toDouble(map['length_feet']),
      price: _toDouble(map['price']),
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

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}
