class Project {
  const Project({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.projectName,
    required this.projectNumber,
    required this.status,
    required this.priority,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    required this.country,
    required this.contractAmount,
    required this.estimatedCost,
    required this.actualCost,
    required this.estimatedProfit,
    required this.actualProfit,
    this.notes,
  });

  final String id;
  final String companyId;
  final String customerId;
  final String projectName;
  final String projectNumber;
  final String status;
  final String priority;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final double contractAmount;
  final double estimatedCost;
  final double actualCost;
  final double estimatedProfit;
  final double actualProfit;
  final String? notes;

  String get displayLocation {
    final cityState = [
      city,
      state,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');

    if (cityState.isNotEmpty) {
      return cityState;
    }

    if (addressLine1 != null && addressLine1!.trim().isNotEmpty) {
      return addressLine1!;
    }

    return 'No location';
  }

  String get statusLabel {
    String label;

    switch (status) {
      case 'contract':
        label = 'Contract';
        break;
      case 'ordered_material':
        label = 'Ordered Material';
        break;
      case 'structure_fabrication':
        label = 'Structure Fabrication';
        break;
      case 'powder_coating':
        label = 'Powder Coating';
        break;
      case 'footers':
        label = 'Footers';
        break;
      case 'sail_fabrication':
        label = 'Sail Fabrication';
        break;
      case 'installation':
        label = 'Installation';
        break;
      case 'final_invoice':
        label = 'Final Invoice';
        break;
      case 'completed':
        label = 'Completed';
        break;
      default:
        label = status;
        break;
    }

    return label.toUpperCase();
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      customerId: map['customer_id'] as String,
      projectName: map['name'] as String,
      projectNumber: map['project_number'] as String,
      status: map['status'] as String? ?? 'scheduled',
      priority: map['priority'] as String? ?? 'normal',
      addressLine1: map['address_line_1'] as String?,
      addressLine2: map['address_line_2'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postal_code'] as String?,
      country: map['country'] as String? ?? 'USA',
      contractAmount: _toDouble(map['contract_amount']),
      estimatedCost: _toDouble(map['estimated_cost']),
      actualCost: _toDouble(map['actual_cost']),
      estimatedProfit: _toDouble(map['estimated_profit']),
      actualProfit: _toDouble(map['actual_profit']),
      notes: map['notes'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
