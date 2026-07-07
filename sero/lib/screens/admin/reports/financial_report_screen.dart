import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_reports_service.dart';

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

  /// Currently applied reporting period (drives the chart label + re-query).
  String _period = 'This Month';
  bool _exporting = false;

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

  /// Filter bottom-sheet: pick a reporting period, then re-query the report.
  Future<void> _showFilterSheet() async {
    const periods = ['This Month', 'Last Month', 'This Quarter', 'This Year'];
    var selected = _period;
    final applied = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Filter Report',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  Text('Period',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: periods.map((p) {
                      final isSel = p == selected;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selected = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF064E3B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(p,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : const Color(0xFF64748B),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext, selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Apply Filter',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (applied != null && mounted) {
      setState(() => _period = applied);
      // Re-query the financial report for the newly selected period.
      ref.invalidate(financeDashboardProvider);
    }
  }

  /// Generates a CSV report on the backend, renders it as a PDF, and opens the
  /// share/save sheet.
  Future<void> _exportReport() async {
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await AdminReportsService.exportReportCsv(kind: 'finance');
      final payload = ref.read(financeDashboardProvider).valueOrNull;
      final bytes = await _buildReportPdf(csv, payload);
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await Printing.sharePdf(bytes: bytes, filename: 'financial_report_$stamp.pdf');
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Builds a PDF: the on-screen summary plus the backend CSV detail table.
  Future<Uint8List> _buildReportPdf(String csv, Map<String, dynamic>? payload) async {
    final rows = _parseCsv(csv).where((r) => r.isNotEmpty).toList();
    final headers = rows.isNotEmpty ? rows.first : <String>[];
    final data = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    final summary = (payload?['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    num m(String k) => (summary[k] as num?) ?? 0;
    final income = m('collectedMinor');
    final expense = m('expensesMinor');
    final surplus = income - expense;
    final outstanding = m('outstandingMinor');

    pw.Widget kv(String label, String value) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ],
        );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text('Financial Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}  •  $_period',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                kv('Collected', _fmt(income)),
                kv('Expense', _fmt(expense)),
                kv('Net Surplus', _fmt(surplus)),
                kv('Outstanding', _fmt(outstanding)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Expense Detail',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (data.isEmpty)
            pw.Text('No transactions available.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data.take(500).toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  /// Minimal RFC-4180 CSV parser (handles quoted fields + escaped quotes).
  List<List<String>> _parseCsv(String csv) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    for (var i = 0; i < csv.length; i++) {
      final c = csv[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < csv.length && csv[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          row.add(field.toString());
          field = StringBuffer();
        } else if (c == '\n') {
          row.add(field.toString());
          rows.add(row);
          row = <String>[];
          field = StringBuffer();
        } else if (c != '\r') {
          field.write(c);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
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
                      onPressed: _showFilterSheet,
                    ),
                    IconButton(
                      icon: _exporting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E293B)))
                          : const Icon(Icons.ios_share, color: Color(0xFF1E293B)),
                      onPressed: _exporting ? null : _exportReport,
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
                          period: _period,
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
  final String period;

  const _ChartSection({required this.title, required this.child, this.period = 'This Month'});

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
                    Text(period, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
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
