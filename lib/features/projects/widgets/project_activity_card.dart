import 'package:flutter/material.dart';

import '../models/project_activity_log.dart';

class ProjectActivityCard extends StatelessWidget {
  const ProjectActivityCard({
    super.key,
    required this.activityLogs,
    required this.enabled,
    required this.canDeleteActivity,
    required this.onDeleteActivity,
  });

  final List<ProjectActivityLog> activityLogs;
  final bool enabled;
  final bool canDeleteActivity;
  final Future<void> Function(ProjectActivityLog activityLog) onDeleteActivity;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Project Activity Timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Automatic project history for status changes, materials, tasks, notes, files, and key updates.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (activityLogs.isEmpty)
            const Text(
              'No activity has been recorded yet.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...activityLogs.map(
              (activityLog) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTile(
                  activityLog: activityLog,
                  enabled: enabled,
                  canDelete: canDeleteActivity,
                  onDelete: () => onDeleteActivity(activityLog),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activityLog,
    required this.enabled,
    required this.canDelete,
    required this.onDelete,
  });

  final ProjectActivityLog activityLog;
  final bool enabled;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _activityColor(activityLog.activityType);
    final background = _activityBackground(activityLog.activityType);
    final icon = _activityIcon(activityLog.activityType);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ActivityChip(
                      label: activityLog.activityTypeLabel,
                      backgroundColor: background,
                      textColor: color,
                    ),
                    Text(
                      activityLog.creatorLabel,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activityLog.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (activityLog.body?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    activityLog.body!,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(activityLog.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: enabled && canDelete ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete activity',
          ),
        ],
      ),
    );
  }

  Color _activityColor(String activityType) {
    return switch (activityType) {
      'status_changed' => const Color(0xFF1D4ED8),
      'material_created' => const Color(0xFF047857),
      'material_status_changed' => const Color(0xFF15803D),
      'task_created' => const Color(0xFF4338CA),
      'task_completed' => const Color(0xFF166534),
      'task_reopened' => const Color(0xFFC2410C),
      'task_deleted' => const Color(0xFFB91C1C),
      'note_created' => const Color(0xFF0E7490),
      'note_deleted' => const Color(0xFFB91C1C),
      'file_uploaded' => const Color(0xFF2563EB),
      'file_deleted' => const Color(0xFFB91C1C),
      _ => const Color(0xFF334155),
    };
  }

  Color _activityBackground(String activityType) {
    return switch (activityType) {
      'status_changed' => const Color(0xFFDBEAFE),
      'material_created' => const Color(0xFFECFDF5),
      'material_status_changed' => const Color(0xFFF0FDF4),
      'task_created' => const Color(0xFFEEF2FF),
      'task_completed' => const Color(0xFFF0FDF4),
      'task_reopened' => const Color(0xFFFFF7ED),
      'task_deleted' => const Color(0xFFFEE2E2),
      'note_created' => const Color(0xFFECFEFF),
      'note_deleted' => const Color(0xFFFEE2E2),
      'file_uploaded' => const Color(0xFFEFF6FF),
      'file_deleted' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFF8FAFC),
    };
  }

  IconData _activityIcon(String activityType) {
    return switch (activityType) {
      'status_changed' => Icons.swap_horiz_outlined,
      'material_created' => Icons.inventory_2_outlined,
      'material_status_changed' => Icons.check_circle_outline,
      'task_created' => Icons.add_task_outlined,
      'task_completed' => Icons.task_alt_outlined,
      'task_reopened' => Icons.refresh_outlined,
      'task_deleted' => Icons.delete_outline,
      'note_created' => Icons.sticky_note_2_outlined,
      'note_deleted' => Icons.note_alt_outlined,
      'file_uploaded' => Icons.upload_file_outlined,
      'file_deleted' => Icons.file_present_outlined,
      _ => Icons.history_outlined,
    };
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';

    return '$month/$day/$year $hour:$minute $suffix';
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
