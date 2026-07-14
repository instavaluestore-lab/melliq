class ProjectStageCost {
  const ProjectStageCost({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.stage,
    required this.lineType,
    this.description,
    required this.estimatedCost,
    required this.actualCost,
    this.notes,
    required this.isCompleted,
    required this.peopleCount,
    required this.hoursEach,
    required this.costPerHour,
    required this.flatFee,
    required this.useFlatFee,
    required this.concreteBagCount,
    required this.concreteBagCost,
    required this.concreteUnitType,
    required this.rebarStickCount,
    required this.rebarStickCost,
    required this.anchorBoltCount,
    required this.anchorBoltCost,
    required this.fabricYards,
    required this.fabricCostPerYard,
    required this.hardwareCount,
    required this.hardwareCostEach,
    required this.cableFeet,
    required this.cableCostPerFoot,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String stage;
  final String lineType;
  final String? description;
  final double estimatedCost;
  final double actualCost;
  final String? notes;
  final bool isCompleted;

  final int peopleCount;
  final double hoursEach;
  final double costPerHour;
  final double flatFee;
  final bool useFlatFee;

  final int concreteBagCount;
  final double concreteBagCost;
  final String concreteUnitType;
  final int rebarStickCount;
  final double rebarStickCost;

  final int anchorBoltCount;
  final double anchorBoltCost;

  final double fabricYards;
  final double fabricCostPerYard;
  final int hardwareCount;
  final double hardwareCostEach;
  final double cableFeet;
  final double cableCostPerFoot;

  bool get isMiscellaneous {
    return lineType == 'miscellaneous' || stage == 'miscellaneous';
  }

  bool get isMilestoneOnly {
    return stage == 'contract' ||
        stage == 'final_invoice' ||
        stage == 'completed';
  }

  bool get usesLaborFormula {
    return stage == 'structure_fabrication' ||
        stage == 'sail_fabrication' ||
        stage == 'installation';
  }

  bool get isFooters {
    return stage == 'footers';
  }

  String get stageLabel {
    if (isMiscellaneous) {
      return description?.trim().isNotEmpty == true
          ? description!
          : 'Miscellaneous Expense';
    }

    switch (stage) {
      case 'contract':
        return 'Contract';
      case 'ordered_material':
        return 'Ordered Material';
      case 'structure_fabrication':
        return 'Structure Fabrication';
      case 'powder_coating':
        return 'Powder Coating';
      case 'equipment':
        return 'Equipment';
      case 'footers':
        return 'Footers';
      case 'sail_fabrication':
        return 'Sail Fabrication';
      case 'installation':
        return 'Installation';
      case 'final_invoice':
        return 'Final Invoice';
      case 'completed':
        return 'Completed';
      default:
        return stage;
    }
  }

  String get concreteUnitLabel {
    return concreteUnitType == 'pallet' ? 'pallet' : 'bag';
  }

  String get concreteUnitPluralLabel {
    return concreteUnitType == 'pallet' ? 'pallets' : 'bags';
  }

  double get calculatedLaborCost {
    if (useFlatFee) {
      return flatFee;
    }

    return peopleCount * hoursEach * costPerHour;
  }

  double get footerMaterialCost {
    if (!isFooters || useFlatFee) {
      return 0;
    }

    final concreteCost = concreteBagCount * concreteBagCost;
    final rebarCost = rebarStickCount * rebarStickCost;
    final anchorCost = anchorBoltCount * anchorBoltCost;

    return concreteCost + rebarCost + anchorCost;
  }

  double get sailMaterialCost {
    if (stage != 'sail_fabrication') {
      return 0;
    }

    final fabricCost = fabricYards * fabricCostPerYard;
    final hardwareCost = hardwareCount * hardwareCostEach;
    final cableCost = cableFeet * cableCostPerFoot;

    return fabricCost + hardwareCost + cableCost;
  }

  double get calculatedCost {
    if (isMilestoneOnly) {
      return 0;
    }

    if (isFooters) {
      if (useFlatFee) {
        return flatFee;
      }

      return calculatedLaborCost + footerMaterialCost;
    }

    if (stage == 'sail_fabrication') {
      return calculatedLaborCost + sailMaterialCost;
    }

    if (usesLaborFormula) {
      return calculatedLaborCost;
    }

    return estimatedCost;
  }

  factory ProjectStageCost.fromMap(Map<String, dynamic> map) {
    return ProjectStageCost(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      stage: map['stage'] as String,
      lineType: map['line_type'] as String? ?? 'stage',
      description: map['description'] as String?,
      estimatedCost: _toDouble(map['estimated_cost']),
      actualCost: _toDouble(map['actual_cost']),
      notes: map['notes'] as String?,
      isCompleted: map['is_completed'] as bool? ?? false,
      peopleCount: _toInt(map['people_count']),
      hoursEach: _toDouble(map['hours_each']),
      costPerHour: _toDouble(map['cost_per_hour']),
      flatFee: _toDouble(map['flat_fee']),
      useFlatFee: map['use_flat_fee'] as bool? ?? false,
      concreteBagCount: _toInt(map['concrete_bag_count']),
      concreteBagCost: _toDouble(map['concrete_bag_cost']),
      concreteUnitType: map['concrete_unit_type'] as String? ?? 'bag',
      rebarStickCount: _toInt(map['rebar_stick_count']),
      rebarStickCost: _toDouble(map['rebar_stick_cost']),
      anchorBoltCount: _toInt(map['anchor_bolt_count']),
      anchorBoltCost: _toDouble(map['anchor_bolt_cost']),
      fabricYards: _toDouble(map['fabric_yards']),
      fabricCostPerYard: _toDouble(map['fabric_cost_per_yard']),
      hardwareCount: _toInt(map['hardware_count']),
      hardwareCostEach: _toDouble(map['hardware_cost_each']),
      cableFeet: _toDouble(map['cable_feet']),
      cableCostPerFoot: _toDouble(map['cable_cost_per_foot']),
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

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}
