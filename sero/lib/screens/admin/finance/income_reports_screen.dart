import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/mini_chart.dart';

/// Income Reports — Screen 6 of 6
/// Visual report of collections by category, month, and wing.
class IncomeReportsScreen extends StatelessWidget {
  const IncomeReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Income Reports', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── Filters ──
            Row(
              children: [
                _ReportFilter(label: 'May 2024'),
                const SizedBox(width: 10),
                _ReportFilter(label: 'All Categories'),
              ],
            ),

            const SizedBox(height: 20),
            // ── Total Income Stat ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Income', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                        const SizedBox(height: 4),
                        Text(MockFinanceData.totalCollection, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF064E3B))),
                         const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, size: 12, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(MockFinanceData.totalCollectionTrend, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                            const SizedBox(width: 4),
                            Text('vs Apr 2024', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E1))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.bar_chart_rounded, size: 40, color: Color(0xFFD1FAE5)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── Income by Category Donut ──
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: const Color(0xFFF1F5F9)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text('Income by Category', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        DonutChart(
                          segments: MockReportsData.financialCategories.map((c) => DonutSegment(
                            value: c['percent'] as double,
                            color: Color(c['color'] as int),
                            label: c['label'] as String,
                          )).toList(),
                          size: 110,
                          centerValue: '70%',
                          centerLabel: 'Maintenance',
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: MockReportsData.financialCategories.map((c) => _ReportLegend(
                              color: Color(c['color'] as int),
                              label: c['label'] as String,
                              value: c['value'] as String,
                              percent: (c['percent'] as double).toInt(),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                 ],
               ),
            ),

            const SizedBox(height: 24),
            // ── Top Collections ──
            Align(alignment: Alignment.centerLeft, child: Text('Top Collections', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
            const SizedBox(height: 12),
            Container(
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: const Color(0xFFF1F5F9)),
               ),
               child: Column(
                 children: MockFinanceData.topCollections.map((item) => _CollectionRow(
                   label: item['label'],
                   value: item['amount'],
                 )).toList(),
               ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _ReportFilter extends StatelessWidget {
  final String label;
  const _ReportFilter({required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
             Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
             const Spacer(),
             const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _ReportLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int percent;
  const _ReportLegend({required this.color, required this.label, required this.value, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
          Text('$percent%', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final String label;
  final String value;
  const _CollectionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
