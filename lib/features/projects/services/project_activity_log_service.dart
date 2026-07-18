import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_activity_log.dart';

class ProjectActivityLogService {
  ProjectActivityLogService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProjectActivityLog>> getProjectActivityLogs({
    required String projectId,
  }) async {
    final response = await _supabase
        .from('project_activity_logs')
        .select('''
          id,
          company_id,
          project_id,
          activity_type,
          title,
          body,
          created_by,
          created_at
        ''')
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .limit(30);

    final logs = List<Map<String, dynamic>>.from(response);

    if (logs.isEmpty) {
      return const [];
    }

    final creatorIds = logs
        .map((log) => log['created_by'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final profilesByUserId = <String, Map<String, dynamic>>{};

    if (creatorIds.isNotEmpty) {
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', creatorIds);

      for (final profile in profilesResponse) {
        profilesByUserId[profile['id'] as String] =
            Map<String, dynamic>.from(profile);
      }
    }

    return logs.map<ProjectActivityLog>((log) {
      final creatorId = log['created_by'] as String?;
      final profile =
          creatorId == null ? null : profilesByUserId[creatorId];
      final logMap = Map<String, dynamic>.from(log);

      if (profile != null) {
        logMap['profiles'] = profile;
      }

      return ProjectActivityLog.fromMap(logMap);
    }).toList();
  }

  Future<ProjectActivityLog> createProjectActivityLog({
    required String companyId,
    required String projectId,
    required String activityType,
    required String title,
    String? body,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final response = await _supabase
        .from('project_activity_logs')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'activity_type': activityType,
          'title': title.trim(),
          'body': _emptyToNull(body),
          'created_by': userId,
        })
        .select('''
          id,
          company_id,
          project_id,
          activity_type,
          title,
          body,
          created_by,
          created_at
        ''')
        .single();

    Map<String, dynamic>? profileResponse;

    if (userId != null) {
      profileResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email')
          .eq('id', userId)
          .maybeSingle();
    }

    final logMap = Map<String, dynamic>.from(response);

    if (profileResponse != null) {
      logMap['profiles'] = profileResponse;
    }

    return ProjectActivityLog.fromMap(logMap);
  }

  Future<void> deleteProjectActivityLog(String activityLogId) async {
    await _supabase
        .from('project_activity_logs')
        .delete()
        .eq('id', activityLogId);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }
}
