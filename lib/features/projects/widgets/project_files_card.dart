import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project_file.dart';

class ProjectFilesCard extends StatelessWidget {
  const ProjectFilesCard({
    super.key,
    required this.files,
    required this.enabled,
    required this.canUploadFile,
    required this.canDeleteFile,
    required this.onUploadFile,
    required this.onOpenFile,
    required this.onDeleteFile,
  });

  final List<ProjectFile> files;
  final bool enabled;
  final bool canUploadFile;
  final bool canDeleteFile;
  final VoidCallback onUploadFile;
  final ValueChanged<ProjectFile> onOpenFile;
  final ValueChanged<ProjectFile> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    final photoCount = files.where((file) => file.isImage).length;
    final documentCount = files.length - photoCount;

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
              'Project Photos & Files',
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
                _FileMetricPill(label: 'Total', value: files.length.toString()),
                _FileMetricPill(label: 'Photos', value: photoCount.toString()),
                _FileMetricPill(
                  label: 'Documents',
                  value: documentCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enabled && canUploadFile ? onUploadFile : null,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload File or Photo'),
              ),
            ),
            const SizedBox(height: 16),
            if (files.isEmpty)
              const Text(
                'No files uploaded yet. Add site photos, measurement photos, install photos, or project documents.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.45,
                ),
              )
            else
              ...files.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProjectFileTile(
                    file: file,
                    enabled: enabled,
                    onOpen: () => onOpenFile(file),
                    onDelete: () => onDeleteFile(file),
                    canDeleteFile: canDeleteFile,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProjectFileUploadDialog extends StatefulWidget {
  const ProjectFileUploadDialog({
    super.key,
    required this.onUpload,
  });

  final Future<void> Function({
    required PlatformFile pickedFile,
    required String fileType,
    required String description,
  }) onUpload;

  @override
  State<ProjectFileUploadDialog> createState() =>
      _ProjectFileUploadDialogState();
}

class _ProjectFileUploadDialogState extends State<ProjectFileUploadDialog> {
  final descriptionController = TextEditingController();

  PlatformFile? pickedFile;
  String selectedFileType = 'document';
  bool isUploading = false;
  String? errorMessage;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      pickedFile = result.files.single;
      errorMessage = null;
    });
  }

  Future<void> upload() async {
    final file = pickedFile;

    if (file == null) {
      setState(() {
        errorMessage = 'Choose a file or photo first.';
      });
      return;
    }

    if (file.bytes == null) {
      setState(() {
        errorMessage = 'Could not read this file. Try choosing it again.';
      });
      return;
    }

    setState(() {
      isUploading = true;
      errorMessage = null;
    });

    try {
      await widget.onUpload(
        pickedFile: file,
        fileType: selectedFileType,
        description: descriptionController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Project File'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : pickFile,
                  icon: const Icon(Icons.attach_file_outlined),
                  label: Text(pickedFile?.name ?? 'Choose file or photo'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedFileType,
                decoration: const InputDecoration(labelText: 'File type'),
                items: const [
                  DropdownMenuItem(
                    value: 'site_photo',
                    child: Text('Site Photo'),
                  ),
                  DropdownMenuItem(
                    value: 'measurement_photo',
                    child: Text('Measurement Photo'),
                  ),
                  DropdownMenuItem(
                    value: 'installation_photo',
                    child: Text('Installation Photo'),
                  ),
                  DropdownMenuItem(
                    value: 'completion_photo',
                    child: Text('Completion Photo'),
                  ),
                  DropdownMenuItem(
                    value: 'material_order',
                    child: Text('Material Order'),
                  ),
                  DropdownMenuItem(
                    value: 'document',
                    child: Text('Document'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: isUploading
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedFileType = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                enabled: !isUploading,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description / notes',
                  alignLabelWithHint: true,
                ),
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
          onPressed: isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUploading ? null : upload,
          child: isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }
}

class _ProjectFileTile extends StatelessWidget {
  const _ProjectFileTile({
    required this.file,
    required this.enabled,
    required this.canDeleteFile,
    required this.onOpen,
    required this.onDelete,
  });

  final ProjectFile file;
  final bool enabled;
  final bool canDeleteFile;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = file.isImage
        ? Icons.image_outlined
        : Icons.insert_drive_file_outlined;

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
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${file.fileTypeLabel} • ${file.fileSizeLabel} • ${file.createdDateLabel}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (file.description != null &&
                    file.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    file.description!,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onOpen : null,
            icon: const Icon(Icons.open_in_new_outlined),
            tooltip: 'Open file',
          ),
          IconButton(
            onPressed: enabled && canDeleteFile ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete file',
          ),
        ],
      ),
    );
  }
}

class _FileMetricPill extends StatelessWidget {
  const _FileMetricPill({
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

Future<void> openProjectFileUrl(String signedUrl) async {
  final uri = Uri.parse(signedUrl);

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    throw Exception('Could not open file.');
  }
}
