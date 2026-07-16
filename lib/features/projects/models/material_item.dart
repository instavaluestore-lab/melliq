class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.companyId,
    this.projectId,
    required this.name,
    this.category,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
    this.supplier,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String? projectId;
  final String name;
  final String? category;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final String? supplier;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get statusLabel {
    switch (status) {
      case 'needed':
        return 'NEEDED';
      case 'ordered':
        return 'ORDERED';
      case 'received':
        return 'RECEIVED';
      case 'installed':
        return 'INSTALLED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get categoryLabel {
    final value = category?.trim();

    if (value == null || value.isEmpty) {
      return 'UNCATEGORIZED';
    }

    return value.replaceAll('_', ' ').toUpperCase();
  }

  String get quantityLabel {
    final quantityText = quantity % 1 == 0
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);

    return '$quantityText $unit';
  }

  String get unitCostLabel {
    return '\$${unitCost.toStringAsFixed(2)} / $unit';
  }

  String get totalCostLabel {
    return '\$${totalCost.toStringAsFixed(2)}';
  }

  bool get isComplete => status == 'installed';

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String?,
      name: map['name'] as String,
      category: map['category'] as String?,
      quantity: double.tryParse(map['quantity'].toString()) ?? 0,
      unit: map['unit'] as String? ?? 'each',
      unitCost: double.tryParse(map['unit_cost'].toString()) ?? 0,
      totalCost: double.tryParse(map['total_cost'].toString()) ?? 0,
      supplier: map['supplier'] as String?,
      status: map['status'] as String? ?? 'needed',
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
