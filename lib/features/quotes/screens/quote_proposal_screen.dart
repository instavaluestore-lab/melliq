import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../audit/models/record_audit_log.dart';
import '../../audit/services/audit_log_service.dart';
import '../../company/models/company_context.dart';
import '../../customers/models/customer.dart';
import '../models/quote.dart';
import '../models/quote_line_item.dart';
import '../services/quote_proposal_pdf_service.dart';
import '../services/quote_service.dart';

class QuoteProposalScreen extends StatelessWidget {
  const QuoteProposalScreen({
    super.key,
    required this.companyContext,
    required this.quote,
    required this.lineItems,
    required this.customer,
  });

  final CompanyContext companyContext;
  final Quote quote;
  final List<QuoteLineItem> lineItems;
  final Customer customer;

  String _formatMoney(double value) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final cents = parts[1];

    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final indexFromRight = whole.length - i;
      buffer.write(whole[i]);

      if (indexFromRight > 1 && indexFromRight % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}\$${buffer.toString()}.$cents';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$month/$day/$year';
  }

  Future<void> _updateQuoteStatus(BuildContext context, String status) async {
    try {
      await QuoteService(
        Supabase.instance.client,
      ).updateQuoteStatus(quoteId: quote.id, status: status);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quote marked as ${_statusActionLabel(status)}.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update quote status: $error')),
      );
    }
  }

  String _statusActionLabel(String status) {
    return switch (status) {
      'sent' => 'sent',
      'approved' => 'approved',
      'rejected' => 'rejected',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = quote.discountAmount > 0;
    final hasTax = quote.taxAmount > 0;
    final validUntil = quote.validUntil;

    return Scaffold(
      appBar: AppBar(title: const Text('Quote Proposal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProposalWorkflowCard(
            quote: quote,
            onMarkSent: () => _updateQuoteStatus(context, 'sent'),
            onMarkApproved: () => _updateQuoteStatus(context, 'approved'),
            onMarkRejected: () => _updateQuoteStatus(context, 'rejected'),
          ),
          const SizedBox(height: 12),
          _ProposalStatusHistoryCard(quote: quote),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final pdfBytes = await const QuoteProposalPdfService()
                      .buildProposalPdf(
                        companyContext: companyContext,
                        quote: quote,
                        lineItems: lineItems,
                        customer: customer,
                      );

                  await Printing.layoutPdf(
                    name: '${quote.quoteNumber}-proposal.pdf',
                    onLayout: (_) async => pdfBytes,
                  );
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not export PDF: $error')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export PDF'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyContext.displayBrandName,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Project Proposal',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              quote.quoteNumber,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quote.statusLabel,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    quote.title.isEmpty ? 'Untitled Quote' : quote.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                    ),
                  ),
                  if (validUntil != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Valid until ${_formatDate(validUntil)}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _ProposalCustomerCard(customer: customer),
                  if (quote.notes != null &&
                      quote.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      quote.notes!.trim(),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  const Text(
                    'Included Items',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lineItems.isEmpty)
                    const Text(
                      'No proposal line items have been added yet.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    )
                  else
                    ...lineItems.map(
                      (item) => _ProposalLineItemRow(
                        item: item,
                        formatMoney: _formatMoney,
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  if (hasDiscount)
                    _ProposalTotalRow(
                      label: 'Discount',
                      value: '-${_formatMoney(quote.discountAmount)}',
                    ),
                  if (hasTax)
                    _ProposalTotalRow(
                      label: 'Tax',
                      value: _formatMoney(quote.taxAmount),
                    ),
                  const SizedBox(height: 8),
                  _ProposalTotalRow(
                    label: 'Customer Total',
                    value: _formatMoney(quote.totalAmount),
                    isTotal: true,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 18),
                  const _ProposalTermsCard(),
                  const SizedBox(height: 18),
                  const _ProposalAcceptanceCard(),
                  const SizedBox(height: 18),
                  _ProposalFooter(
                    preparedBy: companyContext.displayBrandName,
                    poweredByLupinusBuild: companyContext.poweredByLupinusBuild,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProposalStatusHistoryCard extends StatelessWidget {
  const _ProposalStatusHistoryCard({required this.quote});

  final Quote quote;

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';

    return '$month/$day/$year $hour:$minute $suffix';
  }

  String _fallbackActorLabel(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return 'Unknown user';
    }

    final value = userId.trim();
    if (value.length <= 8) return value;

    return 'User ${value.substring(0, 8)}';
  }

  Future<_ProposalStatusHistoryData> _loadStatusHistory() async {
    final loadedLogs = await AuditLogService(
      Supabase.instance.client,
    ).getLogsForRecord(recordType: 'quote', recordId: quote.id, limit: 25);

    final statusLogs = loadedLogs
        .where((log) => log.action == 'status_changed')
        .toList();

    final userLabels = await _loadUserLabels(statusLogs);

    return _ProposalStatusHistoryData(logs: statusLogs, userLabels: userLabels);
  }

  Future<Map<String, String>> _loadUserLabels(List<RecordAuditLog> logs) async {
    final userIds = logs
        .map((log) => log.createdBy?.trim())
        .whereType<String>()
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList();

    if (userIds.isEmpty) return {};

    final labels = <String, String>{};

    try {
      final profileRows = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', userIds);

      for (final row in profileRows) {
        final map = Map<String, dynamic>.from(row);
        final userId = (map['id'] as String?)?.trim();
        if (userId == null || userId.isEmpty) continue;

        final fullName = (map['full_name'] as String?)?.trim();
        final email = (map['email'] as String?)?.trim();

        if (fullName != null && fullName.isNotEmpty) {
          labels[userId] = fullName;
        } else if (email != null && email.isNotEmpty) {
          labels[userId] = email;
        }
      }
    } catch (_) {
      // Continue to company member fallback.
    }

    final missingUserIds = userIds
        .where((userId) => !labels.containsKey(userId))
        .toList();

    if (missingUserIds.isEmpty) return labels;

    try {
      final memberRows = await Supabase.instance.client
          .from('company_members')
          .select(
            'user_id, profiles!company_members_user_id_fkey(full_name, email)',
          )
          .eq('company_id', quote.companyId)
          .inFilter('user_id', missingUserIds);

      for (final row in memberRows) {
        final map = Map<String, dynamic>.from(row);
        final userId = (map['user_id'] as String?)?.trim();
        if (userId == null || userId.isEmpty) continue;

        final profile = map['profiles'] == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(map['profiles'] as Map);

        final fullName = (profile['full_name'] as String?)?.trim();
        final email = (profile['email'] as String?)?.trim();

        if (fullName != null && fullName.isNotEmpty) {
          labels[userId] = fullName;
        } else if (email != null && email.isNotEmpty) {
          labels[userId] = email;
        }
      }
    } catch (_) {
      // Keep fallback user-id labels if profile lookup is unavailable.
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProposalStatusHistoryData>(
      future: _loadStatusHistory(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final logs = data?.logs ?? const <RecordAuditLog>[];
        final userLabels = data?.userLabels ?? const <String, String>{};

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_outlined, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Status History',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Text(
                  'Loading status history...',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                )
              else if (snapshot.hasError)
                Text(
                  'Could not load status history: ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                  ),
                )
              else if (logs.isEmpty)
                const Text(
                  'No status changes have been recorded yet.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                )
              else
                ...logs.map((log) {
                  final createdBy = log.createdBy?.trim();
                  final actor =
                      userLabels[createdBy] ??
                      _fallbackActorLabel(log.createdBy);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ProposalStatusHistoryRow(
                      summary: log.summary,
                      actor: actor,
                      timestamp: _formatDateTime(log.createdAt),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ProposalStatusHistoryData {
  const _ProposalStatusHistoryData({
    required this.logs,
    required this.userLabels,
  });

  final List<RecordAuditLog> logs;
  final Map<String, String> userLabels;
}

class _ProposalStatusHistoryRow extends StatelessWidget {
  const _ProposalStatusHistoryRow({
    required this.summary,
    required this.actor,
    required this.timestamp,
  });

  final String summary;
  final String actor;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$actor • $timestamp',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalWorkflowCard extends StatelessWidget {
  const _ProposalWorkflowCard({
    required this.quote,
    required this.onMarkSent,
    required this.onMarkApproved,
    required this.onMarkRejected,
  });

  final Quote quote;
  final VoidCallback onMarkSent;
  final VoidCallback onMarkApproved;
  final VoidCallback onMarkRejected;

  @override
  Widget build(BuildContext context) {
    final status = quote.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Proposal Status: ${quote.statusLabel}',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == 'draft')
                FilledButton.icon(
                  onPressed: onMarkSent,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Mark as Sent'),
                ),
              if (status == 'sent') ...[
                FilledButton.icon(
                  onPressed: onMarkApproved,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: onMarkRejected,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject'),
                ),
              ],
              if (status == 'approved')
                const _ProposalStatusPill(
                  label: 'Approved',
                  icon: Icons.check_circle_outline,
                ),
              if (status == 'rejected')
                const _ProposalStatusPill(
                  label: 'Rejected',
                  icon: Icons.cancel_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProposalStatusPill extends StatelessWidget {
  const _ProposalStatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCustomerCard extends StatelessWidget {
  const _ProposalCustomerCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final companyName = customer.companyName?.trim();
    final email = customer.email?.trim();
    final phone = customer.phone?.trim();
    final location = customer.location;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prepared For',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customer.displayName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (companyName != null &&
              companyName.isNotEmpty &&
              companyName != customer.displayName) ...[
            const SizedBox(height: 4),
            Text(
              companyName,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (email != null && email.isNotEmpty)
                _ProposalPill(label: 'Email', value: email),
              if (phone != null && phone.isNotEmpty)
                _ProposalPill(label: 'Phone', value: phone),
              if (location != 'No location')
                _ProposalPill(label: 'Location', value: location),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProposalLineItemRow extends StatelessWidget {
  const _ProposalLineItemRow({required this.item, required this.formatMoney});

  final QuoteLineItem item;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name.isEmpty ? 'Unnamed item' : item.name,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (item.description != null &&
              item.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!.trim(),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProposalPill(
                label: 'Qty',
                value: item.quantity.toStringAsFixed(2),
              ),
              _ProposalPill(label: 'Unit', value: item.unit),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProposalPill extends StatelessWidget {
  const _ProposalPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: const Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProposalTotalRow extends StatelessWidget {
  const _ProposalTotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 8 : 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF111827)
                    : const Color(0xFF475569),
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal
                  ? const Color(0xFF111827)
                  : const Color(0xFF334155),
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalTermsCard extends StatelessWidget {
  const _ProposalTermsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proposal Terms',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '• Pricing is based on the scope, quantities, and selections shown in this proposal.\n'
            '• Changes to size, site conditions, materials, engineering, permits, or installation requirements may require a revised proposal.\n'
            '• Work should not begin until the proposal is accepted and any required deposit or authorization is received.\n'
            '• Permit, engineering, utility, or access requirements may affect schedule and final scope.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalAcceptanceCard extends StatelessWidget {
  const _ProposalAcceptanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Acceptance',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18),
          _SignatureLine(label: 'Customer Name'),
          SizedBox(height: 16),
          _SignatureLine(label: 'Customer Signature'),
          SizedBox(height: 16),
          _SignatureLine(label: 'Date'),
        ],
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProposalFooter extends StatelessWidget {
  const _ProposalFooter({
    required this.preparedBy,
    required this.poweredByLupinusBuild,
  });

  final String preparedBy;
  final bool poweredByLupinusBuild;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        poweredByLupinusBuild
            ? 'Prepared by $preparedBy • Powered by LupinusBuild'
            : 'Prepared by $preparedBy',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
