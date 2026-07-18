import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import '../../company/models/company_context.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';
import 'lead_form_screen.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({
    super.key,
    required this.companyContext,
  });

  final CompanyContext companyContext;

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  late final LeadService leadService;
  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';
  List<Lead> leads = [];

  bool get canManageLeads {
    return widget.companyContext.isPrimaryAdmin ||
        widget.companyContext.isCfo ||
        widget.companyContext.isAdmin ||
        widget.companyContext.isManager;
  }

  @override
  void initState() {
    super.initState();
    leadService = LeadService(Supabase.instance.client);
    loadLeads();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadLeads() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await leadService.getLeadsForCompany(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        leads = result;
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

  List<Lead> get filteredLeads {
    final query = searchController.text.trim().toLowerCase();

    return leads.where((lead) {
      final matchesStatus =
          selectedStatus == 'all' || lead.status == selectedStatus;

      final searchableText = [
        lead.title,
        lead.displayContact,
        lead.contactEmail,
        lead.contactPhone,
        lead.sourceLabel,
        lead.statusLabel,
        lead.displayLocation,
        lead.notes,
      ].whereType<String>().join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get openLeadCount {
    return leads.where((lead) => lead.status != 'won' && lead.status != 'lost').length;
  }

  double get openLeadValue {
    return leads
        .where((lead) => lead.status != 'won' && lead.status != 'lost')
        .fold<double>(0, (total, lead) => total + lead.estimatedValue);
  }

  String _formatMoney(double value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${value.abs().toStringAsFixed(2)}';
  }

  Future<void> openLeadForm({Lead? lead}) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeadFormScreen(
          companyContext: widget.companyContext,
          lead: lead,
        ),
      ),
    );

    if (didSave == true) {
      await loadLeads();
    }
  }

  Future<void> archiveLead(Lead lead) async {
    setState(() {
      errorMessage = null;
    });

    try {
      await leadService.archiveLead(lead.id);

      if (!mounted) return;

      setState(() {
        leads = leads.where((existingLead) => existingLead.id != lead.id).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead archived.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleLeads = filteredLeads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          TextButton(
            onPressed: canManageLeads ? () => openLeadForm() : null,
            child: const Text('Add'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: PageNavigationButtons(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadLeads,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text(
                    widget.companyContext.companyName,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Leads Pipeline',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track new sales opportunities before they become quotes or active projects.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        label: 'Open Leads',
                        value: openLeadCount.toString(),
                        subtitle: 'Not won or lost',
                      ),
                      _StatCard(
                        label: 'Open Lead Value',
                        value: _formatMoney(openLeadValue),
                        subtitle: 'Estimated opportunity',
                      ),
                      _StatCard(
                        label: 'Total Leads',
                        value: leads.length.toString(),
                        subtitle: 'Active pipeline records',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search leads',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status filter'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All active leads')),
                      DropdownMenuItem(value: 'new', child: Text('New')),
                      DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(
                        value: 'proposal_needed',
                        child: Text('Proposal Needed'),
                      ),
                      DropdownMenuItem(
                        value: 'proposal_sent',
                        child: Text('Proposal Sent'),
                      ),
                      DropdownMenuItem(value: 'won', child: Text('Won')),
                      DropdownMenuItem(value: 'lost', child: Text('Lost')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (isLoading)
                    const _InfoCard(
                      title: 'Loading leads...',
                      body: 'Checking the current sales pipeline.',
                    )
                  else if (errorMessage != null)
                    _InfoCard(
                      title: 'Could not load leads',
                      body: errorMessage!,
                    )
                  else if (visibleLeads.isEmpty)
                    const _InfoCard(
                      title: 'No leads found',
                      body: 'Add your first lead or adjust the current filters.',
                    )
                  else
                    ...visibleLeads.map(
                      (lead) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LeadCard(
                          lead: lead,
                          canManage: canManageLeads,
                          onOpen: () => openLeadForm(lead: lead),
                          onArchive: () => archiveLead(lead),
                          formatMoney: _formatMoney,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.canManage,
    required this.onOpen,
    required this.onArchive,
    required this.formatMoney,
  });

  final Lead lead;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: lead.statusLabel),
                _Chip(label: lead.sourceLabel),
                _Chip(label: lead.priorityLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lead.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lead.displayContact,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lead.displayLocation,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Estimated value: ${formatMoney(lead.estimatedValue)}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (lead.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                lead.notes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archive'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
