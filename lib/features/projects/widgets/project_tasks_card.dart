import 'package:flutter/material.dart';

import '../models/project_task.dart';

class ProjectTasksCard extends StatelessWidget {
  const ProjectTasksCard({
    super.key,
    required this.tasks,
    required this.enabled,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final List<ProjectTask> tasks;
  final bool enabled;
  final VoidCallback onAddTask;
  final ValueChanged<ProjectTask> onToggleTask;
  final ValueChanged<ProjectTask> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final openTasks = tasks.where((task) => !task.isDone).length;
    final doneTasks = tasks.where((task) => task.isDone).length;
    final overdueTasks = tasks.where((task) => task.isOverdue).length;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Project Tasks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TaskMetricPill(label: 'Open', value: openTasks.toString()),
                _TaskMetricPill(label: 'Done', value: doneTasks.toString()),
                _TaskMetricPill(
                  label: 'Overdue',
                  value: overdueTasks.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enabled ? onAddTask : null,
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Add Task'),
              ),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              const Text(
                'No tasks yet. Add the first task for this project.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.45,
                ),
              )
            else
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProjectTaskTile(
                    task: task,
                    enabled: enabled,
                    onToggle: () => onToggleTask(task),
                    onDelete: () => onDeleteTask(task),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddProjectTaskDialog extends StatefulWidget {
  const AddProjectTaskDialog({
    super.key,
    required this.onSave,
  });

  final Future<ProjectTask> Function({
    required String title,
    required String description,
    required String priority,
    required DateTime? dueDate,
  }) onSave;

  @override
  State<AddProjectTaskDialog> createState() => _AddProjectTaskDialogState();
}

class _AddProjectTaskDialogState extends State<AddProjectTaskDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedPriority = 'normal';
  DateTime? selectedDueDate;
  bool isSaving = false;
  String? errorMessage;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDueDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDueDate = pickedDate;
    });
  }

  Future<void> save() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Task title is required.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final task = await widget.onSave(
        title: title,
        description: descriptionController.text,
        priority: selectedPriority,
        dueDate: selectedDueDate,
      );

      if (!mounted) return;

      Navigator.of(context).pop(task);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  String get dueDateLabel {
    if (selectedDueDate == null) return 'No due date';

    final month = selectedDueDate!.month.toString().padLeft(2, '0');
    final day = selectedDueDate!.day.toString().padLeft(2, '0');
    final year = selectedDueDate!.year.toString();

    return '$month/$day/$year';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Project Task'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                enabled: !isSaving,
                decoration: const InputDecoration(labelText: 'Task title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                enabled: !isSaving,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedPriority = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isSaving ? null : pickDueDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(dueDateLabel),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Task'),
        ),
      ],
    );
  }
}

class _TaskMetricPill extends StatelessWidget {
  const _TaskMetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProjectTaskTile extends StatelessWidget {
  const _ProjectTaskTile({
    required this.task,
    required this.enabled,
    required this.onToggle,
    required this.onDelete,
  });

  final ProjectTask task;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.isDone
        ? const Color(0xFFF0FDF4)
        : task.isOverdue
            ? const Color(0xFFFEF2F2)
            : Colors.white;

    final borderColor =
        task.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: enabled ? (_) => onToggle() : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete task',
              ),
            ],
          ),
          if (task.description != null && task.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 0, 8, 8),
              child: Text(
                task.description!,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TaskStatusChip(label: task.statusLabel),
                _TaskStatusChip(label: task.priorityLabel),
                _TaskStatusChip(
                  label: task.isOverdue
                      ? 'OVERDUE: ${task.dueDateLabel}'
                      : task.dueDateLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusChip extends StatelessWidget {
  const _TaskStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
