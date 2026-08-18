import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/project_service.dart';
import '../models/user_notification.dart';
import '../services/user_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.companyContext});

  final CompanyContext companyContext;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final UserNotificationService notificationService;
  late final ProjectService projectService;

  bool isLoading = true;
  bool isMarkingAllRead = false;
  String? openingNotificationId;
  String? errorMessage;
  List<UserNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    notificationService = UserNotificationService(Supabase.instance.client);
    projectService = ProjectService(Supabase.instance.client);
    loadNotifications();
  }

  int get unreadCount {
    return notifications.where((notification) => notification.isUnread).length;
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedNotifications = await notificationService.getNotifications(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> markAllRead() async {
    if (isMarkingAllRead || unreadCount == 0) return;

    setState(() {
      isMarkingAllRead = true;
      errorMessage = null;
    });

    try {
      await notificationService.markAllRead(
        companyId: widget.companyContext.companyId,
      );
      await loadNotifications();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isMarkingAllRead = false;
        });
      }
    }
  }

  Future<void> openNotification(UserNotification notification) async {
    if (openingNotificationId != null) return;

    setState(() {
      openingNotificationId = notification.id;
      errorMessage = null;
    });

    try {
      if (notification.isUnread) {
        await notificationService.markRead(notification.id);
      }

      final projectId = notification.projectId;
      if (projectId == null) {
        throw StateError('This notification is not linked to a project.');
      }

      final project = await projectService.getProjectById(projectId);

      if (project.companyId != widget.companyContext.companyId) {
        throw StateError('This project is outside your current workspace.');
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            companyContext: widget.companyContext,
            project: project,
          ),
        ),
      );

      await loadNotifications();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          openingNotificationId = null;
        });
      }
    }
  }

  String formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.month}/${local.day}/${local.year} • '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: isMarkingAllRead ? null : markAllRead,
              icon: isMarkingAllRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all),
              label: const Text('Mark All Read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Task Notifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Chip(
                    avatar: const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                    ),
                    label: Text('$unreadCount unread'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Assignments and project tasks that need your attention.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null) ...[
              _NotificationError(message: errorMessage!),
              const SizedBox(height: 16),
            ],
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notifications.isEmpty)
              const _EmptyNotifications()
            else
              ...notifications.map((notification) {
                final isOpening = openingNotificationId == notification.id;

                return Card(
                  elevation: 0,
                  color: notification.isUnread
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: notification.isUnread
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isOpening
                        ? null
                        : () => openNotification(notification),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: notification.isUnread
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assignment_ind_outlined,
                              color: notification.isUnread
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          color: const Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: notification.isUnread
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (notification.isUnread)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notification.notificationTypeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (notification.body?.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 7),
                                  Text(
                                    notification.body!.trim(),
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 9),
                                Text(
                                  formatTimestamp(notification.createdAt),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (isOpening)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.open_in_new,
                                        size: 17,
                                        color: Color(0xFF2563EB),
                                      ),
                                    const SizedBox(width: 7),
                                    Text(
                                      isOpening
                                          ? 'Opening project...'
                                          : 'Open Project',
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'New task assignments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
