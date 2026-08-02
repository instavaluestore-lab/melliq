import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../audit/models/record_audit_log.dart';
import '../../audit/services/audit_log_service.dart';
import '../../company/models/company_context.dart';
import '../models/quote_addon_price.dart';
import '../models/standard_structure_price.dart';
import '../services/quote_addon_price_service.dart';
import '../services/standard_structure_price_service.dart';

class QuotePricingAdminScreen extends StatefulWidget {
  const QuotePricingAdminScreen({super.key, required this.companyContext});

  final CompanyContext companyContext;

  @override
  State<QuotePricingAdminScreen> createState() =>
      _QuotePricingAdminScreenState();
}

class _QuotePricingAdminScreenState extends State<QuotePricingAdminScreen> {
  late final StandardStructurePriceService standardStructurePriceService;
  late final QuoteAddonPriceService quoteAddonPriceService;
  late final AuditLogService auditLogService;

  bool isLoading = true;
  bool showHiddenPricing = false;
  String? errorMessage;

  List<StandardStructurePrice> structurePrices = [];
  List<StandardStructurePrice> hiddenStructurePrices = [];
  List<QuoteAddonPrice> addonPrices = [];
  List<QuoteAddonPrice> hiddenAddonPrices = [];
  List<RecordAuditLog> pricingAuditLogs = [];

