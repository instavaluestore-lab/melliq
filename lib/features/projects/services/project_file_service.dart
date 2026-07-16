import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_file.dart';

class ProjectFileService {
  ProjectFileService(this._supabase);

  final SupabaseClient _supabase;

  static const String bucketName = 'project-files';

  Future<List<ProjectFile>> getFilesForProject({
    required String companyId,
    required String projectId,
  }) async {
    final rows = await _supabase
        .from('project_files')
        .select()
        .eq('company_id', companyId)
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return rows.map<ProjectFile>(ProjectFile.fromMap).toList();
  }

  Future<ProjectFile> uploadProjectFile({
    required String companyId,
    required String projectId,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
    String? mimeType,
    String? description,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final safeFileName = _sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$companyId/$projectId/$timestamp-$safeFileName';

    await _supabase.storage.from(bucketName).uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );

    final row = await _supabase
        .from('project_files')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'uploaded_by': currentUserId,
          'file_name': safeFileName,
          'file_path': filePath,
          'file_type': fileType,
          'mime_type': mimeType,
          'file_size': fileBytes.length,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        })
        .select()
        .single();

    return ProjectFile.fromMap(row);
  }

  Future<String> createSignedUrl(ProjectFile file) async {
    return _supabase.storage.from(bucketName).createSignedUrl(
          file.filePath,
          60 * 10,
        );
  }

  Future<void> deleteProjectFile(ProjectFile file) async {
    await _supabase.storage.from(bucketName).remove([file.filePath]);

    await _supabase.from('project_files').delete().eq('id', file.id);
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'project-file';
    }

    return trimmed
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
