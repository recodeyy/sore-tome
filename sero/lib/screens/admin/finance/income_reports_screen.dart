import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Income Reports — Screen 6 of 6
/// Visual report of collections by category, month, and wing.
class IncomeReportsScreen extends ConsumerWidget {
  const IncomeReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeDashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Income Reports', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)), onPressed: () => AdminActions.comingSoon(context, 'Report export')),
        ],
      ),
      body: financeAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading income reports…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(financeDashboardProvider),
        ),
        data: (data) {
          final summary = (data['summary'] as Map?) ?? const {};
          final totalCollection = '₹ ${summary['collection'] ?? summary['total_collection'] ?? summary['income'] ?? 0}';
          // No category-breakdown or top-collections endpoint in finance summary.
          final categories = (summary['categories'] as List?) ?? const [];
          final topCollections = (summary['top_collections'] as List?) ?? const [];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Filters ──
                Row(
                  children: [
                    _ReportFilter(label: 'This Month'),
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
                        Text(totalCollection, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF064E3B))),
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
                    categories.isEmpty
                        ? const LiveEmptyView(
                            icon: Icons.pie_chart_outline,
                            message: 'No category breakdown available.',
                          )
                        : Row(
                            children: [
                              DonutChart(
                                segments: categories.map((c) {
                                  final m = c is Map ? c : const {};
                                  return DonutSegment(
                                    value: (m['percent'] is num ? (m['percent'] as num).toDouble() : 0.0),
                                    color: Color((m['color'] is int ? m['color'] as int : 0xFF94A3B8)),
                                    label: (m['label'] ?? '').toString(),
                                  );
                                }).toList(),
                                size: 110,
                                centerValue: '',
                                centerLabel: 'Income',
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: categories.map((c) {
                                    final m = c is Map ? c : const {};
                                    return _ReportLegend(
                                      color: Color((m['color'] is int ? m['color'] as int : 0xFF94A3B8)),
                                      label: (m['label'] ?? '').toString(),
                                      value: '₹ ${m['value'] ?? 0}',
                                      percent: (m['percent'] is num ? (m['percent'] as num).toInt() : 0),
                                    );
                                  }).toList(),
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
            topCollections.isEmpty
                ? const LiveEmptyView(
                    icon: Icons.leaderboard_outlined,
                    message: 'No top collections available.',
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: topCollections.map((item) {
                        final m = item is Map ? item : const {};
                        return _CollectionRow(
                          label: (m['label'] ?? m['name'] ?? '').toString(),
                          value: '₹ ${m['amount'] ?? m['value'] ?? 0}',
                        );
                      }).toList(),
                    ),
                  ),

            const SizedBox(height: 100),
              ],
            ),
          );
        },
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
