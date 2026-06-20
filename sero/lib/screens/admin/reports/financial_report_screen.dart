import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Financial Report Detail — Screen 2 of 2.
/// Live, backed by GET /finance/reports/summary (Postgres). Money in integer
/// minor units, formatted client-side. Trend/category breakdowns are only shown
/// when the backend provides them (no fabricated series).
class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _fmt(num minor) {
    final rupees = minor / 100.0;
    if (rupees.abs() >= 100000) return '₹ ${(rupees / 100000).toStringAsFixed(2)}L';
    if (rupees.abs() >= 1000) return '₹ ${(rupees / 1000).toStringAsFixed(1)}K';
    return '₹ ${rupees.toStringAsFixed(0)}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Financial Report',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Color(0xFF1E293B)),
                      onPressed: () => AdminActions.comingSoon(context, 'Report filters'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
                      onPressed: () => AdminActions.comingSoon(context, 'Report export'),
                    ),
                  ],
                ),
                // ── Tabs ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelPadding: EdgeInsets.zero,
                      indicator: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: const [
                        Tab(child: Text('Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Tab(child: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Tab(child: Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Tab(child: Text('Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          Expanded(
            child: ref.watch(financeDashboardProvider).when(
              loading: () => const LiveLoadingView(label: 'Loading financials…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(financeDashboardProvider),
              ),
              data: (payload) {
                final summary =
                    (payload['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
                num m(String k) => (summary[k] as num?) ?? 0;
                final income = m('collectedMinor');
                final expense = m('expensesMinor');
                final surplus = income - expense;
                final outstanding = m('outstandingMinor');
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(financeDashboardProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // ── Summary Metric Grid (live) ──
                        Row(
                          children: [
                            _MetricCard(
                              label: 'Collected (Income)',
                              value: _fmt(income),
                              icon: Icons.trending_up,
                              color: const Color(0xFF059669),
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              label: 'Approved Expense',
                              value: _fmt(expense),
                              icon: Icons.trending_down,
                              color: const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetricCard(
                              label: 'Net Surplus',
                              value: _fmt(surplus),
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFF064E3B),
                              iconBgColor: const Color(0xFFF0FDF4),
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              label: 'Outstanding Dues',
                              value: _fmt(outstanding),
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF7C3AED),
                              iconBgColor: const Color(0xFFF5F3FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _ChartSection(
                          title: 'Income vs Expense',
                          child: Column(
                            children: [
                              _BarRow(label: 'Collected', value: income, max: income > expense ? income : expense, color: const Color(0xFF064E3B), display: _fmt(income)),
                              const SizedBox(height: 12),
                              _BarRow(label: 'Expense', value: expense, max: income > expense ? income : expense, color: const Color(0xFFEA580C), display: _fmt(expense)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? iconBgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                if (iconBgColor != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text('This Month', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final num value;
  final num max;
  final Color color;
  final String display;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            Text(display, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
