import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team_member.dart';
import '../models/team_invitation.dart';

class TeamMemberService {
  TeamMemberService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<TeamMember>> getTeamMembers({
    required String companyId,
  }) async {
    final rows = await _supabase
        .from('company_members')
        .select(
          'id, company_id, user_id, role, status, invited_by, joined_at, created_at, updated_at, profiles!company_members_user_id_fkey(full_name, email, phone, avatar_url)',
        )
        .eq('company_id', companyId)
        .order('created_at');

    return rows.map<TeamMember>(TeamMember.fromMap).toList();
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    await _supabase
        .from('company_members')
        .update({
          'role': role,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId);
  }

  Future<void> updateMemberStatus({
    required String memberId,
    required String status,
  }) async {
    await _supabase
        .from('company_members')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId);
  }

  Future<void> disableMember({
    required String memberId,
  }) async {
    await updateMemberStatus(
      memberId: memberId,
      status: 'disabled',
    );
  }

  Future<void> reactivateMember({
    required String memberId,
  }) async {
    await updateMemberStatus(
      memberId: memberId,
      status: 'active',
    );
  }
  Future<List<TeamInvitation>> getPendingInvitations({
    required String companyId,
  }) async {
    final rows = await _supabase
        .from('team_invitations')
        .select(
          'id, company_id, email, full_name, phone, role, status, invited_by, accepted_by, accepted_at, canceled_at, created_at, updated_at',
        )
        .eq('company_id', companyId)
        .eq('status', 'pending')
        .order('created_at');

    return rows.map<TeamInvitation>(TeamInvitation.fromMap).toList();
  }

  Future<void> createInvitation({
    required String companyId,
    required String email,
    String? fullName,
    String? phone,
    required String role,
    required String invitedBy,
  }) async {
    await _supabase.from('team_invitations').insert({
      'company_id': companyId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName?.trim().isEmpty == true ? null : fullName?.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'role': role,
      'status': 'pending',
      'invited_by': invitedBy,
    });
  }

  Future<void> cancelInvitation({
    required String invitationId,
  }) async {
    await _supabase.from('team_invitations').update({
      'status': 'canceled',
      'canceled_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invitationId);
  }

}
