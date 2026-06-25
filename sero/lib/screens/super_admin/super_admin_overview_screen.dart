import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminOverviewScreen extends ConsumerWidget {
  const SuperAdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(superAdminDashboardProvider);
    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(superAdminDashboardProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) => SuperAdminHeader(
                  title: 'Good Morning, Super Admin',
                  subtitle:
                      'SERO Platform · ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  unreadCount: dashboard.valueOrNull?.unreadNotifications ?? 0,
                  periodLabel: 'Jun 20 - Jul 20',
                  onPeriodTap: () {},
                  onMenu: () => Scaffold.of(context).openDrawer(),
                  onNotifications: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  onSettings: () =>
                      Navigator.pushNamed(context, '/super-admin/settings'),
                ),
              ),
            ),
            dashboard.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: SuperAdminAsyncView<void>(
                  error: error,
                  onRetry: () => ref.invalidate(superAdminDashboardProvider),
                  builder: (_) => const SizedBox.shrink(),
                ),
              ),
              data: (data) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.of(context).size.width >= 700 ? 3 : 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.18,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: List.generate(
                          data.metrics.length,
                          (index) {
                            const palette = [
                              kSuperGreen,
                              Color(0xFF0EA5E9),
                              Color(0xFF8B5CF6),
                              Color(0xFFF59E0B),
                              Color(0xFFEF4444),
                            ];
                            return SuperAdminMetricCard(
                              metric: data.metrics[index],
                              icon: _metricIcon(data.metrics[index].key),
                              accent: palette[index % palette.length],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SuperAdminSectionCard(
                        title: 'Quick Actions',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _ActionChip(
                                icon: Icons.fact_check_outlined,
                                label: 'Approve Society'),
                            _ActionChip(
                                icon: Icons.verified_user_outlined,
                                label: 'Review KYC'),
                            _ActionChip(
                                icon: Icons.campaign_outlined,
                                label: 'Announcement'),
                            _ActionChip(
                                icon: Icons.support_agent_outlined,
                                label: 'Support Queue'),
                          ],
                        ),
                      ),
                      SuperAdminSectionCard(
                        title: 'Revenue Overview',
                        child: Row(
                          children: [
                            Expanded(
                                child: _MoneyTile(
                                    label: 'MRR', amount: data.revenue.mrr)),
                            Expanded(
                                child: _MoneyTile(
                                    label: 'ARR', amount: data.revenue.arr)),
                            Expanded(
                                child: _MoneyTile(
                                    label: 'Failed',
                                    amount:
                                        data.revenue.failedPayments.toDouble(),
                                    isCount: true)),
                          ],
                        ),
                      ),
                      SuperAdminSectionCard(
                        title: 'Platform Health',
                        child: Column(
                          children: data.health.isEmpty
                              ? [
                                  Text(
                                    'No health signals reported.',
                                    style: GoogleFonts.outfit(
                                        color: const Color(0xFF64748B)),
                                  ),
                                ]
                              : data.health
                                  .map(
                                    (signal) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                          Icons.monitor_heart_outlined,
                                          color: kPrimaryGreen),
                                      title: Text(signal.label,
                                          style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w700)),
                                      subtitle: Text(signal.detail.isEmpty
                                          ? signal.status
                                          : signal.detail),
                                      trailing: Text(signal.status),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      SuperAdminSectionCard(
                        title: 'Recent Platform Activity',
                        child: data.recentActivity.isEmpty
                            ? Text(
                                'No recent platform events.',
                                style: GoogleFonts.outfit(
                                    color: const Color(0xFF64748B)),
                              )
                            : Column(
                                children: data.recentActivity
                                    .map(
                                      (activity) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.history,
                                            color: kPrimaryGreen),
                                        title: Text(activity.title),
                                        subtitle: Text(activity.subtitle),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _metricIcon(String key) {
    if (key.contains('societ')) return Icons.business_outlined;
    if (key.contains('approval')) return Icons.fact_check_outlined;
    if (key.contains('user')) return Icons.people_outline;
    if (key.contains('revenue')) return Icons.account_balance_wallet_outlined;
    if (key.contains('support')) return Icons.support_agent_outlined;
    return Icons.monitor_heart_outlined;
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryGreen, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, color: kPrimaryGreen)),
        ],
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  final String label;
  final double amount;
  final bool isCount;

  const _MoneyTile({
    required this.label,
    required this.amount,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: const Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          isCount
              ? amount.toStringAsFixed(0)
              : 'INR ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
