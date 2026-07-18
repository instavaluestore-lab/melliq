import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import '../../company/models/company_context.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({
    super.key,
    required this.companyContext,
  });

  final CompanyContext companyContext;

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  late final ProjectService projectService;
  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';
  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    projectService = ProjectService(Supabase.instance.client);
    loadProjects();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final companyProjects = await projectService.getProjectsForCompany(
        companyId: widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        projects = companyProjects;
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

  List<Project> get filteredProjects {
    final query = searchController.text.trim().toLowerCase();

    return projects.where((project) {
      final matchesStatus =
          selectedStatus == 'all' || project.status == selectedStatus;

      final searchableText = [
        project.projectName,
        project.projectNumber,
        project.statusLabel,
        project.displayLocation,
        project.priority,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get activeProjectCount {
    return projects.where((project) => project.status != 'completed').length;
  }

  double get openProjectValue {
    return projects
        .where((project) => project.status != 'completed')
        .fold<double>(0, (total, project) => total + project.contractAmount);
  }

  double get openProjectProfit {
    return projects
        .where((project) => project.status != 'completed')
        .fold<double>(0, (total, project) => total + project.actualProfit);
  }

  String _formatMoney(double value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${value.abs().toStringAsFixed(2)}';
  }

  Future<void> openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          companyContext: widget.companyContext,
          project: project,
        ),
      ),
    );

    await loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final visibleProjects = filteredProjects;
    final canViewFinancials = widget.companyContext.canViewFinancials;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: PageNavigationButtons(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadProjects,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Text(
                    'Project Records',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View all active MaxShade projects, job stage status, contract value, cost, and profit snapshots.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProjectsSummaryStrip(
                    activeProjects: activeProjectCount,
                    totalProjects: projects.length,
                    openProjectValue: openProjectValue,
                    openProjectProfit: openProjectProfit,
                    canViewFinancials: canViewFinancials,
                    formatMoney: _formatMoney,
                  ),
                  const SizedBox(height: 18),
                  _SearchAndFilterCard(
                    searchController: searchController,
                    selectedStatus: selectedStatus,
                    onSearchChanged: () {
                      setState(() {});
                    },
                    onStatusChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (isLoading)
                    const _StateCard(
                      title: 'Loading projects...',
                      body: 'Fetching current MaxShade project records.',
                    )
                  else if (errorMessage != null)
                    _StateCard(
                      title: 'Could not load projects',
                      body: errorMessage!,
                    )
                  else if (projects.isEmpty)
                    const _StateCard(
                      title: 'No projects found',
                      body:
                          'Create a project from a customer record first. Projects will appear here automatically.',
                    )
                  else if (visibleProjects.isEmpty)
                    const _StateCard(
                      title: 'No matching projects',
                      body:
                          'Try clearing the search box or changing the status filter.',
                    )
                  else
                    ...visibleProjects.map(
                      (project) => _ProjectListCard(
                        project: project,
                        canViewFinancials: canViewFinancials,
                        formatMoney: _formatMoney,
                        onTap: () => openProject(project),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsSummaryStrip extends StatelessWidget {
  const _ProjectsSummaryStrip({
    required this.activeProjects,
    required this.totalProjects,
    required this.openProjectValue,
    required this.openProjectProfit,
    required this.canViewFinancials,
    required this.formatMoney,
  });

  final int activeProjects;
  final int totalProjects;
  final double openProjectValue;
  final double openProjectProfit;
  final bool canViewFinancials;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryPill(
          title: 'Active',
          value: activeProjects.toString(),
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFFEFF6FF),
        ),
        _SummaryPill(
          title: 'Total',
          value: totalProjects.toString(),
          color: const Color(0xFF0F172A),
          backgroundColor: const Color(0xFFF8FAFC),
        ),
        _SummaryPill(
          title: 'Open Value',
          value: canViewFinancials ? formatMoney(openProjectValue) : 'Hidden',
          color: const Color(0xFF15803D),
          backgroundColor: const Color(0xFFF0FDF4),
        ),
        _SummaryPill(
          title: 'Open Profit',
          value: canViewFinancials ? formatMoney(openProjectProfit) : 'Hidden',
          color: const Color(0xFFC2410C),
          backgroundColor: const Color(0xFFFFF7ED),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterCard extends StatelessWidget {
  const _SearchAndFilterCard({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String selectedStatus;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (_) => onSearchChanged(),
              decoration: const InputDecoration(
                labelText: 'Search projects',
                hintText: 'Search by name, number, status, or location',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status Filter',
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Projects')),
                DropdownMenuItem(value: 'contract', child: Text('Contract')),
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
                DropdownMenuItem(value: 'footers', child: Text('Footers')),
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
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value == null) return;
                onStatusChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  const _ProjectListCard({
    required this.project,
    required this.canViewFinancials,
    required this.formatMoney,
    required this.onTap,
  });

  final Project project;
  final bool canViewFinancials;
  final String Function(double value) formatMoney;
  final VoidCallback onTap;

  Color get accentColor {
    switch (project.status) {
      case 'contract':
        return const Color(0xFF2563EB);
      case 'ordered_material':
        return const Color(0xFFF97316);
      case 'structure_fabrication':
        return const Color(0xFF7C3AED);
      case 'powder_coating':
        return const Color(0xFFDB2777);
      case 'footers':
        return const Color(0xFF0891B2);
      case 'sail_fabrication':
        return const Color(0xFF16A34A);
      case 'installation':
        return const Color(0xFFD97706);
      case 'final_invoice':
        return const Color(0xFF475569);
      case 'completed':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF334155);
    }
  }

  Color get shellColor {
    switch (project.status) {
      case 'contract':
        return const Color(0xFFEFF6FF);
      case 'ordered_material':
        return const Color(0xFFFFF7ED);
      case 'structure_fabrication':
        return const Color(0xFFF5F3FF);
      case 'powder_coating':
        return const Color(0xFFFDF2F8);
      case 'footers':
        return const Color(0xFFECFEFF);
      case 'sail_fabrication':
        return const Color(0xFFF0FDF4);
      case 'installation':
        return const Color(0xFFFFFBEB);
      case 'final_invoice':
        return const Color(0xFFF8FAFC);
      case 'completed':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectNumber = project.projectNumber.trim().isNotEmpty
        ? project.projectNumber
        : 'No project number';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: shellColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 126,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accentColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniPill(
                              label: project.statusLabel,
                              color: accentColor,
                              backgroundColor: shellColor,
                            ),
                            _MiniPill(
                              label: projectNumber,
                              color: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                            ),
                            _MiniPill(
                              label: project.priority.toUpperCase(),
                              color: const Color(0xFFC2410C),
                              backgroundColor: const Color(0xFFFFF7ED),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          project.displayLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MoneyBucket(
                              label: 'Contract',
                              value: canViewFinancials ? formatMoney(project.contractAmount) : 'Hidden',
                            ),
                            _MoneyBucket(
                              label: 'Cost',
                              value: canViewFinancials
                                  ? formatMoney(project.actualCost)
                                  : 'Hidden',
                            ),
                            _MoneyBucket(
                              label: 'Profit',
                              value: canViewFinancials
                                  ? formatMoney(project.actualProfit)
                                  : 'Hidden',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right,
                  color: accentColor,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MoneyBucket extends StatelessWidget {
  const _MoneyBucket({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w900,
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
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF475569),
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
