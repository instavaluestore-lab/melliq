import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../../company/services/company_service.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../leads/screens/leads_list_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/user_notification_service.dart';
import '../../projects/screens/company_tasks_screen.dart';
import '../../projects/screens/projects_list_screen.dart';
import '../../quotes/screens/quotes_list_screen.dart';
import '../../quotes/screens/quote_pricing_admin_screen.dart';
import '../../projects/services/project_service.dart';
import '../../team/screens/team_members_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final CompanyService companyService;
  late final ProjectService projectService;
  late final UserNotificationService notificationService;
  late final Timer notificationRefreshTimer;

  bool isLoading = true;
  String? errorMessage;
  CompanyContext? companyContext;
  ProjectDashboardMetrics? projectMetrics;
  int unreadNotificationCount = 0;
  bool isRefreshingNotifications = false;

  @override
  void initState() {
    super.initState();
    companyService = CompanyService(Supabase.instance.client);
    projectService = ProjectService(Supabase.instance.client);
    notificationService = UserNotificationService(Supabase.instance.client);
    notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshUnreadNotificationCount(),
    );
    loadCompanyContext();
  }

  Future<void> loadCompanyContext() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final context = await companyService.getCurrentCompanyContext();

      final metrics = context == null
          ? null
          : await projectService.getCompanyDashboardMetrics(
              companyId: context.companyId,
            );

      var unreadCount = 0;
      if (context != null) {
        try {
          unreadCount = await notificationService.getUnreadCount(
            companyId: context.companyId,
          );
        } catch (_) {
          unreadCount = 0;
        }
      }

      if (!mounted) return;

      setState(() {
        companyContext = context;
        projectMetrics = metrics;
        unreadNotificationCount = unreadCount;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        projectMetrics = null;
        unreadNotificationCount = 0;
        isLoading = false;
      });
    }
  }

  Future<void> handleLogout() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> refreshUnreadNotificationCount() async {
    final context = companyContext;
    if (context == null || isRefreshingNotifications || !mounted) return;

    isRefreshingNotifications = true;

    try {
      final unreadCount = await notificationService.getUnreadCount(
        companyId: context.companyId,
      );

      if (!mounted || unreadCount == unreadNotificationCount) return;

      setState(() {
        unreadNotificationCount = unreadCount;
      });
    } catch (_) {
      // Keep the dashboard usable if a background refresh fails.
    } finally {
      isRefreshingNotifications = false;
    }
  }

  Future<void> openNotifications() async {
    final context = companyContext;
    if (context == null) return;

    await Navigator.of(this.context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(companyContext: context),
      ),
    );

    await refreshUnreadNotificationCount();
  }

  @override
  void dispose() {
    notificationRefreshTimer.cancel();
    super.dispose();
  }

  String _formatMoney(double value) {
    final isNegative = value < 0;
    final absoluteValue = value.abs();

    final rounded = absoluteValue.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      final positionFromEnd = rounded.length - i;

      if (i != 0 && positionFromEnd % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(rounded[i]);
    }

    return isNegative ? '-\$${buffer.toString()}' : '\$${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final canViewFinancials = companyContext?.canViewFinancials == true;
    final metrics = projectMetrics;
    final workspaceTitle =
        companyContext?.displayWorkspaceName ?? 'LupinusBuild Dashboard';
    final workspaceSubtitle =
        companyContext?.loginSubtitle?.trim().isNotEmpty == true
        ? companyContext!.loginSubtitle!.trim()
        : 'Track customers, leads, quotes, projects, materials, files, and profitability.';

    final stats = [
      const _DashboardStat(
        title: 'Open Leads',
        value: '0',
        subtitle: 'New opportunities',
      ),
      const _DashboardStat(
        title: 'Open Quotes',
        value: '0',
        subtitle: 'Drafts and pending',
      ),
      _DashboardStat(
        title: 'Active Projects',
        value: (metrics?.activeProjects ?? 0).toString(),
        subtitle: 'Projects not completed',
      ),
      _DashboardStat(
        title: 'Open Project Value',
        value: canViewFinancials
            ? _formatMoney(metrics?.openProjectTotalValue ?? 0)
            : 'Hidden',
        subtitle: canViewFinancials
            ? 'Total contract value open'
            : 'Restricted by role',
      ),
      _DashboardStat(
        title: 'Project Expenses',
        value: canViewFinancials
            ? _formatMoney(metrics?.projectExpenses ?? 0)
            : 'Hidden',
        subtitle: canViewFinancials
            ? 'Actual costs recorded'
            : 'Restricted by role',
      ),
      _DashboardStat(
        title: 'Open Project Profit',
        value: canViewFinancials
            ? _formatMoney(metrics?.totalOpenProjectProfit ?? 0)
            : 'Hidden',
        subtitle: canViewFinancials
            ? 'Open actual profit'
            : 'Restricted by role',
      ),
      _DashboardStat(
        title: 'Annual Project Profit',
        value: canViewFinancials
            ? _formatMoney(metrics?.totalAnnualProjectProfit ?? 0)
            : 'Hidden',
        subtitle: canViewFinancials
            ? 'This calendar year'
            : 'Restricted by role',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LupinusBuild Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (companyContext != null)
            IconButton(
              tooltip: unreadNotificationCount == 0
                  ? 'Notifications'
                  : '$unreadNotificationCount unread notifications',
              onPressed: openNotifications,
              icon: Badge(
                isLabelVisible: unreadNotificationCount > 0,
                label: Text(
                  unreadNotificationCount > 99
                      ? '99+'
                      : unreadNotificationCount.toString(),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          TextButton(onPressed: handleLogout, child: const Text('Log Out')),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCompanyContext,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              workspaceTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              workspaceSubtitle,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const _InfoCard(
                title: 'Loading company context...',
                body: 'Checking your workspace role and access permissions.',
              )
            else if (errorMessage != null)
              _InfoCard(
                title: 'Could not load company context',
                body: errorMessage!,
              )
            else if (companyContext == null)
              const _InfoCard(
                title: 'No company access found',
                body:
                    'This user is logged in, but no active company membership was found.',
              )
            else
              _CompanyContextCard(companyContext: companyContext!),
            if (companyContext != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LeadsListScreen(
                              companyContext: companyContext!,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Leads'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuotesListScreen(
                              companyContext: companyContext!,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Quotes'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomersListScreen(
                              companyContext: companyContext!,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Customers'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProjectsListScreen(
                              companyContext: companyContext!,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Projects'),
                    ),
                  ),
                  if (companyContext!.canViewCompanyTasks)
                    SizedBox(
                      width: 180,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompanyTasksScreen(
                                companyContext: companyContext!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.task_alt_outlined),
                        label: const Text('All Tasks'),
                      ),
                    ),
                ],
              ),
              if (companyContext!.hasExecutiveAccess) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Controls',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 180,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuotePricingAdminScreen(
                                        companyContext: companyContext!,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Quote Pricing'),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TeamMembersScreen(
                                        companyContext: companyContext!,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Manage Team'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.35 : 1.15,
                  children: stats,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyContextCard extends StatelessWidget {
  const _CompanyContextCard({required this.companyContext});

  final CompanyContext companyContext;

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
        padding: const EdgeInsets.all(20),
        child: Wrap(
          runSpacing: 12,
          spacing: 12,
          children: [
            _ContextChip(
              label: 'Workspace',
              value: companyContext.displayWorkspaceName,
            ),
            _ContextChip(
              label: 'Brand',
              value: companyContext.displayBrandName,
            ),
            _ContextChip(label: 'Company', value: companyContext.companyName),
            if (companyContext.poweredByLupinusBuild)
              const _ContextChip(label: 'Powered By', value: 'LupinusBuild'),
            _ContextChip(label: 'User', value: companyContext.userEmail),
            _ContextChip(label: 'Role', value: companyContext.roleLabel),
            _ContextChip(
              label: 'Expense Access',
              value: companyContext.canViewFinancials ? 'Allowed' : 'Hidden',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
