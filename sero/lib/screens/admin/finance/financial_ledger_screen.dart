import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';

/// Financial Ledger — Screen 5 of 6
/// Date-filtered ledger view with summary tabs and income vs expense bar charts.
class FinancialLedgerScreen extends StatefulWidget {
  const FinancialLedgerScreen({super.key});

  @override
  State<FinancialLedgerScreen> createState() => _FinancialLedgerScreenState();
}

class _FinancialLedgerScreenState extends State<FinancialLedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Financial Ledger', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: Color(0xFF1E293B)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ── Date Range ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Row(
                children: [
                   const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                   const SizedBox(width: 12),
                   Text('01 May 2024 - 31 May 2024', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                   const Spacer(),
                   const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF1E293B),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                tabs: const [
                  Tab(child: Text('Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Tab(child: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Tab(child: Text('Expenses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                const Center(child: Text('Income View')),
                const Center(child: Text('Expenses View')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final summary = MockFinanceData.ledgerSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ledger Summary', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _buildSummaryGrid(summary),
          const SizedBox(height: 32),
          Text('Income vs Expense', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               _LegendItem(color: const Color(0xFF036B52), label: 'Income'),
               const SizedBox(width: 16),
               _LegendItem(color: const Color(0xFFEA580C), label: 'Expenses'),
             ],
          ),
          const SizedBox(height: 20),
          _buildBarChart(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.list_alt_outlined, size: 20, color: Color(0xFF064E3B)),
              label: Text('View Transactions', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF064E3B))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF064E3B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    return Column(
      children: [
        Row(
          children: [
            _MetricItem(label: 'Total Income', value: summary['totalIncome'], color: const Color(0xFF059669)),
            const SizedBox(width: 12),
            _MetricItem(label: 'Total Expenses', value: summary['totalExpenses'], color: const Color(0xFFDC2626)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricItem(label: 'Net Balance', value: summary['netBalance'], color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            _MetricItem(label: 'Transactions', value: summary['transactions'].toString(), color: const Color(0xFF7C3AED)),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _SimpleBarChartPainter(),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ),
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
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }
}

class _SimpleBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final incomePaint = Paint()..color = const Color(0xFF036B52);
    final expensePaint = Paint()..color = const Color(0xFFEA580C);
    
    final data = MockFinanceData.incomeVsExpenseData;
    final double maxVal = 5.0;
    final double groupWidth = size.width / data.length;
    final double barWidth = 10;
    final double spacing = 4;

    for (int i = 0; i < data.length; i++) {
        final x = i * groupWidth + (groupWidth / 2) - (barWidth + spacing / 2);
        
        // Income Bar
        final hi = (data[i]['income'] as double) / maxVal * size.height;
        canvas.drawRRect(RRect.fromLTRBR(x, size.height - hi, x + barWidth, size.height, const Radius.circular(3)), incomePaint);
        
        // Expense Bar
        final he = (data[i]['expense'] as double) / maxVal * size.height;
        canvas.drawRRect(RRect.fromLTRBR(x + barWidth + spacing, size.height - he, x + 2 * barWidth + spacing, size.height, const Radius.circular(3)), expensePaint);
        
        // Label (Simulated)
        final textPainter = TextPainter(
          text: TextSpan(text: data[i]['label'] as String, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x + barWidth - textPainter.width / 2, size.height + 6));
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
