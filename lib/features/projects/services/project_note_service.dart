import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_note.dart';

class ProjectNoteService {
  ProjectNoteService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ProjectNote>> getProjectNotes({
    required String projectId,
  }) async {
    final response = await _supabase
        .from('project_notes')
        .select('''
          id,
          company_id,
          project_id,
          note_type,
          body,
          created_by,
          created_at,
          updated_at
        ''')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    final notes = List<Map<String, dynamic>>.from(response);

    if (notes.isEmpty) {
      return const [];
    }

    final creatorIds = notes
        .map((note) => note['created_by'] as String)
        .toSet()
        .toList();

    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', creatorIds);

    final profilesByUserId = {
      for (final profile in profilesResponse)
        profile['id'] as String: Map<String, dynamic>.from(profile),
    };

    return notes.map<ProjectNote>((note) {
      final creatorId = note['created_by'] as String;
      final profile = profilesByUserId[creatorId];
      final noteMap = Map<String, dynamic>.from(note);

      if (profile != null) {
        noteMap['profiles'] = profile;
      }

      return ProjectNote.fromMap(noteMap);
    }).toList();
  }

  Future<ProjectNote> createProjectNote({
    required String companyId,
    required String projectId,
    required String noteType,
    required String body,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be logged in to add a project note.');
    }

    final response = await _supabase
        .from('project_notes')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'note_type': noteType,
          'body': body.trim(),
          'created_by': userId,
        })
        .select('''
          id,
          company_id,
          project_id,
          note_type,
          body,
          created_by,
          created_at,
          updated_at
        ''')
        .single();

    final profileResponse = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .eq('id', userId)
        .maybeSingle();

    final noteMap = Map<String, dynamic>.from(response);

    if (profileResponse != null) {
      noteMap['profiles'] = profileResponse;
    }

    return ProjectNote.fromMap(noteMap);
  }

  Future<void> deleteProjectNote(String noteId) async {
    await _supabase.from('project_notes').delete().eq('id', noteId);
  }
}
