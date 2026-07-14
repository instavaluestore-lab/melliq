import 'package:flutter/material.dart';

import '../../../shared/widgets/page_navigation_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({
    super.key,
    required this.companyContext,
  });

  final CompanyContext companyContext;

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  late final CustomerService customerService;

  bool isLoading = true;
  String? errorMessage;
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    customerService = CustomerService(Supabase.instance.client);
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await customerService.getCustomersForCompany(
        widget.companyContext.companyId,
      );

      if (!mounted) return;

      setState(() {
        customers = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          TextButton(
            onPressed: () async {
              final didCreate = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CustomerFormScreen(
                    companyContext: widget.companyContext,
                  ),
                ),
              );

              if (didCreate == true) {
                await loadCustomers();
              }
            },
            child: const Text('Add'),
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
              onRefresh: loadCustomers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const Text(
              'Customer Records',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'View MaxShade residential, commercial, and contractor customer records.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const _StateCard(
                title: 'Loading customers...',
                body: 'Fetching customer records from Supabase.',
              )
            else if (errorMessage != null)
              _StateCard(
                title: 'Could not load customers',
                body: errorMessage!,
              )
            else if (customers.isEmpty)
              const _StateCard(
                title: 'No customers yet',
                body:
                    'Customer records will appear here after we build the add customer form.',
              )
            else
              ...customers.map(
                (customer) => _CustomerCard(
                  customer: customer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(
                          companyContext: widget.companyContext,
                          customer: customer,
                        ),
                      ),
                    );
                  },
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  final Customer customer;
  final VoidCallback onTap;

  int get paletteIndex {
    return customer.id.hashCode.abs() % 7;
  }

  Color get shellColor {
    switch (paletteIndex) {
      case 0:
        return const Color(0xFFEFF6FF);
      case 1:
        return const Color(0xFFFFF7ED);
      case 2:
        return const Color(0xFFF0FDF4);
      case 3:
        return const Color(0xFFF5F3FF);
      case 4:
        return const Color(0xFFECFEFF);
      case 5:
        return const Color(0xFFFDF2F8);
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  Color get accentColor {
    switch (paletteIndex) {
      case 0:
        return const Color(0xFF2563EB);
      case 1:
        return const Color(0xFFF97316);
      case 2:
        return const Color(0xFF16A34A);
      case 3:
        return const Color(0xFF7C3AED);
      case 4:
        return const Color(0xFF0891B2);
      case 5:
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get titleColor {
    switch (paletteIndex) {
      case 0:
        return const Color(0xFF1D4ED8);
      case 1:
        return const Color(0xFFC2410C);
      case 2:
        return const Color(0xFF15803D);
      case 3:
        return const Color(0xFF6D28D9);
      case 4:
        return const Color(0xFF0E7490);
      case 5:
        return const Color(0xFFBE185D);
      default:
        return const Color(0xFFB45309);
    }
  }

  String get firstInitial {
    final name = customer.displayName.trim();

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: shellColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 14,
            offset: Offset(0, 7),
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
                  height: 116,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accentColor, width: 1.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  firstInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                customer.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniLabel(
                              label: customer.customerTypeLabel,
                              backgroundColor: shellColor,
                              borderColor: accentColor,
                              textColor: titleColor,
                            ),
                            _MiniLabel(
                              label: customer.statusLabel,
                              backgroundColor: const Color(0xFFF0FDF4),
                              borderColor: const Color(0xFF16A34A),
                              textColor: const Color(0xFF15803D),
                            ),
                            _MiniLabel(
                              label: customer.location,
                              backgroundColor: const Color(0xFFF8FAFC),
                              borderColor: const Color(0xFF64748B),
                              textColor: const Color(0xFF334155),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (customer.email != null &&
                            customer.email!.trim().isNotEmpty)
                          Text(
                            customer.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (customer.phone != null &&
                            customer.phone!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              customer.phone!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({
    required this.label,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.borderColor = const Color(0xFFE5E7EB),
    this.textColor = const Color(0xFF4B5563),
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
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
