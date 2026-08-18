import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_notification.dart';

class UserNotificationService {
  UserNotificationService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<UserNotification>> getNotifications({
    required String companyId,
  }) async {
    final rows = await _supabase
        .from('user_notifications')
        .select('''
          id,
          company_id,
          user_id,
          notification_type,
          title,
          body,
          project_id,
          task_id,
          actor_user_id,
          read_at,
          created_at
        ''')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return rows.map<UserNotification>(UserNotification.fromMap).toList();
  }

  Future<int> getUnreadCount({required String companyId}) async {
    final rows = await _supabase
        .from('user_notifications')
        .select('id')
        .eq('company_id', companyId)
        .isFilter('read_at', null);

    return rows.length;
  }

  Future<void> markRead(String notificationId) async {
    await _supabase
        .from('user_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .isFilter('read_at', null);
  }

  Future<void> markAllRead({required String companyId}) async {
    await _supabase
        .from('user_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('company_id', companyId)
        .isFilter('read_at', null);
  }
}
