import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../customers/services/customer_service.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import 'quote_form_screen.dart';
import 'quote_proposal_screen.dart';

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key, required this.companyContext});

  final CompanyContext companyContext;

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  late final QuoteService quoteService;
  late final CustomerService customerService;

  bool isLoading = true;
  String? errorMessage;
  List<Quote> quotes = [];

  CompanyContext get companyContext => widget.companyContext;

  @override
  void initState() {
    super.initState();
    quoteService = QuoteService(Supabase.instance.client);
    customerService = CustomerService(Supabase.instance.client);
    loadQuotes();
  }

  Future<void> loadQuotes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedQuotes = await quoteService.getQuotesForCompany(
        companyId: companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        quotes = loadedQuotes;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not load quotes: $error';
        isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'draft' => Colors.grey.shade700,
      'sent' => Colors.blue.shade700,
      'approved' => Colors.green.shade700,
      'rejected' => Colors.red.shade700,
      _ => Colors.blueGrey.shade700,
    };
  }

  Future<void> _openAddQuoteForm() async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuoteFormScreen(companyContext: companyContext),
      ),
    );

    if (didSave == true) {
      await loadQuotes();
    }
  }

  Future<void> _openEditQuoteForm(Quote quote) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            QuoteFormScreen(companyContext: companyContext, quote: quote),
      ),
    );

    if (didSave == true) {
      await loadQuotes();
    }
  }

  Future<void> _openQuoteProposal(Quote quote) async {
    try {
      final lineItems = await quoteService.getQuoteLineItems(quoteId: quote.id);
      final customer = await customerService.getCustomerById(quote.customerId);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuoteProposalScreen(
            companyContext: companyContext,
            quote: quote.copyWith(lineItems: lineItems),
            lineItems: lineItems,
            customer: customer,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open proposal: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManageQuotes =
        companyContext.isPrimaryAdmin ||
        companyContext.isCfo ||
        companyContext.isAdmin ||
        companyContext.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [
          IconButton(
            tooltip: 'Refresh quotes',
            onPressed: isLoading ? null : loadQuotes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManageQuotes
          ? FloatingActionButton.extended(
              onPressed: _openAddQuoteForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Quote'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: loadQuotes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Quotes',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Create and track customer estimates before they become projects.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (quotes.isEmpty)
              _EmptyQuotesCard(
                canManageQuotes: canManageQuotes,
                onAddQuote: _openAddQuoteForm,
              )
            else
              ...quotes.map(
                (quote) => _QuoteCard(
                  quote: quote,
                  statusColor: _statusColor(quote.status),
                  showInternalMetrics: companyContext.hasExecutiveAccess,
                  onTap: () => _openEditQuoteForm(quote),
                  onViewProposal: () => _openQuoteProposal(quote),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuotesCard extends StatelessWidget {
  const _EmptyQuotesCard({
    required this.canManageQuotes,
    required this.onAddQuote,
  });

  final bool canManageQuotes;
  final VoidCallback onAddQuote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No quotes yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quotes will help bridge leads, customers, and projects.',
              textAlign: TextAlign.center,
            ),
            if (canManageQuotes) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddQuote,
                icon: const Icon(Icons.add),
                label: const Text('Add Quote'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.statusColor,
    required this.showInternalMetrics,
    required this.onTap,
    required this.onViewProposal,
  });

  final Quote quote;
  final Color statusColor;
  final bool showInternalMetrics;
  final VoidCallback onTap;
  final VoidCallback onViewProposal;

  String formatCurrency(double value) {
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

  @override
  Widget build(BuildContext context) {
    final marginText = '${quote.estimatedMarginPercent.toStringAsFixed(1)}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    quote.quoteNumber,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      quote.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quote.title.isEmpty ? 'Untitled Quote' : quote.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (quote.notes != null && quote.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  quote.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricPill(
                    label: 'Base Price',
                    value: formatCurrency(quote.subtotal),
                  ),
                  _MetricPill(
                    label: 'Customer Total',
                    value: formatCurrency(quote.totalAmount),
                    isBold: true,
                  ),
                  if (showInternalMetrics) ...[
                    _MetricPill(
                      label: 'Cost Basis',
                      value: formatCurrency(quote.estimatedCost),
                    ),
                    _MetricPill(
                      label: 'Estimated Profit',
                      value: formatCurrency(quote.estimatedProfit),
                    ),
                    _MetricPill(label: 'Estimated Margin', value: marginText),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: onViewProposal,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('View Proposal'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Quote'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
