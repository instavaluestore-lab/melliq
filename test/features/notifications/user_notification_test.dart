import 'package:flutter_test/flutter_test.dart';
import 'package:lupinusbuild/features/notifications/models/user_notification.dart';

void main() {
  group('UserNotification', () {
    test('parses an unread task reassignment', () {
      final notification = UserNotification.fromMap({
        'id': 'notification-1',
        'company_id': 'company-1',
        'user_id': 'user-1',
        'notification_type': 'task_reassigned',
        'title': 'Task assigned: Confirm site measurements',
        'body': 'Due date: 07/19/2026',
        'project_id': 'project-1',
        'task_id': 'task-1',
        'actor_user_id': 'actor-1',
        'read_at': null,
        'created_at': '2026-08-18T02:42:44.133830+00:00',
      });

      expect(notification.id, 'notification-1');
      expect(notification.projectId, 'project-1');
      expect(notification.taskId, 'task-1');
      expect(notification.isUnread, isTrue);
      expect(notification.notificationTypeLabel, 'Task Reassigned');
    });

    test('parses a read notification', () {
      final notification = UserNotification.fromMap({
        'id': 'notification-2',
        'company_id': 'company-1',
        'user_id': 'user-1',
        'notification_type': 'task_assigned',
        'title': 'Task assigned: Site inspection',
        'body': null,
        'project_id': 'project-2',
        'task_id': 'task-2',
        'actor_user_id': null,
        'read_at': '2026-08-18T03:00:00.000000+00:00',
        'created_at': '2026-08-18T02:55:00.000000+00:00',
      });

      expect(notification.isUnread, isFalse);
      expect(notification.notificationTypeLabel, 'Task Assigned');
      expect(notification.readAt, isNotNull);
    });

    test('provides a fallback label for future notification types', () {
      final notification = UserNotification.fromMap({
        'id': 'notification-3',
        'company_id': 'company-1',
        'user_id': 'user-1',
        'notification_type': 'project_updated',
        'title': 'Project updated',
        'created_at': '2026-08-18T03:00:00.000000+00:00',
      });

      expect(notification.notificationTypeLabel, 'PROJECT UPDATED');
    });
  });
}
