import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../customers/models/customer.dart';
import '../../customers/services/customer_service.dart';
import '../../projects/services/project_service.dart';
import '../../audit/services/audit_log_service.dart';
import '../models/quote.dart';
import '../models/quote_line_item.dart';
import '../models/standard_structure_price.dart';
import '../models/quote_addon_price.dart';
import '../services/quote_service.dart';
import '../services/standard_structure_price_service.dart';
import '../services/quote_addon_price_service.dart';

class QuoteFormScreen extends StatefulWidget {
  const QuoteFormScreen({super.key, required this.companyContext, this.quote});

  final CompanyContext companyContext;
  final Quote? quote;

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  late final CustomerService customerService;
  late final QuoteService quoteService;
  late final StandardStructurePriceService standardStructurePriceService;
  late final QuoteAddonPriceService quoteAddonPriceService;
  late final ProjectService projectService;
  late final AuditLogService auditLogService;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final markupController = TextEditingController(text: '75');
  final taxController = TextEditingController(text: '0');
  final discountController = TextEditingController(text: '0');
  final notesController = TextEditingController();
  final footerQuantityController = TextEditingController(text: '1');

  bool isLoading = true;
  bool isSaving = false;
  bool isConverting = false;
  String? errorMessage;

  List<Customer> customers = [];
  String? selectedCustomerId;
  String selectedStatus = 'draft';
  String? selectedStructureType;
  String? selectedMountType;
  String? selectedFooterType;
  bool permitRequired = false;
  bool specialtyEquipmentRequired = false;
  List<_QuoteLineItemEditor> lineItems = [];
  List<StandardStructurePrice> standardStructurePrices = [];
  List<QuoteAddonPrice> quoteAddonPrices = [];
  String? selectedStandardStructurePriceId;

  bool get isEditing => widget.quote != null;

  CompanyContext get companyContext => widget.companyContext;

  void _adjustMarkup(double delta) {
    final current = _parsePercent(markupController);
    final next = (current + delta).clamp(0, 500).toDouble();

    setState(() {
      markupController.text = next.toStringAsFixed(0);
    });
  }

  bool get canConvertToProject {
    return isEditing &&
        selectedStatus == 'approved' &&
        widget.quote?.isConverted != true;
  }

  @override
  void initState() {
    super.initState();
    customerService = CustomerService(Supabase.instance.client);
    quoteService = QuoteService(Supabase.instance.client);
    standardStructurePriceService = StandardStructurePriceService(
      Supabase.instance.client,
    );
    quoteAddonPriceService = QuoteAddonPriceService(Supabase.instance.client);
    projectService = ProjectService(Supabase.instance.client);
    auditLogService = AuditLogService(Supabase.instance.client);
    _loadInitialData();
  }

