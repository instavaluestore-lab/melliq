class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.createdBy,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDone => status == 'done';

  bool get isOverdue {
    if (dueDate == null || isDone) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDueDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    return taskDueDate.isBefore(today);
  }

  String get statusLabel {
    switch (status) {
      case 'todo':
        return 'TO DO';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'done':
        return 'DONE';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'LOW';
      case 'normal':
        return 'NORMAL';
      case 'high':
        return 'HIGH';
      case 'urgent':
        return 'URGENT';
      default:
        return priority.toUpperCase();
    }
  }

  String get dueDateLabel {
    if (dueDate == null) return 'No due date';

    final month = dueDate!.month.toString().padLeft(2, '0');
    final day = dueDate!.day.toString().padLeft(2, '0');
    final year = dueDate!.year.toString();

    return '$month/$day/$year';
  }

  factory ProjectTask.fromMap(Map<String, dynamic> map) {
    return ProjectTask(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'todo',
      priority: map['priority'] as String? ?? 'normal',
      assignedTo: map['assigned_to'] as String?,
      createdBy: map['created_by'] as String?,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
