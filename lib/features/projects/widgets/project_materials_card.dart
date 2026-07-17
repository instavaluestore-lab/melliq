import 'package:flutter/material.dart';

import '../models/material_item.dart';

class ProjectMaterialsCard extends StatelessWidget {
  const ProjectMaterialsCard({
    super.key,
    required this.materials,
    required this.enabled,
    required this.canManageMaterials,
    required this.canDeleteMaterials,
    required this.canUpdateStatus,
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onUpdateMaterialStatus,
  });

  final List<MaterialItem> materials;
  final bool enabled;
  final bool canManageMaterials;
  final bool canDeleteMaterials;
  final bool canUpdateStatus;
  final VoidCallback onAddMaterial;
  final ValueChanged<MaterialItem> onEditMaterial;
  final ValueChanged<MaterialItem> onDeleteMaterial;
  final void Function(MaterialItem material, String status) onUpdateMaterialStatus;

  @override
  Widget build(BuildContext context) {
    final totalCost = materials.fold<double>(
      0,
      (sum, material) => sum + material.totalCost,
    );

    final orderedCount = materials
        .where((material) => material.status == 'ordered')
        .length;

    final receivedCount = materials
        .where((material) => material.status == 'received')
        .length;

    final installedCount = materials
        .where((material) => material.status == 'installed')
        .length;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Project Materials',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MaterialMetricPill(
                  label: 'Items',
                  value: materials.length.toString(),
                ),
                _MaterialMetricPill(
                  label: 'Total',
                  value: '\$${totalCost.toStringAsFixed(2)}',
                ),
                _MaterialMetricPill(
                  label: 'Ordered',
                  value: orderedCount.toString(),
                ),
                _MaterialMetricPill(
                  label: 'Received',
                  value: receivedCount.toString(),
                ),
                _MaterialMetricPill(
                  label: 'Installed',
                  value: installedCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enabled && canManageMaterials ? onAddMaterial : null,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Material'),
              ),
            ),
            const SizedBox(height: 16),
            if (materials.isEmpty)
              const Text(
                'No materials added yet. Track shade fabric, hardware, anchors, concrete materials, powder coating, and install supplies here.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.45,
                ),
              )
            else
              ...materials.map(
                (material) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MaterialTile(
                    material: material,
                    enabled: enabled,
                    onEdit: () => onEditMaterial(material),
                    onDelete: () => onDeleteMaterial(material),
                    onUpdateStatus: (status) {
                      onUpdateMaterialStatus(material, status);
                    },
                    canEditMaterial: canManageMaterials,
                    canDeleteMaterial: canDeleteMaterials,
                    canUpdateStatus: canUpdateStatus,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MaterialDialog extends StatefulWidget {
  const MaterialDialog({
    super.key,
    this.material,
    required this.onSave,
  });

  final MaterialItem? material;
  final Future<void> Function({
    required String name,
    required String category,
    required double quantity,
    required String unit,
    required double unitCost,
    required String supplier,
    required String status,
  }) onSave;

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController quantityController;
  late final TextEditingController unitController;
  late final TextEditingController unitCostController;
  late final TextEditingController supplierController;

  late String selectedStatus;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final material = widget.material;

    nameController = TextEditingController(text: material?.name ?? '');
    categoryController = TextEditingController(text: material?.category ?? '');
    quantityController = TextEditingController(
      text: material == null ? '1' : material.quantity.toString(),
    );
    unitController = TextEditingController(text: material?.unit ?? 'each');
    unitCostController = TextEditingController(
      text: material == null ? '0' : material.unitCost.toStringAsFixed(2),
    );
    supplierController = TextEditingController(text: material?.supplier ?? '');
    selectedStatus = material?.status ?? 'needed';
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    unitController.dispose();
    unitCostController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final unitCost = double.tryParse(unitCostController.text.trim()) ?? 0;

    if (name.isEmpty) {
      setState(() {
        errorMessage = 'Material name is required.';
      });
      return;
    }

    if (quantity <= 0) {
      setState(() {
        errorMessage = 'Quantity must be greater than 0.';
      });
      return;
    }

    if (unitCost < 0) {
      setState(() {
        errorMessage = 'Unit cost cannot be negative.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await widget.onSave(
        name: name,
        category: categoryController.text,
        quantity: quantity,
        unit: unitController.text,
        unitCost: unitCost,
        supplier: supplierController.text,
        status: selectedStatus,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.material != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Material' : 'Add Material'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Material name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Fabric, hardware, concrete, coating...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      enabled: !isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'each, bags, yards...',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCostController,
                enabled: !isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Unit cost',
                  prefixText: '\$',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _CalculatedMaterialTotal(
                quantityText: quantityController.text,
                unitCostText: unitCostController.text,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Supplier / vendor',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'needed',
                    child: Text('Needed'),
                  ),
                  DropdownMenuItem(
                    value: 'ordered',
                    child: Text('Ordered'),
                  ),
                  DropdownMenuItem(
                    value: 'received',
                    child: Text('Received'),
                  ),
                  DropdownMenuItem(
                    value: 'installed',
                    child: Text('Installed'),
                  ),
                ],
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedStatus = value;
                        });
                      },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Save Material' : 'Add Material'),
        ),
      ],
    );
  }
}


class _CalculatedMaterialTotal extends StatelessWidget {
  const _CalculatedMaterialTotal({
    required this.quantityText,
    required this.unitCostText,
  });

  final String quantityText;
  final String unitCostText;

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(quantityText.trim()) ?? 0;
    final unitCost = double.tryParse(unitCostText.trim()) ?? 0;
    final total = quantity * unitCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          const Text(
            'Calculated total',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.material,
    required this.enabled,
    required this.canEditMaterial,
    required this.canDeleteMaterial,
    required this.canUpdateStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStatus,
  });

  final MaterialItem material;
  final bool enabled;
  final bool canEditMaterial;
  final bool canDeleteMaterial;
  final bool canUpdateStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (material.status) {
      'needed' => const Color(0xFF92400E),
      'ordered' => const Color(0xFF1D4ED8),
      'received' => const Color(0xFF047857),
      'installed' => const Color(0xFF166534),
      _ => const Color(0xFF334155),
    };

    final statusBackground = switch (material.status) {
      'needed' => const Color(0xFFFFF7ED),
      'ordered' => const Color(0xFFEFF6FF),
      'received' => const Color(0xFFECFDF5),
      'installed' => const Color(0xFFF0FDF4),
      _ => const Color(0xFFF8FAFC),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${material.categoryLabel} • ${material.quantityLabel} • ${material.unitCostLabel}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (material.supplier != null &&
                    material.supplier!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Supplier: ${material.supplier}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MaterialChip(
                      label: material.statusLabel,
                      textColor: statusColor,
                      backgroundColor: statusBackground,
                    ),
                    _MaterialChip(
                      label: material.totalCostLabel,
                      textColor: const Color(0xFF0F172A),
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Update status',
                enabled: enabled && canUpdateStatus,
                icon: const Icon(Icons.sync_alt_outlined),
                onSelected: onUpdateStatus,
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(value: 'needed', child: Text('Needed')),
                    PopupMenuItem(value: 'ordered', child: Text('Ordered')),
                    PopupMenuItem(value: 'received', child: Text('Received')),
                    PopupMenuItem(value: 'installed', child: Text('Installed')),
                  ];
                },
              ),
              IconButton(
                onPressed: enabled && canEditMaterial ? onEdit : null,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit material',
              ),
              IconButton(
                onPressed: enabled && canDeleteMaterial ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete material',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialMetricPill extends StatelessWidget {
  const _MaterialMetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  const _MaterialChip({
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
