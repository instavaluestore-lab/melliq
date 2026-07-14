import 'package:flutter/material.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../projects/models/project.dart';
import '../../projects/screens/project_form_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/project_service.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.companyContext,
    required this.customer,
  });

  final CompanyContext companyContext;
  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late final CustomerService customerService;
  late final ProjectService projectService;

  bool isLoading = true;
  String? errorMessage;
  late Customer customer;
  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    customerService = CustomerService(Supabase.instance.client);
    projectService = ProjectService(Supabase.instance.client);
    customer = widget.customer;
    loadCustomerDetail();
  }

  Future<void> loadCustomerDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final freshCustomer = await customerService.getCustomerById(customer.id);

      final customerProjects = await projectService.getProjectsForCustomer(
        companyId: widget.companyContext.companyId,
        customerId: customer.id,
      );

      if (!mounted) return;

      setState(() {
        customer = freshCustomer;
        projects = customerProjects;
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

  Future<void> openEditCustomer() async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(
          companyContext: widget.companyContext,
          customer: customer,
        ),
      ),
    );

    if (didUpdate == true) {
      await loadCustomerDetail();
    }
  }

  Future<void> openAddProject() async {
    final didCreate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectFormScreen(
          companyContext: widget.companyContext,
          customer: customer,
        ),
      ),
    );

    if (didCreate == true) {
      await loadCustomerDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = isLoading
        ? const [
            _StateCard(
              title: 'Loading customer...',
              body: 'Fetching the latest customer record and projects.',
            ),
          ]
        : errorMessage != null
            ? [
                _StateCard(
                  title: 'Could not load customer',
                  body: errorMessage!,
                ),
              ]
            : [
                Text(
                  customer.displayName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  customer.companyName?.trim().isNotEmpty == true
                      ? customer.companyName!
                      : 'No company name',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _ProjectsCard(
                  companyContext: widget.companyContext,
                  projects: projects,
                  onAddProject: openAddProject,
                  onProjectUpdated: loadCustomerDetail,
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Contact Information',
                  children: [
                    _DetailRow(
                      label: 'First Name',
                      value: customer.firstName,
                    ),
                    _DetailRow(
                      label: 'Last Name',
                      value: customer.lastName,
                    ),
                    _DetailRow(
                      label: 'Company',
                      value: customer.companyName,
                    ),
                    _DetailRow(
                      label: 'Email',
                      value: customer.email,
                    ),
                    _DetailRow(
                      label: 'Phone',
                      value: customer.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Location',
                  children: [
                    _DetailRow(
                      label: 'City',
                      value: customer.city,
                    ),
                    _DetailRow(
                      label: 'State',
                      value: customer.state,
                    ),
                    _DetailRow(
                      label: 'Display Location',
                      value: customer.location,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Customer Status',
                  children: [
                    _DetailRow(
                      label: 'Customer Type',
                      value: customer.customerTypeLabel,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: customer.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Notes',
                  children: [
                    Text(
                      customer.notes?.trim().isNotEmpty == true
                          ? customer.notes!
                          : 'No notes yet.',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _FutureModulesCard(),
              ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : openEditCustomer,
            child: const Text('Edit'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: PageNavigationButtons(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadCustomerDetail,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsCard extends StatelessWidget {
  const _ProjectsCard({
    required this.companyContext,
    required this.projects,
    required this.onAddProject,
    required this.onProjectUpdated,
  });

  final CompanyContext companyContext;
  final List<Project> projects;
  final VoidCallback onAddProject;
  final Future<void> Function() onProjectUpdated;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Projects',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAddProject,
                  child: const Text('Add Project'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (projects.isEmpty)
              const Text(
                'No projects assigned to this customer yet.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 15,
                  height: 1.45,
                ),
              )
            else
              ...projects.map(
                (project) => _ProjectRow(
                  project: project,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(
                          companyContext: companyContext,
                          project: project,
                        ),
                      ),
                    );

                    await onProjectUpdated();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final projectNumber = project.projectNumber.trim().isNotEmpty
        ? project.projectNumber
        : 'No project number';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.folder_open,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectNumber,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.displayLocation,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(status: project.statusLabel),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.children,
  });

  final String title;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue =
        value == null || value!.trim().isEmpty ? 'Not provided' : value!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureModulesCard extends StatelessWidget {
  const _FutureModulesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming Next',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This customer profile will later connect to quotes, files, notes, tasks, materials, expenses, and activity history.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
