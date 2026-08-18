import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/company_task.dart';
import '../screens/project_detail_screen.dart';
import '../services/project_service.dart';
import '../services/project_task_service.dart';

class CompanyTasksScreen extends StatefulWidget {
  const CompanyTasksScreen({super.key, required this.companyContext});

  final CompanyContext companyContext;

  @override
  State<CompanyTasksScreen> createState() => _CompanyTasksScreenState();
}

class _CompanyTasksScreenState extends State<CompanyTasksScreen> {
  late final ProjectTaskService taskService;
  late final ProjectService projectService;
  final searchController = TextEditingController();

  bool isLoading = true;
  String? openingTaskId;
  String? errorMessage;
  List<CompanyTask> tasks = [];

  @override
  void initState() {
    super.initState();
    taskService = ProjectTaskService(Supabase.instance.client);
    projectService = ProjectService(Supabase.instance.client);
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<CompanyTask> get filteredTasks {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return List<CompanyTask>.from(tasks);
    }

    return tasks.where((companyTask) {
      final task = companyTask.task;

      return task.title.toLowerCase().contains(query) ||
          (task.description?.toLowerCase().contains(query) ?? false) ||
          companyTask.projectName.toLowerCase().contains(query) ||
          companyTask.projectNumber.toLowerCase().contains(query) ||
          companyTask.assigneeLabel.toLowerCase().contains(query);
    }).toList();
  }

  List<CompanyTask> get openTasks {
    final values = filteredTasks
        .where((companyTask) => !companyTask.task.isDone)
        .toList();

    values.sort(compareOpenTasks);
    return values;
  }

  List<CompanyTask> get completedTasks {
    final values = filteredTasks
        .where((companyTask) => companyTask.task.isDone)
        .toList();

    values.sort((first, second) {
      final firstDate = first.task.completedAt ?? first.task.updatedAt;
      final secondDate = second.task.completedAt ?? second.task.updatedAt;

      return secondDate.compareTo(firstDate);
    });

    return values;
  }

  int compareOpenTasks(CompanyTask first, CompanyTask second) {
    final firstTask = first.task;
    final secondTask = second.task;

    if (firstTask.isOverdue != secondTask.isOverdue) {
      return firstTask.isOverdue ? -1 : 1;
    }

    final priorityComparison = priorityRank(
      firstTask.priority,
    ).compareTo(priorityRank(secondTask.priority));

    if (priorityComparison != 0) return priorityComparison;

    final firstDueDate = firstTask.dueDate;
    final secondDueDate = secondTask.dueDate;

    if (firstDueDate == null && secondDueDate != null) return 1;
    if (firstDueDate != null && secondDueDate == null) return -1;

    if (firstDueDate != null && secondDueDate != null) {
      final dueDateComparison = firstDueDate.compareTo(secondDueDate);
      if (dueDateComparison != 0) return dueDateComparison;
    }

    return firstTask.title.compareTo(secondTask.title);
  }

  int priorityRank(String priority) {
    return switch (priority) {
      'urgent' => 0,
      'high' => 1,
      'normal' => 2,
      'low' => 3,
      _ => 4,
    };
  }

  Future<void> loadTasks() async {
    if (!widget.companyContext.canViewCompanyTasks) {
      setState(() {
        errorMessage = 'You do not have permission to view all company tasks.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedTasks = await taskService.getCompanyTasks(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        tasks = loadedTasks;
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

  Future<void> openTask(CompanyTask companyTask) async {
    if (openingTaskId != null) return;

    setState(() {
      openingTaskId = companyTask.task.id;
      errorMessage = null;
    });

    try {
      final project = await projectService.getProjectById(
        companyTask.task.projectId,
      );

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

      await loadTasks();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          openingTaskId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Company Task Center',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review open and completed tasks across every project.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search tasks',
                hintText: 'Task, project, number, or assignee',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            if (errorMessage != null) ...[
              _TaskCenterError(message: errorMessage!),
              const SizedBox(height: 16),
            ],
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 90),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _TaskSection(
                title: 'Open Tasks',
                subtitle:
                    '${openTasks.length} task${openTasks.length == 1 ? '' : 's'} requiring attention',
                icon: Icons.pending_actions_outlined,
                iconColor: const Color(0xFFDC2626),
                tasks: openTasks,
                openingTaskId: openingTaskId,
                emptyMessage: searchController.text.trim().isEmpty
                    ? 'No open tasks.'
                    : 'No open tasks match your search.',
                onOpenTask: openTask,
              ),
              const SizedBox(height: 18),
              _TaskSection(
                title: 'Completed Tasks',
                subtitle:
                    '${completedTasks.length} completed task${completedTasks.length == 1 ? '' : 's'}',
                icon: Icons.task_alt_outlined,
                iconColor: const Color(0xFF16A34A),
                tasks: completedTasks,
                openingTaskId: openingTaskId,
                emptyMessage: searchController.text.trim().isEmpty
                    ? 'No completed tasks.'
                    : 'No completed tasks match your search.',
                onOpenTask: openTask,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.openingTaskId,
    required this.emptyMessage,
    required this.onOpenTask,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<CompanyTask> tasks;
  final String? openingTaskId;
  final String emptyMessage;
  final ValueChanged<CompanyTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ...tasks.asMap().entries.map((entry) {
                final companyTask = entry.value;

                return Column(
                  children: [
                    if (entry.key > 0) const Divider(height: 24),
                    _CompanyTaskRow(
                      companyTask: companyTask,
                      isOpening: openingTaskId == companyTask.task.id,
                      onTap: () => onOpenTask(companyTask),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CompanyTaskRow extends StatelessWidget {
  const _CompanyTaskRow({
    required this.companyTask,
    required this.isOpening,
    required this.onTap,
  });

  final CompanyTask companyTask;
  final bool isOpening;
  final VoidCallback onTap;

  Color priorityColor(String priority) {
    return switch (priority) {
      'urgent' => const Color(0xFFDC2626),
      'high' => const Color(0xFFEA580C),
      'low' => const Color(0xFF64748B),
      _ => const Color(0xFF2563EB),
    };
  }

  @override
  Widget build(BuildContext context) {
    final task = companyTask.task;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isOpening ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              task.isDone
                  ? Icons.check_circle_outline
                  : task.isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.radio_button_unchecked,
              color: task.isDone
                  ? const Color(0xFF16A34A)
                  : task.isOverdue
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${companyTask.projectNumber} • '
                    '${companyTask.projectName}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Assigned to: ${companyTask.assigneeLabel}',
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TaskBadge(
                        label: task.statusLabel,
                        color: task.isDone
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                      ),
                      _TaskBadge(
                        label: task.priorityLabel,
                        color: priorityColor(task.priority),
                      ),
                      _TaskBadge(
                        label: task.isOverdue
                            ? 'OVERDUE: ${task.dueDateLabel}'
                            : 'DUE: ${task.dueDateLabel}',
                        color: task.isOverdue
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isOpening)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TaskCenterError extends StatelessWidget {
  const _TaskCenterError({required this.message});

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
