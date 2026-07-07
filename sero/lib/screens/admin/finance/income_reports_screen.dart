import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/mini_chart.dart';

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
          IconButton(icon: const Icon(Icons.ios_share, color: Color(0xFF1E293B)), onPressed: () => _exportReport(context, ref)),
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

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    final data = ref.read(financeDashboardProvider).valueOrNull;
    if (data == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimaryGreen,
          content: Text('Report is still loading. Try again in a moment.', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ));
      return;
    }
    try {
      final bytes = await _buildReportPdf((data['summary'] as Map?)?.cast<String, dynamic>() ?? const {});
      await Printing.sharePdf(bytes: bytes, filename: 'income_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<Uint8List> _buildReportPdf(Map<String, dynamic> summary) async {
    final totalCollection = (summary['collection'] ?? summary['total_collection'] ?? summary['income'] ?? 0).toString();
    final categories = (summary['categories'] as List?) ?? const [];
    final topCollections = (summary['top_collections'] as List?) ?? const [];
    final now = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text('INCOME REPORT', style: pw.TextStyle(fontSize: 10, letterSpacing: 1.5, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Collection Summary', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.Container(height: 2, width: 60, color: PdfColors.green900),
          pw.SizedBox(height: 4),
          pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(color: PdfColors.green50),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Total Income', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs. $totalCollection', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            ]),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Income by Category', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.SizedBox(height: 8),
          if (categories.isEmpty)
            pw.Text('No category breakdown available.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                _pdfRow('Category', 'Amount', header: true),
                ...categories.map((c) {
                  final m = c is Map ? c : const {};
                  return _pdfRow((m['label'] ?? '').toString(), 'Rs. ${m['value'] ?? 0}');
                }),
              ],
            ),
          pw.SizedBox(height: 24),
          pw.Text('Top Collections', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.SizedBox(height: 8),
          if (topCollections.isEmpty)
            pw.Text('No top collections available.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                _pdfRow('Name', 'Amount', header: true),
                ...topCollections.map((c) {
                  final m = c is Map ? c : const {};
                  return _pdfRow((m['label'] ?? m['name'] ?? '').toString(), 'Rs. ${m['amount'] ?? m['value'] ?? 0}');
                }),
              ],
            ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.TableRow _pdfRow(String a, String b, {bool header = false}) {
    final style = pw.TextStyle(fontSize: 10, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.TableRow(
      decoration: header ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(a, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(b, style: style, textAlign: pw.TextAlign.right)),
      ],
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
