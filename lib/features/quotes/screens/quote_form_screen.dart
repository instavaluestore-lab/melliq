import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../customers/models/customer.dart';
import '../../customers/services/customer_service.dart';
import '../models/quote.dart';
import '../models/quote_line_item.dart';
import '../services/quote_service.dart';

class QuoteFormScreen extends StatefulWidget {
  const QuoteFormScreen({
    super.key,
    required this.companyContext,
    this.quote,
  });

  final CompanyContext companyContext;
  final Quote? quote;

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  late final CustomerService customerService;
  late final QuoteService quoteService;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final markupController = TextEditingController(text: '0');
  final taxController = TextEditingController(text: '0');
  final discountController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Customer> customers = [];
  String? selectedCustomerId;
  String selectedStatus = 'draft';
  List<_QuoteLineItemEditor> lineItems = [];

  bool get isEditing => widget.quote != null;

  CompanyContext get companyContext => widget.companyContext;

  @override
  void initState() {
    super.initState();
    customerService = CustomerService(Supabase.instance.client);
    quoteService = QuoteService(Supabase.instance.client);
    _loadInitialData();
  }

  @override
  void dispose() {
    titleController.dispose();
    markupController.dispose();
    taxController.dispose();
    discountController.dispose();
    notesController.dispose();

    for (final item in lineItems) {
      item.dispose();
    }

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedCustomers = await customerService.getCustomersForCompany(
        companyContext.companyId,
      );

      final quote = widget.quote;
      List<QuoteLineItem> loadedLineItems = [];

      if (quote != null) {
        loadedLineItems = await quoteService.getQuoteLineItems(
          quoteId: quote.id,
        );
      }

      if (!mounted) return;

      setState(() {
        customers = loadedCustomers;

        if (quote != null) {
          selectedCustomerId = quote.customerId;
          selectedStatus = quote.status;
          titleController.text = quote.title;
          markupController.text = quote.markupPercent.toStringAsFixed(2);
          taxController.text = quote.taxPercent.toStringAsFixed(2);
          discountController.text = quote.discountAmount.toStringAsFixed(2);
          notesController.text = quote.notes ?? '';
          lineItems = loadedLineItems
              .map(_QuoteLineItemEditor.fromSavedLineItem)
              .toList();
        } else {
          selectedCustomerId =
              loadedCustomers.isEmpty ? null : loadedCustomers.first.id;
          lineItems = [_QuoteLineItemEditor.empty(sortOrder: 0)];
        }

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not load quote form: $error';
        isLoading = false;
      });
    }
  }

  double _parseMoney(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;
  }

  double _parsePercent(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;
  }

  List<QuoteDraftLineItem> _draftLineItems() {
    return lineItems
        .where((item) => item.nameController.text.trim().isNotEmpty)
        .map(
          (item) => QuoteDraftLineItem(
            itemType: item.itemType,
            name: item.nameController.text,
            description: item.descriptionController.text,
            quantity: item.quantity,
            unit: item.unitController.text,
            unitCost: item.unitCost,
            unitPrice: item.unitPrice,
            sortOrder: lineItems.indexOf(item),
          ),
        )
        .toList();
  }

  QuoteTotals _totals() {
    return quoteService.calculateTotals(
      lineItems: _draftLineItems(),
      markupPercent: _parsePercent(markupController),
      taxPercent: _parsePercent(taxController),
      discountAmount: _parseMoney(discountController),
    );
  }

  String _formatCurrency(double value) {
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

  void _addLineItem() {
    setState(() {
      lineItems.add(_QuoteLineItemEditor.empty(sortOrder: lineItems.length));
    });
  }

  void _removeLineItem(_QuoteLineItemEditor item) {
    if (lineItems.length == 1) {
      item.clear();
      setState(() {});
      return;
    }

    setState(() {
      lineItems.remove(item);
      item.dispose();
    });
  }

  Future<void> _saveQuote() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCustomerId == null) {
      setState(() {
        errorMessage = 'Select a customer before saving the quote.';
      });
      return;
    }

    final draftLineItems = _draftLineItems();

    if (draftLineItems.isEmpty) {
      setState(() {
        errorMessage = 'Add at least one quote line item.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      if (widget.quote == null) {
        await quoteService.createQuote(
          companyId: companyContext.companyId,
          customerId: selectedCustomerId!,
          title: titleController.text,
          status: selectedStatus,
          markupPercent: _parsePercent(markupController),
          taxPercent: _parsePercent(taxController),
          discountAmount: _parseMoney(discountController),
          lineItems: draftLineItems,
          notes: notesController.text,
        );
      } else {
        await quoteService.updateQuote(
          quoteId: widget.quote!.id,
          companyId: companyContext.companyId,
          customerId: selectedCustomerId!,
          title: titleController.text,
          status: selectedStatus,
          markupPercent: _parsePercent(markupController),
          taxPercent: _parsePercent(taxController),
          discountAmount: _parseMoney(discountController),
          lineItems: draftLineItems,
          leadId: widget.quote!.leadId,
          notes: notesController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not save quote: $error';
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quote' : 'Add Quote'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              onChanged: () => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  if (customers.isEmpty)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No customers found. Create a customer before adding a quote.',
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: customers.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedCustomerId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Select a customer';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quote title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a quote title';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'sent', child: Text('Sent')),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pricing',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: TextFormField(
                          controller: markupController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Markup %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextFormField(
                          controller: taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tax %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextFormField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Discount \$',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Line Items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...lineItems.map(
                    (item) => _LineItemCard(
                      item: item,
                      onChanged: () => setState(() {}),
                      onRemove: () => _removeLineItem(item),
                      formatCurrency: _formatCurrency,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Line Item'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TotalsCard(
                    totals: totals,
                    formatCurrency: _formatCurrency,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: notesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Internal quote notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isSaving || customers.isEmpty ? null : _saveQuote,
                    icon: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save Quote'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _QuoteLineItemEditor {
  _QuoteLineItemEditor({
    required this.itemType,
    required this.nameController,
    required this.descriptionController,
    required this.quantityController,
    required this.unitController,
    required this.unitCostController,
    required this.unitPriceController,
  });

  String itemType;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController unitCostController;
  final TextEditingController unitPriceController;

  double get quantity => _parseDouble(quantityController.text);
  double get unitCost => _parseDouble(unitCostController.text);
  double get unitPrice => _parseDouble(unitPriceController.text);
  double get totalCost => quantity * unitCost;
  double get totalPrice => quantity * unitPrice;

  factory _QuoteLineItemEditor.empty({required int sortOrder}) {
    return _QuoteLineItemEditor(
      itemType: 'material',
      nameController: TextEditingController(),
      descriptionController: TextEditingController(),
      quantityController: TextEditingController(text: '1'),
      unitController: TextEditingController(text: 'each'),
      unitCostController: TextEditingController(text: '0'),
      unitPriceController: TextEditingController(text: '0'),
    );
  }

  factory _QuoteLineItemEditor.fromSavedLineItem(QuoteLineItem item) {
    return _QuoteLineItemEditor(
      itemType: item.itemType,
      nameController: TextEditingController(text: item.name),
      descriptionController: TextEditingController(text: item.description ?? ''),
      quantityController: TextEditingController(
        text: item.quantity.toStringAsFixed(2),
      ),
      unitController: TextEditingController(text: item.unit),
      unitCostController: TextEditingController(
        text: item.unitCost.toStringAsFixed(2),
      ),
      unitPriceController: TextEditingController(
        text: item.unitPrice.toStringAsFixed(2),
      ),
    );
  }

  void clear() {
    itemType = 'material';
    nameController.clear();
    descriptionController.clear();
    quantityController.text = '1';
    unitController.text = 'each';
    unitCostController.text = '0';
    unitPriceController.text = '0';
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitController.dispose();
    unitCostController.dispose();
    unitPriceController.dispose();
  }

  static double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }
}

class _LineItemCard extends StatelessWidget {
  const _LineItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
    required this.formatCurrency,
  });

  final _QuoteLineItemEditor item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: item.itemType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'labor',
                        child: Text('Labor'),
                      ),
                      DropdownMenuItem(
                        value: 'material',
                        child: Text('Material'),
                      ),
                      DropdownMenuItem(
                        value: 'equipment',
                        child: Text('Equipment'),
                      ),
                      DropdownMenuItem(
                        value: 'subcontractor',
                        child: Text('Subcontractor'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      item.itemType = value;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove line item',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter item name';
                }

                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.descriptionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: item.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: item.unitCostController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: item.unitPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line total: ${formatCurrency(item.totalPrice)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totals,
    required this.formatCurrency,
  });

  final QuoteTotals totals;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(
            alpha: 0.35,
          ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _TotalMetric(
              label: 'Subtotal',
              value: formatCurrency(totals.subtotal),
            ),
            _TotalMetric(
              label: 'Markup',
              value: formatCurrency(totals.markupAmount),
            ),
            _TotalMetric(
              label: 'Tax',
              value: formatCurrency(totals.taxAmount),
            ),
            _TotalMetric(
              label: 'Total',
              value: formatCurrency(totals.totalAmount),
              isBold: true,
            ),
            _TotalMetric(
              label: 'Est. Cost',
              value: formatCurrency(totals.estimatedCost),
            ),
            _TotalMetric(
              label: 'Est. Profit',
              value: formatCurrency(totals.estimatedProfit),
            ),
            _TotalMetric(
              label: 'Margin',
              value: '${totals.estimatedMarginPercent.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalMetric extends StatelessWidget {
  const _TotalMetric({
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
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