  @override
  void initState() {
    super.initState();
    standardStructurePriceService = StandardStructurePriceService(
      Supabase.instance.client,
    );
    quoteAddonPriceService = QuoteAddonPriceService(Supabase.instance.client);
    auditLogService = AuditLogService(Supabase.instance.client);
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedStructurePrices = await standardStructurePriceService
          .getActivePrices(companyId: widget.companyContext.companyId);

      final loadedHiddenStructurePrices = await standardStructurePriceService
          .getHiddenPrices(companyId: widget.companyContext.companyId);

      final loadedAddonPrices = await quoteAddonPriceService.getActivePrices(
        companyId: widget.companyContext.companyId,
      );

      final loadedHiddenAddonPrices = await quoteAddonPriceService
          .getHiddenPrices(companyId: widget.companyContext.companyId);

      final loadedAuditLogs = await auditLogService.getRecentLogsForCompany(
        companyId: widget.companyContext.companyId,
        limit: 100,
      );

      final loadedPricingAuditLogs = loadedAuditLogs
          .where((log) => log.recordType.startsWith('pricing_'))
          .toList();

      if (!mounted) return;

      setState(() {
        structurePrices = loadedStructurePrices;
        hiddenStructurePrices = loadedHiddenStructurePrices;
        addonPrices = loadedAddonPrices;
        hiddenAddonPrices = loadedHiddenAddonPrices;
        pricingAuditLogs = loadedPricingAuditLogs;
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

  Widget _dialogActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 132,
      height: 42,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _logPricingAction({
    required String recordType,
    required String recordId,
    required String action,
    required String summary,
    String? fieldName,
    String? oldValue,
    String? newValue,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await auditLogService.logAction(
        companyId: widget.companyContext.companyId,
        recordType: recordType,
        recordId: recordId,
        action: action,
        summary: summary,
        fieldName: fieldName,
        oldValue: oldValue,
        newValue: newValue,
        metadata: metadata,
      );
    } catch (_) {
      // Pricing changes should not fail just because audit logging failed.
    }
  }

  String _pricingAuditRecordId({
    required String itemType,
    required String itemKey,
  }) {
    return '$itemType:$itemKey';
  }

  Future<double?> _showMoneyDialog({
    required String title,
    required String label,
    required double currentValue,
  }) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              prefixText: '\$',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            _dialogActionButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            _dialogActionButton(
              label: 'Save',
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.trim().replaceAll(',', ''),
                );

                if (parsed == null || parsed < 0) return;

                Navigator.of(context).pop(parsed);
              },
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<void> _editStructurePrice(StandardStructurePrice price) async {
    final newPrice = await _showMoneyDialog(
      title: 'Edit ${price.structureName} ${price.sizeOnlyLabel}',
      label: 'Structure Price',
      currentValue: price.price,
    );

    if (newPrice == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await standardStructurePriceService.updatePrice(
        companyId: widget.companyContext.companyId,
        price: price,
        unitPrice: newPrice,
      );

      await _logPricingAction(
        recordType: 'pricing_standard_structure',
        recordId: price.id,
        action: 'edit',
        summary:
            'Updated ${price.structureName} ${price.sizeOnlyLabel} from ${_formatMoney(price.price)} to ${_formatMoney(newPrice)}.',
        fieldName: 'price',
        oldValue: _formatMoney(price.price),
        newValue: _formatMoney(newPrice),
        metadata: {
          'structure_type': price.structureType,
          'structure_name': price.structureName,
          'size_label': price.sizeOnlyLabel,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${price.structureName} ${price.sizeOnlyLabel} updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _addStructurePrice(String structureType) async {
    final lengthController = TextEditingController();
    final widthController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<_NewStructurePriceDraft>(
      context: context,
      builder: (context) {
        Widget actionButton({
          required String label,
          required VoidCallback onPressed,
        }) {
          return Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton.tonal(
                onPressed: onPressed,
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return AlertDialog(
          title: Text('Add ${_structureLabel(structureType)} Size'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: lengthController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Length Feet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Width Feet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    actionButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    actionButton(
                      label: 'Add Size',
                      onPressed: () {
                        final length = double.tryParse(
                          lengthController.text.trim().replaceAll(',', ''),
                        );
                        final width = double.tryParse(
                          widthController.text.trim().replaceAll(',', ''),
                        );
                        final price = double.tryParse(
                          priceController.text.trim().replaceAll(',', ''),
                        );

                        if (length == null ||
                            length <= 0 ||
                            width == null ||
                            width <= 0 ||
                            price == null ||
                            price < 0) {
                          return;
                        }

                        Navigator.of(context).pop(
                          _NewStructurePriceDraft(
                            lengthFeet: length,
                            widthFeet: width,
                            price: price,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    lengthController.dispose();
    widthController.dispose();
    priceController.dispose();

    if (result == null) return;

    final existingPrices = _structurePricesByType[structureType] ?? [];
    final nextSortOrder = existingPrices.isEmpty
        ? 0
        : existingPrices
                  .map((price) => price.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await standardStructurePriceService.addPrice(
        companyId: widget.companyContext.companyId,
        structureType: structureType,
        structureName: _structureName(structureType),
        lengthFeet: result.lengthFeet,
        widthFeet: result.widthFeet,
        unitPrice: result.price,
        sortOrder: nextSortOrder,
      );

      await _logPricingAction(
        recordType: 'pricing_standard_structure',
        recordId: _pricingAuditRecordId(
          itemType: 'standard_structure',
          itemKey:
              '$structureType:${result.lengthFeet.toString()}:${result.widthFeet.toString()}',
        ),
        action: 'add',
        summary:
            'Added ${_structureLabel(structureType)} ${result.lengthFeet.toStringAsFixed(0)} ft × ${result.widthFeet.toStringAsFixed(0)} ft at ${_formatMoney(result.price)}.',
        fieldName: 'price',
        newValue: _formatMoney(result.price),
        metadata: {
          'structure_type': structureType,
          'structure_name': _structureName(structureType),
          'length_feet': result.lengthFeet,
          'width_feet': result.widthFeet,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_structureLabel(structureType)} size added.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteStructurePrice(StandardStructurePrice price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Size'),
          content: Text(
            'Delete ${price.structureName} ${price.sizeOnlyLabel}? Company-added rows will be removed. Global default rows will be hidden for this company.',
          ),
          actions: [
            _dialogActionButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            _dialogActionButton(
              label: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await standardStructurePriceService.deletePrice(
        companyId: widget.companyContext.companyId,
        price: price,
      );

      await _logPricingAction(
        recordType: 'pricing_standard_structure',
        recordId: price.id,
        action: 'delete',
        summary: 'Deleted ${price.structureName} ${price.sizeOnlyLabel}.',
        fieldName: 'is_active',
        oldValue: 'true',
        newValue: 'false',
        metadata: {
          'structure_type': price.structureType,
          'structure_name': price.structureName,
          'size_label': price.sizeOnlyLabel,
          'price': price.price,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${price.structureName} ${price.sizeOnlyLabel} deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _restoreStructurePrice(StandardStructurePrice price) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await standardStructurePriceService.restorePrice(
        companyId: widget.companyContext.companyId,
        price: price,
      );

      await _logPricingAction(
        recordType: 'pricing_standard_structure',
        recordId: price.id,
        action: 'restore',
        summary: 'Restored ${price.structureName} ${price.sizeOnlyLabel}.',
        fieldName: 'is_active',
        oldValue: 'false',
        newValue: 'true',
        metadata: {
          'structure_type': price.structureType,
          'structure_name': price.structureName,
          'size_label': price.sizeOnlyLabel,
          'price': price.price,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${price.structureName} ${price.sizeOnlyLabel} restored.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _editAddonPrice(QuoteAddonPrice price) async {
    final newPrice = await _showMoneyDialog(
      title: 'Edit ${price.addonName}',
      label: 'Unit Price',
      currentValue: price.unitPrice,
    );

    if (newPrice == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await quoteAddonPriceService.updatePrice(
        companyId: widget.companyContext.companyId,
        price: price,
        unitPrice: newPrice,
      );

      await _logPricingAction(
        recordType: 'pricing_quote_addon',
        recordId: price.id,
        action: 'edit',
        summary:
            'Updated ${price.addonName} from ${_formatMoney(price.unitPrice)} to ${_formatMoney(newPrice)}.',
        fieldName: 'unit_price',
        oldValue: _formatMoney(price.unitPrice),
        newValue: _formatMoney(newPrice),
        metadata: {
          'addon_key': price.addonKey,
          'addon_name': price.addonName,
          'addon_type': price.addonType,
          'unit': price.unit,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${price.addonName} updated.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAddonPrice(QuoteAddonPrice price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Add-On'),
          content: Text(
            'Delete ${price.addonName}? Company-added rows will be removed. Global default rows will be hidden for this company.',
          ),
          actions: [
            _dialogActionButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            _dialogActionButton(
              label: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await quoteAddonPriceService.deletePrice(
        companyId: widget.companyContext.companyId,
        price: price,
      );

      await _logPricingAction(
        recordType: 'pricing_quote_addon',
        recordId: price.id,
        action: 'delete',
        summary: 'Deleted ${price.addonName}.',
        fieldName: 'is_active',
        oldValue: 'true',
        newValue: 'false',
        metadata: {
          'addon_key': price.addonKey,
          'addon_name': price.addonName,
          'addon_type': price.addonType,
          'unit': price.unit,
          'unit_price': price.unitPrice,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${price.addonName} deleted.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _restoreAddonPrice(QuoteAddonPrice price) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await quoteAddonPriceService.restorePrice(
        companyId: widget.companyContext.companyId,
        price: price,
      );

      await _logPricingAction(
        recordType: 'pricing_quote_addon',
        recordId: price.id,
        action: 'restore',
        summary: 'Restored ${price.addonName}.',
        fieldName: 'is_active',
        oldValue: 'false',
        newValue: 'true',
        metadata: {
          'addon_key': price.addonKey,
          'addon_name': price.addonName,
          'addon_type': price.addonType,
          'unit': price.unit,
          'unit_price': price.unitPrice,
        },
      );

      await _loadPricing();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${price.addonName} restored.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Map<String, List<StandardStructurePrice>> get _structurePricesByType {
    final grouped = <String, List<StandardStructurePrice>>{};

    for (final price in structurePrices) {
      grouped.putIfAbsent(price.structureType, () => []).add(price);
    }

    return grouped;
  }

  String _structureLabel(String structureType) {
    switch (structureType) {
      case 'HR':
        return 'Hip Roof';
      case 'SP':
        return 'Single Post Pyramid';
      case 'CL':
        return 'Cantilever';
      case 'SWC':
        return 'Slanted Wing Cantilever';
      default:
        return structureType;
    }
  }

  String _structureName(String structureType) {
    switch (structureType) {
      case 'HR':
        return 'Hip Roof Structure';
      case 'SP':
        return 'Single Post Pyramid';
      case 'CL':
        return 'Cantilever Structure';
      case 'SWC':
        return 'Slanted Wing Cantilever';
      default:
        return structureType;
    }
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.companyContext.hasExecutiveAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quote Pricing Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to manage quote pricing.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Pricing Admin'),
        actions: [
          IconButton(
            tooltip: 'Refresh pricing',
            onPressed: isLoading ? null : _loadPricing,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPricing,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Quote Pricing Admin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Primary Admin and CFO pricing controls.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
            else ...[
              _AddonPricingCard(
                addonPrices: addonPrices,
                formatMoney: _formatMoney,
                onEditPrice: _editAddonPrice,
                onDeletePrice: _deleteAddonPrice,
              ),
              const SizedBox(height: 16),
              _StructurePricingCard(
                groupedPrices: _structurePricesByType,
                structureLabel: _structureLabel,
                formatMoney: _formatMoney,
                onEditPrice: _editStructurePrice,
                onAddPrice: _addStructurePrice,
                onDeletePrice: _deleteStructurePrice,
              ),
              const SizedBox(height: 16),
              _HiddenPricingCard(
                showHiddenPricing: showHiddenPricing,
                hiddenStructurePrices: hiddenStructurePrices,
                hiddenAddonPrices: hiddenAddonPrices,
                structureLabel: _structureLabel,
                formatMoney: _formatMoney,
                onToggleShowHidden: (value) {
                  setState(() {
                    showHiddenPricing = value;
                  });
                },
                onRestoreStructurePrice: _restoreStructurePrice,
                onRestoreAddonPrice: _restoreAddonPrice,
              ),
              const SizedBox(height: 16),
              _PricingAuditCard(logs: pricingAuditLogs),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewStructurePriceDraft {
  const _NewStructurePriceDraft({
    required this.lengthFeet,
    required this.widthFeet,
    required this.price,
  });

  final double lengthFeet;
  final double widthFeet;
  final double price;
}

class _AddonPricingCard extends StatelessWidget {
  const _AddonPricingCard({
    required this.addonPrices,
    required this.formatMoney,
    required this.onEditPrice,
    required this.onDeletePrice,
  });

  final List<QuoteAddonPrice> addonPrices;
  final String Function(double value) formatMoney;
  final ValueChanged<QuoteAddonPrice> onEditPrice;
  final ValueChanged<QuoteAddonPrice> onDeletePrice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Footer and Mount Pricing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (addonPrices.isEmpty)
              const Text('No add-on prices found.')
            else
              ...addonPrices.map(
                (price) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(price.addonName),
                  subtitle: Text('${price.addonType} • ${price.unit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMoney(price.unitPrice),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Edit price',
                        onPressed: () => onEditPrice(price),
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PricingAuditCard extends StatelessWidget {
  const _PricingAuditCard({required this.logs});

  final List<RecordAuditLog> logs;

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  String _createdByLabel(String? createdBy) {
    if (createdBy == null || createdBy.trim().isEmpty) {
      return 'Unknown user';
    }

    if (createdBy.length <= 8) return createdBy;

    return '${createdBy.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing Audit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Recent pricing changes for this company.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Text('No pricing audit logs yet.')
            else
              ...logs
                  .take(25)
                  .map(
                    (log) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(log.summary),
                      subtitle: Text(
                        '${log.action} • ${log.recordType} • ${_formatDateTime(log.createdAt)} • ${_createdByLabel(log.createdBy)}',
                      ),
                      trailing: log.fieldName == null
                          ? null
                          : Text(
                              log.fieldName!,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HiddenPricingCard extends StatelessWidget {
  const _HiddenPricingCard({
    required this.showHiddenPricing,
    required this.hiddenStructurePrices,
    required this.hiddenAddonPrices,
    required this.structureLabel,
    required this.formatMoney,
    required this.onToggleShowHidden,
    required this.onRestoreStructurePrice,
    required this.onRestoreAddonPrice,
  });

  final bool showHiddenPricing;
  final List<StandardStructurePrice> hiddenStructurePrices;
  final List<QuoteAddonPrice> hiddenAddonPrices;
  final String Function(String structureType) structureLabel;
  final String Function(double value) formatMoney;
  final ValueChanged<bool> onToggleShowHidden;
  final ValueChanged<StandardStructurePrice> onRestoreStructurePrice;
  final ValueChanged<QuoteAddonPrice> onRestoreAddonPrice;

  @override
  Widget build(BuildContext context) {
    final hiddenCount = hiddenStructurePrices.length + hiddenAddonPrices.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Hidden Pricing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text('$hiddenCount hidden pricing rows'),
              value: showHiddenPricing,
              onChanged: onToggleShowHidden,
            ),
            if (showHiddenPricing) ...[
              const SizedBox(height: 12),
              Text(
                'Hidden Footer and Mount Pricing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (hiddenAddonPrices.isEmpty)
                const Text('No hidden add-on prices.')
              else
                ...hiddenAddonPrices.map(
                  (price) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(price.addonName),
                    subtitle: Text(
                      '${price.addonType} • ${price.unit} • ${formatMoney(price.unitPrice)}',
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: () => onRestoreAddonPrice(price),
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                    ),
                  ),
                ),
              const Divider(height: 32),
              Text(
                'Hidden Standard Structure Pricing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (hiddenStructurePrices.isEmpty)
                const Text('No hidden structure prices.')
              else
                ...hiddenStructurePrices.map(
                  (price) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${structureLabel(price.structureType)} ${price.sizeOnlyLabel}',
                    ),
                    subtitle: Text(
                      '${price.lengthFeetFormatted} ft × ${price.widthFeetFormatted} ft • ${formatMoney(price.price)}',
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: () => onRestoreStructurePrice(price),
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StructurePricingCard extends StatelessWidget {
  const _StructurePricingCard({
    required this.groupedPrices,
    required this.structureLabel,
    required this.formatMoney,
    required this.onEditPrice,
    required this.onAddPrice,
    required this.onDeletePrice,
  });

  final Map<String, List<StandardStructurePrice>> groupedPrices;
  final String Function(String structureType) structureLabel;
  final String Function(double value) formatMoney;
  final ValueChanged<StandardStructurePrice> onEditPrice;
  final ValueChanged<String> onAddPrice;
  final ValueChanged<StandardStructurePrice> onDeletePrice;

  @override
  Widget build(BuildContext context) {
    final structureTypes = groupedPrices.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standard Structure Pricing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (structureTypes.isEmpty)
              const Text('No standard structure prices found.')
            else
              ...structureTypes.map((structureType) {
                final prices = groupedPrices[structureType] ?? [];

                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(structureLabel(structureType)),
                  subtitle: Text('${prices.length} active price rows'),
                  children: [
                    ...prices.map(
                      (price) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price.sizeOnlyLabel,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${price.lengthFeetFormatted} ft × ${price.widthFeetFormatted} ft • ${formatMoney(price.price)}',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => onEditPrice(price),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Price'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onDeletePrice(price),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete Size'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => onAddPrice(structureType),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Add ${structureLabel(structureType)} Size',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
