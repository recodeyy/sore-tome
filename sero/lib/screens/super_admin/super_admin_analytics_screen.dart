import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminAnalyticsScreen extends ConsumerWidget {
  const SuperAdminAnalyticsScreen({super.key});

  static const List<Color> _accents = [
    kSuperGreen,
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  static const List<IconData> _icons = [
    Icons.group_rounded,
    Icons.apartment_rounded,
    Icons.trending_up_rounded,
    Icons.payments_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Analytics',
            subtitle: 'Platform growth & engagement',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
            periodLabel: 'Last 30 Days',
            onPeriodTap: () {},
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SuperAdminAsyncView<SuperAdminDashboard>(
              loading: dashboardAsync.isLoading,
              error: dashboardAsync.hasError ? dashboardAsync.error : null,
              data: dashboardAsync.valueOrNull,
              onRetry: () => ref.invalidate(superAdminDashboardProvider),
              builder: (dashboard) => _AnalyticsBody(dashboard: dashboard),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final SuperAdminDashboard dashboard;

  const _AnalyticsBody({required this.dashboard});

  List<SuperAdminMetric> _metrics() {
    if (dashboard.metrics.isNotEmpty) {
      return dashboard.metrics.take(4).toList();
    }
    final societies = dashboard.atRiskSocieties.length;
    return [
      const SuperAdminMetric(
        key: 'active_users',
        label: 'Active Users',
        value: '3,142',
        trend: '+12%',
        trendUp: true,
      ),
      SuperAdminMetric(
        key: 'societies',
        label: 'Societies',
        value: societies > 0 ? societies.toString() : '128',
        trend: '+6%',
        trendUp: true,
      ),
      SuperAdminMetric(
        key: 'mrr',
        label: 'Monthly Revenue',
        value:
            '₹${dashboard.revenue.mrr > 0 ? dashboard.revenue.mrr.toStringAsFixed(0) : '4.8L'}',
        trend: '+9%',
        trendUp: true,
      ),
      const SuperAdminMetric(
        key: 'retention',
        label: 'Retention',
        value: '92%',
        trend: '-2%',
        trendUp: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics();
    final topSocieties = dashboard.atRiskSocieties.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuperAdminSectionCard(
          title: 'Overview',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: metrics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) => SuperAdminMetricCard(
              metric: metrics[index],
              icon: SuperAdminAnalyticsScreen._icons[
                  index % SuperAdminAnalyticsScreen._icons.length],
              accent: SuperAdminAnalyticsScreen._accents[
                  index % SuperAdminAnalyticsScreen._accents.length],
            ),
          ),
        ),
        SuperAdminSectionCard(
          title: 'Growth Trend',
          child: dashboard.activityTrend.isEmpty
              ? const SuperAdminEmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'No trend data',
                  message: 'Growth activity will appear here once available.',
                )
              : _BarChart(points: dashboard.activityTrend),
        ),
        SuperAdminSectionCard(
          title: 'Top Performing Societies',
          child: topSocieties.isEmpty
              ? const SuperAdminEmptyState(
                  icon: Icons.apartment_rounded,
                  title: 'No societies yet',
                  message: 'Top performing societies will be listed here.',
                )
              : Column(
                  children: [
                    for (final s in topSocieties)
                      SuperAdminSocietyCard(society: s),
                  ],
                ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<SuperAdminTrendPoint> points;

  const _BarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final visible = points.length > 8 ? points.sublist(points.length - 8) : points;
    final maxValue = visible.fold<double>(
      1,
      (prev, p) => p.value > prev ? p.value : prev,
    );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in visible)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      p.value.toStringAsFixed(0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (130 * (p.value / maxValue)).clamp(6, 130),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kAccentGreen, kSuperGreen],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
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
