import 'package:flutter/material.dart';

import '../../company/models/company_context.dart';
import '../models/quote.dart';
import '../models/quote_line_item.dart';

class QuoteProposalScreen extends StatelessWidget {
  const QuoteProposalScreen({
    super.key,
    required this.companyContext,
    required this.quote,
    required this.lineItems,
  });

  final CompanyContext companyContext;
  final Quote quote;
  final List<QuoteLineItem> lineItems;

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
                  _ProposalTotalRow(
                    label: 'Subtotal',
                    value: _formatMoney(quote.subtotal),
                  ),
                  if (quote.markupAmount > 0)
                    _ProposalTotalRow(
                      label: 'Project Overhead & Profit',
                      value: _formatMoney(quote.markupAmount),
                    ),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'This proposal view is customer-facing. Internal cost, profit, and margin details are intentionally hidden.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
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
              _ProposalPill(
                label: 'Unit Price',
                value: formatMoney(item.unitPrice),
              ),
              _ProposalPill(
                label: 'Line Total',
                value: formatMoney(item.totalPrice),
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProposalPill extends StatelessWidget {
  const _ProposalPill({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

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
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
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
