import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/team_invitation.dart';
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
  List<TeamInvitation> invitations = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    teamMemberService = TeamMemberService(Supabase.instance.client);
    loadTeamData();
  }

  Future<void> loadTeamData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final freshMembers = await teamMemberService.getTeamMembers(
        companyId: widget.companyContext.companyId,
      );

      final freshInvitations = await teamMemberService.getPendingInvitations(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        members = freshMembers;
        invitations = freshInvitations;
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

  Future<void> createInvitation({
    required String email,
    String? fullName,
    String? phone,
    required String role,
  }) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await teamMemberService.createInvitation(
        companyId: widget.companyContext.companyId,
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        invitedBy: widget.companyContext.userId,
      );

      await loadTeamData();

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

  Future<void> cancelInvitation(TeamInvitation invitation) async {
    if (!canManageTeam || isSaving) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await teamMemberService.cancelInvitation(invitationId: invitation.id);
      await loadTeamData();

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

      await loadTeamData();

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

      await loadTeamData();

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

  Future<void> showInviteDialog() async {
    if (!canManageTeam || isSaving) return;

    final result = await showDialog<_InviteFormResult>(
      context: context,
      builder: (context) {
        return const _InviteTeamMemberDialog();
      },
    );

    if (result == null) return;

    await createInvitation(
      email: result.email,
      fullName: result.fullName,
      phone: result.phone,
      role: result.role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadTeamData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTeamData,
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
                      'Manage team access, roles, pending invites, and active status.',
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
                        _Pill(
                          label: 'Pending',
                          value: invitations.length.toString(),
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
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Text(
                      canManageTeam
                          ? 'Invite employees and assign their company role.'
                          : 'You can view team members, but only owners and admins can manage roles.',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          canManageTeam && !isSaving ? showInviteDialog : null,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Invite Team Member'),
                    ),
                  ],
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
            else ...[
              const _SectionTitle(title: 'Active Company Members'),
              const SizedBox(height: 8),
              if (members.isEmpty)
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
                  return _TeamMemberCard(
                    member: member,
                    canManageTeam: canManageTeam,
                    isSaving: isSaving,
                    onChangeRole: () => showRolePicker(member),
                    onToggleStatus: () => toggleStatus(member),
                  );
                }),
              const SizedBox(height: 18),
              const _SectionTitle(title: 'Pending Invitations'),
              const SizedBox(height: 8),
              if (invitations.isEmpty)
                const Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No pending invitations.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...invitations.map((invitation) {
                  return _InvitationCard(
                    invitation: invitation,
                    canManageTeam: canManageTeam,
                    isSaving: isSaving,
                    onCancel: () => cancelInvitation(invitation),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.member,
    required this.canManageTeam,
    required this.isSaving,
    required this.onChangeRole,
    required this.onToggleStatus,
  });

  final TeamMember member;
  final bool canManageTeam;
  final bool isSaving;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final canEditThisMember = canManageTeam && !member.isOwner && !isSaving;

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
            if (canEditThisMember) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onChangeRole,
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Change Role'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      member.isDisabled
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                    ),
                    label: Text(
                      member.isDisabled ? 'Reactivate' : 'Disable',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.canManageTeam,
    required this.isSaving,
    required this.onCancel,
  });

  final TeamInvitation invitation;
  final bool canManageTeam;
  final bool isSaving;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
              invitation.displayName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invitation.email,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (invitation.phone != null &&
                invitation.phone!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                invitation.phone!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallBadge(
                  label: invitation.roleLabel,
                  textColor: const Color(0xFF1D4ED8),
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
                _SmallBadge(
                  label: invitation.statusLabel,
                  textColor: const Color(0xFF92400E),
                  backgroundColor: const Color(0xFFFFFBEB),
                ),
              ],
            ),
            if (canManageTeam) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Invitation'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteTeamMemberDialog extends StatefulWidget {
  const _InviteTeamMemberDialog();

  @override
  State<_InviteTeamMemberDialog> createState() =>
      _InviteTeamMemberDialogState();
}

class _InviteTeamMemberDialogState extends State<_InviteTeamMemberDialog> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  String selectedRole = 'field_user';

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void submit() {
    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    Navigator.of(context).pop(
      _InviteFormResult(
        email: emailController.text.trim(),
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Team Member'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'employee@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Email is required.';
                    }

                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(
                      value: 'field_user',
                      child: Text('Field User'),
                    ),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submit,
          child: const Text('Create Invite'),
        ),
      ],
    );
  }
}

class _InviteFormResult {
  const _InviteFormResult({
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  final String email;
  final String fullName;
  final String phone;
  final String role;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 16,
        fontWeight: FontWeight.w900,
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
