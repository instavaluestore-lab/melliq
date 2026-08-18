import 'project_task.dart';

class CompanyTask {
  const CompanyTask({
    required this.task,
    required this.projectNumber,
    required this.projectName,
    this.assigneeName,
    this.assigneeEmail,
  });

  final ProjectTask task;
  final String projectNumber;
  final String projectName;
  final String? assigneeName;
  final String? assigneeEmail;

  String get assigneeLabel {
    final name = assigneeName?.trim();
    final email = assigneeEmail?.trim();

    if (name != null && name.isNotEmpty) return name;
    if (email != null && email.isNotEmpty) return email;

    return 'Unassigned';
  }

  factory CompanyTask.fromMap(Map<String, dynamic> map) {
    final project = Map<String, dynamic>.from(map['projects'] as Map);
    final profileValue = map['profiles'];
    final profile = profileValue == null
        ? null
        : Map<String, dynamic>.from(profileValue as Map);

    return CompanyTask(
      task: ProjectTask.fromMap(map),
      projectNumber: project['project_number'] as String,
      projectName: project['name'] as String,
      assigneeName: profile?['full_name'] as String?,
      assigneeEmail: profile?['email'] as String?,
    );
  }
}
