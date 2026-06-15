import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/mini_chart.dart';

/// Financial Report Detail — Screen 2 of 2
/// Includes Tabs (Summary, Income, etc), Stats, Trend Chart, Category Donut, and Download CTE.
class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
                      onPressed: () {},
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ── Date Selector ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          '01 May 2024 - 31 May 2024',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // ── Summary Metric Grid ──
                  Row(
                    children: [
                      _MetricCard(
                        label: 'Total Income',
                        value: MockReportsData.totalIncome,
                        trend: '12.5%',
                        trendUp: true,
                        icon: Icons.trending_up,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      _MetricCard(
                        label: 'Total Expense',
                        value: MockReportsData.totalExpense,
                        trend: '8.3%',
                        trendUp: false,
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
                        value: MockReportsData.netSurplus,
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF064E3B),
                        iconBgColor: const Color(0xFFF0FDF4),
                      ),
                      const SizedBox(width: 10),
                      _MetricCard(
                        label: 'Transactions',
                        value: MockReportsData.transactionCount.toString(),
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF7C3AED),
                        iconBgColor: const Color(0xFFF5F3FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // ── Income vs Expense Trend ──
                  _ChartSection(
                    title: 'Income vs Expense Trend',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _LegendItem(color: const Color(0xFF064E3B), label: 'Income'),
                            const SizedBox(width: 16),
                            _LegendItem(color: const Color(0xFFEA580C), label: 'Expense'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _LineChartPlaceholder(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // ── Income by Category ──
                  _ChartSection(
                    title: 'Income by Category',
                    child: Row(
                      children: [
                        DonutChart(
                          segments: MockReportsData.financialCategories.map((c) => DonutSegment(
                            value: c['percent'] as double,
                            color: Color(c['color'] as int),
                            label: c['label'] as String,
                          )).toList(),
                          size: 110,
                          centerValue: '₹ 4.58L',
                          centerLabel: 'Total',
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: MockReportsData.financialCategories.map((c) => _DonutLegendRow(
                              color: Color(c['color'] as int),
                              label: c['label'] as String,
                              value: c['value'] as String,
                              percent: c['percent'] as double,
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // ── Download Section ──
                  Text('Download Report', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DownloadAction(icon: Icons.picture_as_pdf, color: Colors.red, label: 'Download PDF', onTap: () {}),
                      const SizedBox(width: 12),
                      _DownloadAction(icon: Icons.table_chart, color: Colors.green, label: 'Export Excel', onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
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
  final String? trend;
  final bool trendUp;
  final IconData icon;
  final Color color;
  final Color? iconBgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    this.trend,
    this.trendUp = true,
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
            if (trend != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(trendUp ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text(trend!, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(width: 4),
                  Text('vs Apr 2024', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E1))),
                ],
              ),
            ],
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percent;

  const _DonutLegendRow({required this.color, required this.label, required this.value, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('$value (${percent}%)', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _MultiLinePainter(),
      ),
    );
  }
}

class _MultiLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final incomePaint = Paint()..color = const Color(0xFF064E3B)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final expensePaint = Paint()..color = const Color(0xFFEA580C)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    
    // Draw grid lines
    final gridPaint = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = size.height - (i * (size.height / 5));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final incomePoints = [0.4, 0.6, 0.55, 0.75, 0.65, 0.82, 0.9];
    final expensePoints = [0.2, 0.35, 0.3, 0.45, 0.38, 0.48, 0.6];
    
    _drawPath(canvas, size, incomePoints, incomePaint);
    _drawPath(canvas, size, expensePoints, expensePaint);
  }

  void _drawPath(Canvas canvas, Size size, List<double> values, Paint paint) {
    final path = Path();
    final stepX = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] * size.height);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = paint.color);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DownloadAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _DownloadAction({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }
}
