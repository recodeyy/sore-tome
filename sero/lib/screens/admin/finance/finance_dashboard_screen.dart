import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'generate_bills_screen.dart';
import 'bill_details_screen.dart';
import 'payment_history_screen.dart';
import 'financial_ledger_screen.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

/// Finance Dashboard — Screen 1 of 6
/// Entry point for the Finance section with collection summary and revenue charts.
class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
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
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Text(
              'Finance Dashboard',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF1E293B)), onPressed: () {}),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  children: [
                    IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF1E293B)), onPressed: null),
                    if (ref.watch(notificationProvider.notifier).unreadCount > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              ref.watch(notificationProvider.notifier).unreadCount.toString(),
                              style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Total Collection Hero Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                        Text('Total Collection', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Text('May 2024', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                              const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MockFinanceData.totalCollection,
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF064E3B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(MockFinanceData.totalCollectionTrend, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                        const SizedBox(width: 6),
                        Text('vs Apr 2024', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFCBD5E1))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF064E3B), size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Stat Grid ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _FinanceMetricCard(
                  label: 'Pending Dues',
                  value: MockFinanceData.pendingDues,
                  trend: MockFinanceData.pendingDuesTrend,
                  trendUp: false,
                  onTap: () => Navigator.pushNamed(context, '/admin/finance/history'),
                ),
                _FinanceMetricCard(
                  label: 'This Month Revenue',
                  value: MockFinanceData.thisMonthRevenue,
                  showSparkline: true,
                  onTap: () => Navigator.pushNamed(context, '/admin/finance/reports'),
                ),
                _FinanceMetricCard(
                  label: 'Total Expenses',
                  value: MockFinanceData.totalExpenses,
                  trend: MockFinanceData.totalExpensesTrend,
                  trendUp: true,
                  onTap: () => Navigator.pushNamed(context, '/admin/finance/ledger'),
                ),
                _FinanceMetricCard(
                  label: 'Maintenance Due',
                  value: MockFinanceData.maintenanceDue,
                  subtitle: '${MockFinanceData.maintenanceDueFlats} Flats',
                  onTap: () => Navigator.pushNamed(context, '/admin/finance/bills'),
                ),
              ],
            ),
          ),

          // ── Revenue Overview Chart ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                        Text('Revenue Overview', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
                    const SizedBox(height: 20),
                    MiniLineChart(
                      data: MockDashboardData.revenueLineData,
                      labels: MockDashboardData.revenueLabels,
                      lineColor: const Color(0xFF059669),
                      height: 180,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/finance/generate-bills'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Generate New Bills', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final bool trendUp;
  final String? subtitle;
  final bool showSparkline;
  final VoidCallback onTap;

  const _FinanceMetricCard({
    required this.label,
    required this.value,
    this.trend,
    this.trendUp = true,
    this.subtitle,
    this.showSparkline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
            Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            if (trend != null)
              Row(
                children: [
                  Icon(trendUp ? Icons.trending_up : Icons.trending_down, size: 12, color: trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  Text(trend!, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: trendUp ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                ],
              ),
            if (subtitle != null)
              Text(subtitle!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEA580C))),
            if (showSparkline)
              SizedBox(
                height: 20,
                child: CustomPaint(painter: _MiniSparklinePainter()),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF10B981)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    final points = [0.2, 0.5, 0.4, 0.8, 0.7, 1.0];
    final step = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * step;
      final y = size.height - (points[i] * size.height);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
