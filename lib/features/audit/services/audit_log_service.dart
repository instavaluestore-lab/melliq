import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/record_audit_log.dart';

class AuditLogService {
  AuditLogService(this._supabase);

  final SupabaseClient _supabase;

  Future<void> logAction({
    required String companyId,
    required String recordType,
    required String recordId,
    required String action,
    required String summary,
    String? fieldName,
    String? oldValue,
    String? newValue,
    Map<String, dynamic> metadata = const {},
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('record_audit_logs').insert({
      'company_id': companyId,
      'record_type': recordType,
      'record_id': recordId,
      'action': action,
      'field_name': fieldName,
      'old_value': oldValue,
      'new_value': newValue,
      'summary': summary,
      'created_by': userId,
      'metadata': metadata,
    });
  }

  Future<List<RecordAuditLog>> getLogsForRecord({
    required String recordType,
    required String recordId,
    int limit = 50,
  }) async {
    final rows = await _supabase
        .from('record_audit_logs')
        .select()
        .eq('record_type', recordType)
        .eq('record_id', recordId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map<RecordAuditLog>(
          (row) => RecordAuditLog.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<RecordAuditLog>> getRecentLogsForCompany({
    required String companyId,
    int limit = 50,
  }) async {
    final rows = await _supabase
        .from('record_audit_logs')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map<RecordAuditLog>(
          (row) => RecordAuditLog.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}
