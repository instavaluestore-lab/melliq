import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool isLoading = true;
  String? errorMessage;

  List<StandardStructurePrice> structurePrices = [];
  List<QuoteAddonPrice> addonPrices = [];

  @override
  void initState() {
    super.initState();
    standardStructurePriceService = StandardStructurePriceService(
      Supabase.instance.client,
    );
    quoteAddonPriceService = QuoteAddonPriceService(Supabase.instance.client);
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

      final loadedAddonPrices = await quoteAddonPriceService.getActivePrices(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        structurePrices = loadedStructurePrices;
        addonPrices = loadedAddonPrices;
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

  Future<void> _editAddonPrice(QuoteAddonPrice price) async {
    final controller = TextEditingController(
      text: price.unitPrice.toStringAsFixed(2),
    );

    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${price.addonName}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Unit Price',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.trim().replaceAll(',', ''),
                );

                if (parsed == null || parsed < 0) {
                  return;
                }

                Navigator.of(context).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

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
              ),
              const SizedBox(height: 16),
              _StructurePricingCard(
                groupedPrices: _structurePricesByType,
                structureLabel: _structureLabel,
                formatMoney: _formatMoney,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddonPricingCard extends StatelessWidget {
  const _AddonPricingCard({
    required this.addonPrices,
    required this.formatMoney,
    required this.onEditPrice,
  });

  final List<QuoteAddonPrice> addonPrices;
  final String Function(double value) formatMoney;
  final ValueChanged<QuoteAddonPrice> onEditPrice;

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

class _StructurePricingCard extends StatelessWidget {
  const _StructurePricingCard({
    required this.groupedPrices,
    required this.structureLabel,
    required this.formatMoney,
  });

  final Map<String, List<StandardStructurePrice>> groupedPrices;
  final String Function(String structureType) structureLabel;
  final String Function(double value) formatMoney;

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
                  children: prices
                      .map(
                        (price) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(price.sizeLabel),
                          subtitle: Text(
                            '${price.lengthFeetFormatted} ft × ${price.widthFeetFormatted} ft',
                          ),
                          trailing: Text(
                            formatMoney(price.price),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
          ],
        ),
      ),
    );
  }
}
