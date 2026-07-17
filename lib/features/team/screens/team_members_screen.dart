import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/team_member.dart';
import '../services/team_member_service.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({
    super.key,
    required this.companyContext,
  });

  final CompanyContext companyContext;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  late final TeamMemberService teamMemberService;

  List<TeamMember> members = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    teamMemberService = TeamMemberService(Supabase.instance.client);
    loadTeamMembers();
  }

  Future<void> loadTeamMembers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final freshMembers = await teamMemberService.getTeamMembers(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        members = freshMembers;
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

  Future<void> updateRole(TeamMember member, String role) async {
    if (member.isOwner || isSaving) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await teamMemberService.updateMemberRole(
        memberId: member.id,
        role: role,
      );

      await loadTeamMembers();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> toggleStatus(TeamMember member) async {
    if (member.isOwner || isSaving) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      if (member.isDisabled) {
        await teamMemberService.reactivateMember(memberId: member.id);
      } else {
        await teamMemberService.disableMember(memberId: member.id);
      }

      await loadTeamMembers();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> showRolePicker(TeamMember member) async {
    if (!canManageTeam || member.isOwner || isSaving) return;

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Change role for ${member.displayName}'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('admin'),
              child: const Text('Admin'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('manager'),
              child: const Text('Manager'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('field_user'),
              child: const Text('Field User'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('viewer'),
              child: const Text('Viewer'),
            ),
          ],
        );
      },
    );

    if (selectedRole == null || selectedRole == member.role) return;

    await updateRole(member, selectedRole);
  }

  int get activeCount {
    return members.where((member) => member.status == 'active').length;
  }

  int get disabledCount {
    return members.where((member) => member.status == 'disabled').length;
  }

  bool get canManageTeam {
    return widget.companyContext.role == 'owner' ||
        widget.companyContext.role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadTeamMembers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTeamMembers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 0,
              color: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.companyContext.companyName} Team',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stable diagnostic view for team access, roles, and status.',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Pill(label: 'Total', value: members.length.toString()),
                        _Pill(label: 'Active', value: activeCount.toString()),
                        _Pill(
                          label: 'Disabled',
                          value: disabledCount.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  canManageTeam
                      ? 'Invite flow is next. For now, this screen confirms existing company users.'
                      : 'You can view team members, but only owners and admins can manage roles.',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              _ErrorBox(message: errorMessage!)
            else if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (members.isEmpty)
              const Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No team members found.'),
                ),
              )
            else
              ...members.map((member) {
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.email,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SmallBadge(
                              label: member.roleLabel,
                              textColor: const Color(0xFF1D4ED8),
                              backgroundColor: const Color(0xFFEFF6FF),
                            ),
                            _SmallBadge(
                              label: member.statusLabel,
                              textColor: const Color(0xFF166534),
                              backgroundColor: const Color(0xFFF0FDF4),
                            ),
                            if (member.isOwner)
                              const _SmallBadge(
                                label: 'PROTECTED',
                                textColor: Color(0xFF7C2D12),
                                backgroundColor: Color(0xFFFFF7ED),
                              ),
                          ],
                        ),
                        if (canManageTeam && !member.isOwner) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => showRolePicker(member),
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Change Role'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => toggleStatus(member),
                                icon: Icon(
                                  member.isDisabled
                                      ? Icons.check_circle_outline
                                      : Icons.block_outlined,
                                ),
                                label: Text(
                                  member.isDisabled
                                      ? 'Reactivate'
                                      : 'Disable',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
