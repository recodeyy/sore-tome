import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/providers/shared/notification_provider.dart';

/// Dashboard Revenue Overview — Screen 2 of 4
/// Shows total collection, finance cards, revenue line chart,
/// collections trend bar chart, and category-wise donut chart.
class DashboardRevenueScreen extends ConsumerWidget {
  const DashboardRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1E293B), size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 22),
                      onPressed: null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Revenue Overview Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revenue Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          MockDashboardData.monthLabel,
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Total Collection Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Collection',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MockDashboardData.totalCollection,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                MockDashboardData.totalCollectionTrend,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'vs Apr 2024',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Finance Summary Row ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                _MiniFinanceCard(
                  label: 'Collected',
                  value: MockDashboardData.collectedAmount,
                  color: const Color(0xFF059669),
                ),
                _MiniFinanceCard(
                  label: 'Pending',
                  value: MockDashboardData.pendingAmount,
                  color: const Color(0xFFD97706),
                ),
                _MiniFinanceCard(
                  label: 'Overdue',
                  value: MockDashboardData.overdueAmount,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),

          // ── Finance Detail Cards (2 rows x 2) ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _FinanceDetailCard(
                  title: 'Pending Dues',
                  value: MockDashboardData.pendingDues,
                  trend: MockDashboardData.pendingDuesTrend,
                  trendUp: false,
                  trendColor: const Color(0xFFDC2626),
                ),
                _FinanceDetailCard(
                  title: 'This Month Revenue',
                  value: MockDashboardData.thisMonthRevenue,
                  showSparkline: true,
                ),
                _FinanceDetailCard(
                  title: 'Total Expenses',
                  value: MockDashboardData.totalExpenses,
                  trend: MockDashboardData.totalExpensesTrend,
                  trendUp: true,
                ),
                _FinanceDetailCard(
                  title: 'Maintenance Due',
                  value: MockDashboardData.maintenanceDueAmount,
                  subtitle: '${MockDashboardData.maintenanceDueFlats} Flats',
                ),
              ],
            ),
          ),

          // ── Revenue Overview Line Chart ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revenue Overview',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('This Month', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        // Y-axis scale labels
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: ['5L', '4L', '3L', '2L', '1L', '0']
                                  .map((l) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Text(l, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MiniLineChart(
                                data: MockDashboardData.revenueLineData,
                                labels: MockDashboardData.revenueLabels,
                                lineColor: kPrimaryGreen,
                                height: 160,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collections Trend (Bar Chart) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collections Trend',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('This Month', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: MiniBarChart(
                      data: MockDashboardData.collectionTrend,
                      labels: MockDashboardData.collectionWeeks,
                      barColor: kPrimaryGreen,
                      height: 140,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category Wise Collection (Donut) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Wise Collection',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: MockDashboardData.categoryBreakdown.isEmpty 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'No financial records found.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            ),
                          )
                        : Row(
                          children: [
                            DonutChart(
                              segments: MockDashboardData.categoryBreakdown
                                  .map((c) => DonutSegment(
                                        value: c['percent'].toDouble(),
                                        color: Color(c['color'] as int),
                                        label: c['label'] as String,
                                      ))
                                  .toList(),
                              centerValue: MockDashboardData.categoryTotal,
                              centerLabel: 'Total',
                              size: 120,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: MockDashboardData.categoryBreakdown
                                    .map((c) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Color(c['color'] as int),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      c['label'] as String,
                                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                                                    ),
                                                    Text(
                                                      '${c['percent']}%',
                                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  c['amount'] as String,
                                                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Small finance stat card for collected/pending/overdue row
class _MiniFinanceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniFinanceCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Larger finance detail card with trend indicator or sparkline
class _FinanceDetailCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool trendUp;
  final Color? trendColor;
  final bool showSparkline;
  final String? subtitle;

  const _FinanceDetailCard({
    required this.title,
    required this.value,
    this.trend,
    this.trendUp = true,
    this.trendColor,
    this.showSparkline = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (trend != null)
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: trendColor ?? (trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor ?? (trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: kPrimaryGreen),
            ),
          if (showSparkline)
            SizedBox(
              height: 24,
              child: CustomPaint(
                size: const Size(double.infinity, 24),
                painter: _TinySparkPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TinySparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final data = [20.0, 35.0, 25.0, 45.0, 38.0, 55.0, 48.0];
    final maxVal = 60.0;
    final step = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
