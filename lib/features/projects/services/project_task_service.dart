import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_task.dart';
import '../models/project_task_assignee.dart';

class ProjectTaskService {
  ProjectTaskService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProjectTaskAssignee>> getAssignableMembers({
    required String companyId,
  }) async {
    final rows = await _supabase
        .from('company_members')
        .select('user_id, role, status, profiles(full_name, email)')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .order('created_at', ascending: true);

    return rows.map<ProjectTaskAssignee>(ProjectTaskAssignee.fromMap).toList();
  }

  Future<List<ProjectTask>> getTasksForProject({
    required String companyId,
    required String projectId,
  }) async {
    final rows = await _supabase
        .from('project_tasks')
        .select()
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .order('status', ascending: true)
        .order('due_date', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return rows
        .map<ProjectTask>(
          ProjectTask.fromMap,
        )
        .toList();
  }

  Future<ProjectTask> createTask({
    required String companyId,
    required String projectId,
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'normal',
    String? assignedTo,
    DateTime? dueDate,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_by': currentUserId,
      'due_date': dueDate?.toIso8601String().split('T').first,
    };

    final row = await _supabase
        .from('project_tasks')
        .insert(payload)
        .select()
        .single();

    return ProjectTask.fromMap(row);
  }

  Future<ProjectTask> updateTask({
    required String taskId,
    required String title,
    String? description,
    required String status,
    required String priority,
    String? assignedTo,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'completed_at': status == 'done' ? now : null,
      'updated_at': now,
    };

    final row = await _supabase
        .from('project_tasks')
        .update(payload)
        .eq('id', taskId)
        .select()
        .single();

    return ProjectTask.fromMap(row);
  }

  Future<ProjectTask> markTaskDone(String taskId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final row = await _supabase
        .from('project_tasks')
        .update({
          'status': 'done',
          'completed_at': now,
          'updated_at': now,
        })
        .eq('id', taskId)
        .select()
        .single();

    return ProjectTask.fromMap(row);
  }

  Future<ProjectTask> reopenTask(String taskId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final row = await _supabase
        .from('project_tasks')
        .update({
          'status': 'todo',
          'completed_at': null,
          'updated_at': now,
        })
        .eq('id', taskId)
        .select()
        .single();

    return ProjectTask.fromMap(row);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('project_tasks').delete().eq('id', taskId);
  }
}
