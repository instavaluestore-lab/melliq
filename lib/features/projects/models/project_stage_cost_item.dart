class ProjectStageCostItem {
  const ProjectStageCostItem({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.stageCostId,
    required this.itemType,
    this.description,
    required this.estimatedCost,
    required this.actualCost,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String stageCostId;
  final String itemType;
  final String? description;
  final double estimatedCost;
  final double actualCost;

  factory ProjectStageCostItem.fromMap(Map<String, dynamic> map) {
    return ProjectStageCostItem(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      stageCostId: map['stage_cost_id'] as String,
      itemType: map['item_type'] as String? ?? 'additional_actual',
      description: map['description'] as String?,
      estimatedCost: _toDouble(map['estimated_cost']),
      actualCost: _toDouble(map['actual_cost']),
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
