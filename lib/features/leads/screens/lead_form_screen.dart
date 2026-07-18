import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';

class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({
    super.key,
    required this.companyContext,
    this.lead,
  });

  final CompanyContext companyContext;
  final Lead? lead;

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  late final LeadService leadService;

  final titleController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final estimatedValueController = TextEditingController();
  final addressLine1Controller = TextEditingController();
  final addressLine2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController(text: 'US');
  final notesController = TextEditingController();

  String selectedSource = 'other';
  String selectedStatus = 'new';
  bool isSaving = false;
  String? errorMessage;

  bool get isEditing => widget.lead != null;

  @override
  void initState() {
    super.initState();
    leadService = LeadService(Supabase.instance.client);

    final lead = widget.lead;
    if (lead != null) {
      titleController.text = lead.title;
      contactNameController.text = lead.contactName ?? '';
      contactEmailController.text = lead.contactEmail ?? '';
      contactPhoneController.text = lead.contactPhone ?? '';
      estimatedValueController.text =
          lead.estimatedValue == 0 ? '' : lead.estimatedValue.toStringAsFixed(2);
      addressLine1Controller.text = lead.addressLine1 ?? '';
      addressLine2Controller.text = lead.addressLine2 ?? '';
      cityController.text = lead.city ?? '';
      stateController.text = lead.state ?? '';
      postalCodeController.text = lead.postalCode ?? '';
      countryController.text = lead.country;
      notesController.text = lead.notes ?? '';
      selectedSource = lead.source;
      selectedStatus = lead.status;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contactNameController.dispose();
    contactEmailController.dispose();
    contactPhoneController.dispose();
    estimatedValueController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> saveLead() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Lead title is required.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final estimatedValue =
          double.tryParse(estimatedValueController.text.trim()) ?? 0;

      if (isEditing) {
        await leadService.updateLead(
          id: widget.lead!.id,
          title: title,
          source: selectedSource,
          status: selectedStatus,
          estimatedValue: estimatedValue,
          contactName: contactNameController.text,
          contactEmail: contactEmailController.text,
          contactPhone: contactPhoneController.text,
          addressLine1: addressLine1Controller.text,
          addressLine2: addressLine2Controller.text,
          city: cityController.text,
          state: stateController.text,
          postalCode: postalCodeController.text,
          country: countryController.text,
          notes: notesController.text,
        );
      } else {
        await leadService.createLead(
          companyId: widget.companyContext.companyId,
          title: title,
          source: selectedSource,
          status: selectedStatus,
          estimatedValue: estimatedValue,
          contactName: contactNameController.text,
          contactEmail: contactEmailController.text,
          contactPhone: contactPhoneController.text,
          addressLine1: addressLine1Controller.text,
          addressLine2: addressLine2Controller.text,
          city: cityController.text,
          state: stateController.text,
          postalCode: postalCodeController.text,
          country: countryController.text,
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
    final canEdit = widget.companyContext.isPrimaryAdmin ||
        widget.companyContext.isCfo ||
        widget.companyContext.isAdmin ||
        widget.companyContext.isManager;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lead' : 'Add Lead'),
        actions: [
          TextButton(
            onPressed: isSaving || !canEdit ? null : saveLead,
            child: Text(isSaving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.companyContext.companyName,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEditing ? 'Edit Lead' : 'New Lead',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture a sales opportunity before it becomes a quote or project.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          if (!canEdit)
            const _InfoCard(
              title: 'Read-only access',
              body: 'Your role can view leads but cannot create or edit them.',
            ),
          if (errorMessage != null) ...[
            _InfoCard(title: 'Could not save lead', body: errorMessage!),
            const SizedBox(height: 12),
          ],
          _SectionCard(
            title: 'Lead Details',
            children: [
              TextField(
                controller: titleController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(
                  labelText: 'Lead title',
                  hintText: 'Example: Smith backyard shade structure',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New')),
                  DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                  DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                  DropdownMenuItem(
                    value: 'proposal_needed',
                    child: Text('Proposal Needed'),
                  ),
                  DropdownMenuItem(
                    value: 'proposal_sent',
                    child: Text('Proposal Sent'),
                  ),
                  DropdownMenuItem(value: 'won', child: Text('Won')),
                  DropdownMenuItem(value: 'lost', child: Text('Lost')),
                ],
                onChanged: isSaving || !canEdit
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          selectedStatus = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSource,
                decoration: const InputDecoration(labelText: 'Lead source'),
                items: const [
                  DropdownMenuItem(value: 'website', child: Text('Website')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'referral', child: Text('Referral')),
                  DropdownMenuItem(
                    value: 'repeat_customer',
                    child: Text('Repeat Customer'),
                  ),
                  DropdownMenuItem(
                    value: 'social_media',
                    child: Text('Social Media'),
                  ),
                  DropdownMenuItem(value: 'walk_in', child: Text('Walk-in')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: isSaving || !canEdit
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          selectedSource = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: estimatedValueController,
                enabled: !isSaving && canEdit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated value',
                  prefixText: r'$',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Contact',
            children: [
              TextField(
                controller: contactNameController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'Contact name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactEmailController,
                enabled: !isSaving && canEdit,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Contact email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPhoneController,
                enabled: !isSaving && canEdit,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Location',
            children: [
              TextField(
                controller: addressLine1Controller,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'Address line 1'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressLine2Controller,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'Address line 2'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: postalCodeController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'Postal code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryController,
                enabled: !isSaving && canEdit,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notes',
            children: [
              TextField(
                controller: notesController,
                enabled: !isSaving && canEdit,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Lead notes',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSaving || !canEdit ? null : saveLead,
            child: Text(isSaving ? 'Saving Lead...' : 'Save Lead'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
