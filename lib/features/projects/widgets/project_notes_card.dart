import 'package:flutter/material.dart';

import '../models/project_note.dart';

class ProjectNotesCard extends StatelessWidget {
  const ProjectNotesCard({
    super.key,
    required this.notes,
    required this.enabled,
    required this.canAddNote,
    required this.canDeleteNote,
    required this.currentUserId,
    required this.onAddNote,
    required this.onDeleteNote,
  });

  final List<ProjectNote> notes;
  final bool enabled;
  final bool canAddNote;
  final bool canDeleteNote;
  final String currentUserId;
  final Future<void> Function(String noteType, String body) onAddNote;
  final Future<void> Function(ProjectNote note) onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Project Notes / Daily Field Updates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Capture jobsite updates, issues, customer comments, delays, weather/site conditions, and next steps.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: enabled && canAddNote
                ? () async {
                    final result = await showDialog<_ProjectNoteDialogResult>(
                      context: context,
                      builder: (_) => const _ProjectNoteDialog(),
                    );

                    if (result == null) return;

                    await onAddNote(result.noteType, result.body);
                  }
                : null,
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Add Field Update'),
          ),
          const SizedBox(height: 14),
          if (notes.isEmpty)
            const Text(
              'No project notes yet. Add the first field update for this project.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...notes.map(
              (note) {
                final canDeleteThisNote =
                    canDeleteNote || note.createdBy == currentUserId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProjectNoteTile(
                    note: note,
                    enabled: enabled,
                    canDelete: canDeleteThisNote,
                    onDelete: () => onDeleteNote(note),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProjectNoteTile extends StatelessWidget {
  const _ProjectNoteTile({
    required this.note,
    required this.enabled,
    required this.canDelete,
    required this.onDelete,
  });

  final ProjectNote note;
  final bool enabled;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final chipColor = switch (note.noteType) {
      'issue' => const Color(0xFFFEE2E2),
      'delay' => const Color(0xFFFFF7ED),
      'customer_note' => const Color(0xFFEFF6FF),
      'weather_site' => const Color(0xFFECFEFF),
      'next_step' => const Color(0xFFF0FDF4),
      'field_update' => const Color(0xFFEEF2FF),
      _ => const Color(0xFFF8FAFC),
    };

    final chipTextColor = switch (note.noteType) {
      'issue' => const Color(0xFFB91C1C),
      'delay' => const Color(0xFFC2410C),
      'customer_note' => const Color(0xFF1D4ED8),
      'weather_site' => const Color(0xFF0E7490),
      'next_step' => const Color(0xFF15803D),
      'field_update' => const Color(0xFF4338CA),
      _ => const Color(0xFF334155),
    };

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
          const Icon(Icons.sticky_note_2_outlined, color: Color(0xFF2563EB)),
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
                    _NoteChip(
                      label: note.noteTypeLabel,
                      backgroundColor: chipColor,
                      textColor: chipTextColor,
                    ),
                    Text(
                      note.creatorLabel,
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
                  note.body,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(note.createdAt),
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
            tooltip: 'Delete note',
          ),
        ],
      ),
    );
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

class _ProjectNoteDialogResult {
  const _ProjectNoteDialogResult({
    required this.noteType,
    required this.body,
  });

  final String noteType;
  final String body;
}

class _ProjectNoteDialog extends StatefulWidget {
  const _ProjectNoteDialog();

  @override
  State<_ProjectNoteDialog> createState() => _ProjectNoteDialogState();
}

class _ProjectNoteDialogState extends State<_ProjectNoteDialog> {
  final bodyController = TextEditingController();
  String selectedNoteType = 'field_update';
  String? errorMessage;

  @override
  void dispose() {
    bodyController.dispose();
    super.dispose();
  }

  void submit() {
    final body = bodyController.text.trim();

    if (body.isEmpty) {
      setState(() {
        errorMessage = 'Enter a note before saving.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ProjectNoteDialogResult(
        noteType: selectedNoteType,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Field Update'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedNoteType,
              decoration: const InputDecoration(labelText: 'Note type'),
              items: const [
                DropdownMenuItem(
                  value: 'general',
                  child: Text('General Update'),
                ),
                DropdownMenuItem(
                  value: 'field_update',
                  child: Text('Field Update'),
                ),
                DropdownMenuItem(value: 'issue', child: Text('Issue')),
                DropdownMenuItem(value: 'delay', child: Text('Delay')),
                DropdownMenuItem(
                  value: 'customer_note',
                  child: Text('Customer Note'),
                ),
                DropdownMenuItem(
                  value: 'weather_site',
                  child: Text('Weather / Site Condition'),
                ),
                DropdownMenuItem(
                  value: 'next_step',
                  child: Text('Next Step'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedNoteType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Notes / details',
                alignLabelWithHint: true,
                hintText: 'Example: Crew completed footer layout. Waiting on additional anchor bolts before installation.',
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submit,
          child: const Text('Save Note'),
        ),
      ],
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({
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
