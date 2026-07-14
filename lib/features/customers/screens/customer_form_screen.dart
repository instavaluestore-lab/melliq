import 'package:flutter/material.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    super.key,
    required this.companyContext,
    this.customer,
  });

  final CompanyContext companyContext;
  final Customer? customer;

  bool get isEditing => customer != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final notesController = TextEditingController();

  late final CustomerService customerService;

  String customerType = 'residential';
  String status = 'active';
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    customerService = CustomerService(Supabase.instance.client);

    final customer = widget.customer;

    if (customer != null) {
      firstNameController.text = customer.firstName ?? '';
      lastNameController.text = customer.lastName ?? '';
      companyNameController.text = customer.companyName ?? '';
      emailController.text = customer.email ?? '';
      phoneController.text = customer.phone ?? '';
      cityController.text = customer.city ?? '';
      stateController.text = customer.state ?? '';
      notesController.text = customer.notes ?? '';
      customerType = customer.customerType;
      status = customer.status;
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    stateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  bool get hasAtLeastOneName {
    return firstNameController.text.trim().isNotEmpty ||
        lastNameController.text.trim().isNotEmpty ||
        companyNameController.text.trim().isNotEmpty;
  }

  Future<void> saveCustomer() async {
    setState(() {
      errorMessage = null;
    });

    if (!hasAtLeastOneName) {
      setState(() {
        errorMessage =
            'Enter at least a first name, last name, or company name.';
      });
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await customerService.updateCustomer(
          customerId: widget.customer!.id,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          companyName: companyNameController.text,
          email: emailController.text,
          phone: phoneController.text,
          city: cityController.text,
          state: stateController.text,
          customerType: customerType,
          status: status,
          notes: notesController.text,
        );
      } else {
        await customerService.createCustomer(
          companyId: widget.companyContext.companyId,
          createdBy: widget.companyContext.userId,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          companyName: companyNameController.text,
          email: emailController.text,
          phone: phoneController.text,
          city: cityController.text,
          state: stateController.text,
          customerType: customerType,
          notes: notesController.text,
        );
      }

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
    final title = widget.isEditing ? 'Edit Customer' : 'Add Customer';
    final subtitle = widget.isEditing
        ? 'Update this customer record.'
        : 'Add a residential, commercial, or contractor customer record.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageNavigationButtons(),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _FormCard(
              children: [
                TextFormField(
                  controller: firstNameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: lastNameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: companyNameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return null;
                    }

                    if (!text.contains('@')) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
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
                DropdownButtonFormField<String>(
                  initialValue: customerType,
                  decoration: const InputDecoration(
                    labelText: 'Customer type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'residential',
                      child: Text('Residential'),
                    ),
                    DropdownMenuItem(
                      value: 'commercial',
                      child: Text('Commercial'),
                    ),
                    DropdownMenuItem(
                      value: 'government',
                      child: Text('Government'),
                    ),
                    DropdownMenuItem(
                      value: 'property_manager',
                      child: Text('Property Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'contractor',
                      child: Text('Contractor'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            customerType = value;
                          });
                        },
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'archived',
                        child: Text('Archived'),
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
                ],
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
              onPressed: isSaving ? null : saveCustomer,
              child: isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.isEditing ? 'Save Changes' : 'Save Customer'),
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
