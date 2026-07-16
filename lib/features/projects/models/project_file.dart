class ProjectFile {
  const ProjectFile({
    required this.id,
    required this.companyId,
    required this.projectId,
    this.uploadedBy,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.mimeType,
    this.fileSize,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String? uploadedBy;
  final String fileName;
  final String filePath;
  final String fileType;
  final String? mimeType;
  final int? fileSize;
  final String? description;
  final DateTime createdAt;

  bool get isImage {
    final type = mimeType?.toLowerCase() ?? '';
    final name = fileName.toLowerCase();

    return type.startsWith('image/') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic');
  }

  String get fileTypeLabel {
    switch (fileType) {
      case 'site_photo':
        return 'SITE PHOTO';
      case 'measurement_photo':
        return 'MEASUREMENT PHOTO';
      case 'installation_photo':
        return 'INSTALLATION PHOTO';
      case 'completion_photo':
        return 'COMPLETION PHOTO';
      case 'material_order':
        return 'MATERIAL ORDER';
      case 'document':
        return 'DOCUMENT';
      default:
        return fileType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get fileSizeLabel {
    if (fileSize == null) return 'Unknown size';

    final bytes = fileSize!;

    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get createdDateLabel {
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    final year = createdAt.year.toString();

    return '$month/$day/$year';
  }

  factory ProjectFile.fromMap(Map<String, dynamic> map) {
    return ProjectFile(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      projectId: map['project_id'] as String,
      uploadedBy: map['uploaded_by'] as String?,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String? ?? 'document',
      mimeType: map['mime_type'] as String?,
      fileSize: map['file_size'] == null
          ? null
          : int.tryParse(map['file_size'].toString()),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
