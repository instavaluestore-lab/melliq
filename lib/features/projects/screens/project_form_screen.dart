import 'package:flutter/material.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../customers/models/customer.dart';
import '../services/project_service.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    super.key,
    required this.companyContext,
    required this.customer,
  });

  final CompanyContext companyContext;
  final Customer customer;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final formKey = GlobalKey<FormState>();

  final projectNameController = TextEditingController();
  final projectNumberController = TextEditingController();
  final addressLine1Controller = TextEditingController();
  final addressLine2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController(text: 'USA');
  final notesController = TextEditingController();

  late final ProjectService projectService;

  String status = 'contract';
  String priority = 'normal';
  bool isSaving = false;
  bool isLoadingProjectNumber = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    projectService = ProjectService(Supabase.instance.client);
    loadNextProjectNumber();
  }

  @override
  void dispose() {
    projectNameController.dispose();
    projectNumberController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    notesController.dispose();
    super.dispose();
  }


  Future<void> loadNextProjectNumber() async {
    try {
      final nextProjectNumber = await projectService.getNextProjectNumber(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        projectNumberController.text = nextProjectNumber;
        isLoadingProjectNumber = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoadingProjectNumber = false;
      });
    }
  }

  Future<void> saveProject() async {
    setState(() {
      errorMessage = null;
    });

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await projectService.createProjectForCustomer(
        companyId: widget.companyContext.companyId,
        customerId: widget.customer.id,
        createdBy: widget.companyContext.userId,
        projectName: projectNameController.text,
        projectNumber: projectNumberController.text,
        addressLine1: addressLine1Controller.text,
        addressLine2: addressLine2Controller.text,
        city: cityController.text,
        state: stateController.text,
        postalCode: postalCodeController.text,
        country: countryController.text,
        status: status,
        priority: priority,
        notes: notesController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageNavigationButtons(),
            const SizedBox(height: 16),
            const Text(
              'New Project',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign this project to ${widget.customer.displayName}.',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _FormCard(
              children: [
                TextFormField(
                  controller: projectNameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Project name',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Project name is required.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: projectNumberController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Project number',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Project number is required.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'contract',
                      child: Text('Contract'),
                    ),
                    DropdownMenuItem(
                      value: 'ordered_material',
                      child: Text('Ordered Material'),
                    ),
                    DropdownMenuItem(
                      value: 'structure_fabrication',
                      child: Text('Structure Fabrication'),
                    ),
                    DropdownMenuItem(
                      value: 'powder_coating',
                      child: Text('Powder Coating'),
                    ),
                    DropdownMenuItem(
                      value: 'footers',
                      child: Text('Footers'),
                    ),
                    DropdownMenuItem(
                      value: 'sail_fabrication',
                      child: Text('Sail Fabrication'),
                    ),
                    DropdownMenuItem(
                      value: 'installation',
                      child: Text('Installation'),
                    ),
                    DropdownMenuItem(
                      value: 'final_invoice',
                      child: Text('Final Invoice'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            status = value;
                          });
                        },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text('Normal'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: 'urgent',
                      child: Text('Urgent'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            priority = value;
                          });
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: addressLine1Controller,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Address line 1',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: addressLine2Controller,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Address line 2',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: cityController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'City',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: stateController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'State',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: postalCodeController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Postal code',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: countryController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: notesController,
                  enabled: !isSaving,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : saveProject,
              child: isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          children: children,
        ),
      ),
    );
  }
}