  @override
  void dispose() {
    titleController.dispose();
    markupController.dispose();
    taxController.dispose();
    discountController.dispose();
    notesController.dispose();
    footerQuantityController.dispose();

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

      final loadedStandardStructurePrices = await standardStructurePriceService
          .getActivePrices(companyId: widget.companyContext.companyId);

      final loadedQuoteAddonPrices = await quoteAddonPriceService
          .getActivePrices(companyId: widget.companyContext.companyId);

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
        standardStructurePrices = loadedStandardStructurePrices;
        quoteAddonPrices = loadedQuoteAddonPrices;

        if (quote != null) {
          selectedCustomerId = quote.customerId;
          selectedStatus = quote.status;
          selectedStructureType = quote.structureType;
          selectedMountType = quote.mountType;
          selectedFooterType = quote.footerType;
          permitRequired = quote.permitRequired;
          specialtyEquipmentRequired = quote.specialtyEquipmentRequired;
          titleController.text = quote.title;
          markupController.text = quote.markupPercent.toStringAsFixed(2);
          taxController.text = quote.taxPercent.toStringAsFixed(2);
          discountController.text = '0';
          notesController.text = quote.notes ?? '';
          lineItems = loadedLineItems
              .map(_QuoteLineItemEditor.fromSavedLineItem)
              .toList();
        } else {
          selectedCustomerId = loadedCustomers.isEmpty
              ? null
              : loadedCustomers.first.id;
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

  double _discountAmount() {
    final discountPercent = _parsePercent(discountController);
    if (discountPercent <= 0) return 0;

    final draftItems = _draftLineItems();
    final subtotal = draftItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final markupAmount = subtotal * (_parsePercent(markupController) / 100);

    return (subtotal + markupAmount) * (discountPercent / 100);
  }

  QuoteTotals _totals() {
    return quoteService.calculateTotals(
      lineItems: _draftLineItems(),
      markupPercent: _parsePercent(markupController),
      taxPercent: _parsePercent(taxController),
      discountAmount: _discountAmount(),
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

  void _popWithResult(bool result) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    });
  }

  List<StandardStructurePrice> get _pricesForSelectedStructure {
    final structureType = selectedStructureType;
    if (structureType == null || structureType.isEmpty) return [];

    return standardStructurePrices
        .where((price) => price.structureType == structureType)
        .toList();
  }

  bool get _selectedStructureUsesStandardPricing {
    return selectedStructureType == 'HR' ||
        selectedStructureType == 'SP' ||
        selectedStructureType == 'CL' ||
        selectedStructureType == 'SWC';
  }

  QuoteAddonPrice? _addonPriceByKey(String addonKey) {
    for (final price in quoteAddonPrices) {
      if (price.addonKey == addonKey) return price;
    }

    return null;
  }

  double get _footerQuantity {
    final parsed = double.tryParse(
      footerQuantityController.text.trim().replaceAll(',', ''),
    );

    if (parsed == null || parsed <= 0) return 1;

    return parsed;
  }

  void _upsertAddonLineItem({
    required String marker,
    required String itemType,
    required String name,
    required String unit,
    required double quantity,
    required double unitPrice,
  }) {
    final editor = _QuoteLineItemEditor(
      itemType: itemType,
      nameController: TextEditingController(text: name),
      descriptionController: TextEditingController(text: marker),
      quantityController: TextEditingController(
        text: quantity.toStringAsFixed(0),
      ),
      unitController: TextEditingController(text: unit),
      unitCostController: TextEditingController(text: '0'),
      unitPriceController: TextEditingController(
        text: unitPrice.toStringAsFixed(2),
      ),
    );

    final existingIndex = lineItems.indexWhere(
      (item) => item.descriptionController.text.trim() == marker,
    );

    if (existingIndex >= 0) {
      final oldItem = lineItems[existingIndex];
      lineItems[existingIndex] = editor;
      oldItem.dispose();
    } else {
      lineItems.add(editor);
    }
  }

  void _removeAddonLineItem(String marker) {
    final index = lineItems.indexWhere(
      (item) => item.descriptionController.text.trim() == marker,
    );

    if (index < 0) return;

    final oldItem = lineItems.removeAt(index);
    oldItem.dispose();

    if (lineItems.isEmpty) {
      lineItems.add(_QuoteLineItemEditor.empty(sortOrder: 0));
    }
  }

  void _applyFooterPricing() {
    const footer2x2Marker = 'Auto-priced footer: standard_2x2x5.';
    const footer7x30Marker = 'Auto-priced footer: standard_7x30.';

    _removeAddonLineItem(footer2x2Marker);
    _removeAddonLineItem(footer7x30Marker);

    final footerType = selectedFooterType;
    if (footerType == null || footerType == 'custom') return;

    final addonKey = footerType == 'standard_2x2x5'
        ? 'footer_standard_2x2x5'
        : footerType == 'standard_7x30'
        ? 'footer_standard_7x30'
        : null;

    if (addonKey == null) return;

    final price = _addonPriceByKey(addonKey);
    if (price == null) return;

    _upsertAddonLineItem(
      marker: footerType == 'standard_2x2x5'
          ? footer2x2Marker
          : footer7x30Marker,
      itemType: 'material',
      name: price.addonName,
      unit: price.unit,
      quantity: _footerQuantity,
      unitPrice: price.unitPrice,
    );
  }

  void _applyMountPricing() {
    const marker = 'Auto-priced mount: base_plate.';

    if (selectedMountType != 'base_plate') {
      _removeAddonLineItem(marker);
      return;
    }

    final price = _addonPriceByKey('mount_base_plate');
    if (price == null) return;

    _upsertAddonLineItem(
      marker: marker,
      itemType: 'material',
      name: price.addonName,
      unit: price.unit,
      quantity: 1,
      unitPrice: price.unitPrice,
    );
  }

  void _applyStandardStructurePrice(String? priceId) {
    if (priceId == null || priceId.isEmpty) {
      setState(() {
        selectedStandardStructurePriceId = null;
      });
      return;
    }

    StandardStructurePrice? selectedPrice;
    for (final price in standardStructurePrices) {
      if (price.id == priceId) {
        selectedPrice = price;
        break;
      }
    }

    if (selectedPrice == null) return;

    final editor = _QuoteLineItemEditor(
      itemType: 'material',
      nameController: TextEditingController(text: selectedPrice.quoteLineName),
      descriptionController: TextEditingController(
        text: 'Standard structure price selected from pricing table.',
      ),
      quantityController: TextEditingController(text: '1'),
      unitController: TextEditingController(text: 'each'),
      unitCostController: TextEditingController(text: '0'),
      unitPriceController: TextEditingController(
        text: selectedPrice.price.toStringAsFixed(2),
      ),
    );

    final existingIndex = lineItems.indexWhere(
      (item) =>
          item.descriptionController.text.trim() ==
          'Standard structure price selected from pricing table.',
    );

    setState(() {
      selectedStandardStructurePriceId = priceId;

      if (existingIndex >= 0) {
        final oldItem = lineItems[existingIndex];
        lineItems[existingIndex] = editor;
        oldItem.dispose();
      } else {
        lineItems.insert(0, editor);
      }
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

    if (selectedStructureType == null) {
      setState(() {
        errorMessage = 'Select a structure type before saving the quote.';
      });
      return;
    }

    if (selectedMountType == null) {
      setState(() {
        errorMessage = 'Select a mount type before saving the quote.';
      });
      return;
    }

    if (selectedFooterType == null) {
      setState(() {
        errorMessage = 'Select a footer type before saving the quote.';
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
          discountAmount: _discountAmount(),
          lineItems: draftLineItems,
          structureType: selectedStructureType,
          mountType: selectedMountType,
          footerType: selectedFooterType,
          permitRequired: permitRequired,
          specialtyEquipmentRequired: specialtyEquipmentRequired,
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
          discountAmount: _discountAmount(),
          lineItems: draftLineItems,
          structureType: selectedStructureType,
          mountType: selectedMountType,
          footerType: selectedFooterType,
          permitRequired: permitRequired,
          specialtyEquipmentRequired: specialtyEquipmentRequired,
          leadId: widget.quote!.leadId,
          notes: notesController.text,
        );
      }

      if (!mounted) return;

      _popWithResult(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not save quote: $error';
        isSaving = false;
      });
    }
  }

  Future<void> _convertApprovedQuoteToProject() async {
    final quote = widget.quote;

    if (quote == null) {
      return;
    }

    if (quote.isConverted) {
      setState(() {
        errorMessage = 'This quote has already been converted to a project.';
      });
      return;
    }

    if (selectedStatus != 'approved') {
      setState(() {
        errorMessage = 'Only approved quotes can be converted to projects.';
      });
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        errorMessage = 'Could not identify the current user.';
      });
      return;
    }

    if (selectedCustomerId == null) {
      setState(() {
        errorMessage = 'Select a customer before converting this quote.';
      });
      return;
    }

    setState(() {
      isConverting = true;
      errorMessage = null;
    });

    try {
      final selectedCustomer = customers.firstWhere(
        (customer) => customer.id == selectedCustomerId,
      );

      final totals = _totals();

      final projectNumber = await projectService.getNextProjectNumber(
        companyId: companyContext.companyId,
      );

      final projectId = await projectService.createProjectForCustomer(
        companyId: companyContext.companyId,
        customerId: selectedCustomer.id,
        createdBy: userId,
        projectName: titleController.text.trim().isEmpty
            ? 'Project from ${quote.quoteNumber}'
            : titleController.text.trim(),
        projectNumber: projectNumber,
        addressLine1: '',
        addressLine2: '',
        city: selectedCustomer.city ?? '',
        state: selectedCustomer.state ?? '',
        postalCode: '',
        country: 'USA',
        status: 'contract',
        priority: 'normal',
        notes: [
          'Converted from quote ${quote.quoteNumber}.',
          if (notesController.text.trim().isNotEmpty)
            notesController.text.trim(),
        ].join('\n\n'),
        contractAmount: totals.totalAmount,
        estimatedCost: totals.estimatedCost,
        estimatedProfit: totals.estimatedProfit,
        sourceQuoteId: quote.id,
      );

      await quoteService.markQuoteConverted(
        quoteId: quote.id,
        projectId: projectId,
        convertedBy: userId,
      );

      await auditLogService.logAction(
        companyId: companyContext.companyId,
        recordType: 'quote',
        recordId: quote.id,
        action: 'converted_to_project',
        summary:
            'Quote ${quote.quoteNumber} was converted to project $projectNumber.',
        metadata: {
          'quote_id': quote.id,
          'quote_number': quote.quoteNumber,
          'project_id': projectId,
          'project_number': projectNumber,
          'customer_id': selectedCustomer.id,
          'contract_amount': totals.totalAmount,
          'estimated_cost': totals.estimatedCost,
          'estimated_profit': totals.estimatedProfit,
        },
      );

      await auditLogService.logAction(
        companyId: companyContext.companyId,
        recordType: 'project',
        recordId: projectId,
        action: 'created_from_quote',
        summary:
            'Project $projectNumber was created from quote ${quote.quoteNumber}.',
        metadata: {
          'quote_id': quote.id,
          'quote_number': quote.quoteNumber,
          'project_id': projectId,
          'project_number': projectNumber,
          'customer_id': selectedCustomer.id,
          'contract_amount': totals.totalAmount,
          'estimated_cost': totals.estimatedCost,
          'estimated_profit': totals.estimatedProfit,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approved quote converted to project.')),
      );

      _popWithResult(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not convert quote to project: $error';
        isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals();

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Quote' : 'Add Quote')),
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

                  const SizedBox(height: 16),
                  Text(
                    'Project Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStructureType,
                    decoration: const InputDecoration(
                      labelText: 'Structure Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'HT',
                        child: Text('High Tension Structure — HT'),
                      ),
                      DropdownMenuItem(
                        value: 'HR',
                        child: Text('Hip Roof Structure — HR'),
                      ),
                      DropdownMenuItem(
                        value: 'SP',
                        child: Text('Single Post — SP'),
                      ),
                      DropdownMenuItem(
                        value: 'CL',
                        child: Text('Cantilever Structure — CL'),
                      ),
                      DropdownMenuItem(
                        value: 'SWC',
                        child: Text('Slanted Wing Cantilever — SWC'),
                      ),
                      DropdownMenuItem(
                        value: 'CSTM',
                        child: Text('Custom — CSTM'),
                      ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() {
                              selectedStructureType = value;
                              selectedStandardStructurePriceId = null;
                            });
                          },
                  ),
                  if (_selectedStructureUsesStandardPricing) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStandardStructurePriceId,
                      decoration: InputDecoration(
                        labelText: 'Standard Size / Price',
                        border: const OutlineInputBorder(),
                        helperText: _pricesForSelectedStructure.isEmpty
                            ? 'No standard prices found for this structure yet.'
                            : 'Selecting a size adds or updates the structure line item.',
                      ),
                      items: _pricesForSelectedStructure
                          .map(
                            (price) => DropdownMenuItem(
                              value: price.id,
                              child: Text(price.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving || _pricesForSelectedStructure.isEmpty
                          ? null
                          : _applyStandardStructurePrice,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMountType,
                    decoration: const InputDecoration(
                      labelText: 'Mount Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'in_ground',
                        child: Text('In-Ground Mount'),
                      ),
                      DropdownMenuItem(
                        value: 'base_plate',
                        child: Text('Base Plate Mount'),
                      ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() {
                              selectedMountType = value;
                              _applyMountPricing();
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: footerQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Footer Quantity',
                      border: OutlineInputBorder(),
                      helperText: 'Used for standard footer pricing.',
                    ),
                    onChanged: (_) {
                      setState(() {
                        _applyFooterPricing();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFooterType,
                    decoration: const InputDecoration(
                      labelText: 'Footer Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'standard_2x2x5',
                        child: Text('Standard 2 × 2 × 5'),
                      ),
                      DropdownMenuItem(
                        value: 'standard_7x30',
                        child: Text('Standard 7 ft deep × 30 in diameter'),
                      ),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() {
                              selectedFooterType = value;
                              _applyFooterPricing();
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: permitRequired,
                    title: const Text('Permit Required'),
                    subtitle: Text(
                      permitRequired
                          ? 'Permit requirement will transfer to the project later.'
                          : 'No permit fee added at this stage.',
                    ),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() {
                              permitRequired = value;
                            });
                          },
                  ),
                  SwitchListTile(
                    value: specialtyEquipmentRequired,
                    title: const Text('Specialty Equipment Required'),
                    subtitle: Text(
                      specialtyEquipmentRequired
                          ? 'Equipment details will be added in the next phase.'
                          : 'No specialty equipment required.',
                    ),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() {
                              specialtyEquipmentRequired = value;
                            });
                          },
                  ),

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
                  _TotalsCard(totals: totals, formatCurrency: _formatCurrency),
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
                  const SizedBox(height: 20),
                  Text(
                    'Pricing Adjustments',
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
                        width: 260,
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Decrease markup',
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      _adjustMarkup(-1);
                                    },
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: markupController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Markup %',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Increase markup',
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      _adjustMarkup(1);
                                    },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: taxController.text.trim() == '8.25'
                              ? '8.25'
                              : '0',
                          decoration: const InputDecoration(
                            labelText: 'Tax',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '0',
                              child: Text('Tax Exempt'),
                            ),
                            DropdownMenuItem(
                              value: '8.25',
                              child: Text('8.25% Tax'),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    taxController.text = value;
                                  });
                                },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: discountController.text.trim().isEmpty
                              ? '0'
                              : discountController.text.trim(),
                          decoration: const InputDecoration(
                            labelText: 'Discount',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '0',
                              child: Text('No Discount'),
                            ),
                            DropdownMenuItem(value: '1', child: Text('1%')),
                            DropdownMenuItem(value: '2', child: Text('2%')),
                            DropdownMenuItem(value: '3', child: Text('3%')),
                            DropdownMenuItem(value: '4', child: Text('4%')),
                            DropdownMenuItem(value: '5', child: Text('5%')),
                            DropdownMenuItem(value: '6', child: Text('6%')),
                            DropdownMenuItem(value: '7', child: Text('7%')),
                            DropdownMenuItem(value: '8', child: Text('8%')),
                            DropdownMenuItem(value: '9', child: Text('9%')),
                            DropdownMenuItem(value: '10', child: Text('10%')),
                            DropdownMenuItem(value: '11', child: Text('11%')),
                            DropdownMenuItem(value: '12', child: Text('12%')),
                            DropdownMenuItem(value: '13', child: Text('13%')),
                            DropdownMenuItem(value: '14', child: Text('14%')),
                            DropdownMenuItem(value: '15', child: Text('15%')),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    discountController.text = value;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isSaving || isConverting || customers.isEmpty
                        ? null
                        : _saveQuote,
                    icon: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save Quote'),
                  ),
                  if (canConvertToProject) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isSaving || isConverting || customers.isEmpty
                          ? null
                          : _convertApprovedQuoteToProject,
                      icon: isConverting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_turned_in_outlined),
                      label: Text(
                        isConverting
                            ? 'Converting...'
                            : 'Convert Approved Quote to Project',
                      ),
                    ),
                  ],
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
      descriptionController: TextEditingController(
        text: item.description ?? '',
      ),
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
                      DropdownMenuItem(value: 'labor', child: Text('Labor')),
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
                      DropdownMenuItem(value: 'other', child: Text('Other')),
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals, required this.formatCurrency});

  final QuoteTotals totals;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.35),
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
            _TotalMetric(label: 'Tax', value: formatCurrency(totals.taxAmount)),
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
