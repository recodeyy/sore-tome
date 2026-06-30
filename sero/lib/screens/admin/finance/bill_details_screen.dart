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
import 'package:sero/services/admin/admin_finance_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/status_badge.dart';

/// Bill Details — Screen 3 of 6
/// Individual bill view with status, amount, breakup list, and download option.
class BillDetailsScreen extends ConsumerWidget {
  final String? invoiceId;
  const BillDetailsScreen({super.key, this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = invoiceId ??
        (ModalRoute.of(context)?.settings.arguments is String
            ? ModalRoute.of(context)!.settings.arguments as String
            : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Bill Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          if (id != null)
            IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)), onPressed: () => _showBillOptions(context, ref, id)),
        ],
      ),
      body: id == null
          ? const LiveEmptyView(icon: Icons.receipt_long_outlined, message: 'No invoice selected.')
          : ref.watch(invoiceDetailProvider(id)).when(
              loading: () => const LiveLoadingView(label: 'Loading bill…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(invoiceDetailProvider(id)),
              ),
              data: (bill) => _buildBody(context, ref, id, bill),
            ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, String id, Map<String, dynamic> bill) {
    final flatId = (bill['flat_id'] ?? bill['unit'] ?? bill['flatId'] ?? '').toString();
    final residentName = (bill['resident_name'] ?? bill['residentName'] ?? '').toString();
    final billName = (bill['bill_name'] ?? bill['title'] ?? bill['billName'] ?? '').toString();
    final totalAmount = '₹ ${bill['total'] ?? bill['amount'] ?? bill['totalAmount'] ?? 0}';
    final dueDate = (bill['due_date'] ?? bill['dueDate'] ?? '').toString();
    final billDate = (bill['bill_date'] ?? bill['created_at'] ?? bill['billDate'] ?? '').toString();
    final billMonth = (bill['bill_month'] ?? bill['billMonth'] ?? '').toString();
    final billType = (bill['bill_type'] ?? bill['type'] ?? 'Maintenance').toString();
    final status = (bill['status'] ?? 'Pending').toString();
    final breakup = ((bill['breakup'] ?? bill['line_items']) as List?) ?? const [];

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── Bill Header Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.apartment, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(flatId.isEmpty ? 'Invoice' : flatId, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Flat: $flatId • $residentName', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                      StatusBadge.active(), // "Paid" status in header
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(billName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // ── Amount & Due Date Info ──
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
                        Text('Total Amount', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                        const SizedBox(height: 4),
                        Text(totalAmount, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Due Date', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                        const SizedBox(height: 4),
                        Text(dueDate, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── Bill Breakup ──
            Align(alignment: Alignment.centerLeft, child: Text('Breakup', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  if (breakup.isEmpty)
                    const LiveEmptyView(icon: Icons.list_alt_outlined, message: 'No breakup available.')
                  else
                    ...breakup.map((item) {
                      final m = item is Map ? item : const {};
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text((m['label'] ?? '').toString(), style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                            Text('₹ ${m['value'] ?? m['amount'] ?? 0}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                      Text(totalAmount, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── Bill Metadata ──
            _buildInfoRow('Bill Date', billDate),
            _buildInfoRow('Bill Month', billMonth),
            _buildInfoRow('Bill Type', billType),
            _buildInfoRow('Status', status, isStatus: true),

            const SizedBox(height: 32),
            // ── Action ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _downloadBill(context, bill),
                icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF064E3B)),
                label: Text('Download Bill', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF064E3B))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF064E3B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8))),
          isStatus 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
              )
            : Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showBillOptions(BuildContext context, WidgetRef ref, String id) {
    final bill = ref.read(invoiceDetailProvider(id)).valueOrNull ?? const <String, dynamic>{};
    final status = (bill['status'] ?? '').toString().toLowerCase();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Bill Options', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              ),
            ),
            _optionTile(
              icon: Icons.file_download_outlined,
              label: 'Download / Share PDF',
              onTap: () {
                Navigator.pop(sheetCtx);
                _downloadBill(context, bill);
              },
            ),
            if (status == 'draft')
              _optionTile(
                icon: Icons.publish_outlined,
                label: 'Publish Bill',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _publishBill(context, ref, id);
                },
              ),
            if (status != 'paid')
              _optionTile(
                icon: Icons.check_circle_outline,
                label: 'Mark as Paid',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _markPaid(context, ref, id, bill);
                },
              ),
            _optionTile(
              icon: Icons.refresh,
              label: 'Refresh',
              onTap: () {
                Navigator.pop(sheetCtx);
                ref.invalidate(invoiceDetailProvider(id));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryGreen, size: 22),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
      onTap: onTap,
    );
  }

  int _amountMinorOf(Map<String, dynamic> bill) {
    final minor = bill['total_minor'] ?? bill['totalMinor'] ?? bill['balance_minor'];
    if (minor is num) return minor.toInt();
    final major = bill['total'] ?? bill['amount'] ?? bill['totalAmount'] ?? 0;
    final value = major is num ? major : num.tryParse(major.toString()) ?? 0;
    return (value * 100).round();
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref, String id, Map<String, dynamic> bill) async {
    final amountMinor = _amountMinorOf(bill);
    if (amountMinor <= 0) {
      _toast(context, 'Cannot record payment: bill amount is zero.');
      return;
    }
    _toast(context, 'Recording payment…');
    try {
      await AdminFinanceService.recordPayment(invoiceId: id, amountMinor: amountMinor);
      ref.invalidate(invoiceDetailProvider(id));
      if (context.mounted) _toast(context, 'Payment recorded.');
    } catch (e) {
      if (context.mounted) _toast(context, 'Failed to record payment: $e');
    }
  }

  Future<void> _publishBill(BuildContext context, WidgetRef ref, String id) async {
    _toast(context, 'Publishing bill…');
    try {
      await AdminFinanceService.publishInvoice(id);
      ref.invalidate(invoiceDetailProvider(id));
      if (context.mounted) _toast(context, 'Bill published.');
    } catch (e) {
      if (context.mounted) _toast(context, 'Failed to publish: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimaryGreen,
        content: Text(message, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ));
  }

  Future<void> _downloadBill(BuildContext context, Map<String, dynamic> bill) async {
    try {
      final bytes = await _buildBillPdf(bill);
      final id = (bill['number'] ?? bill['id'] ?? 'bill').toString().replaceAll('/', '-');
      await Printing.sharePdf(bytes: bytes, filename: 'bill_$id.pdf');
    } catch (e) {
      if (context.mounted) _toast(context, 'Download failed: $e');
    }
  }

  Future<Uint8List> _buildBillPdf(Map<String, dynamic> bill) async {
    final flatId = (bill['flat_id'] ?? bill['unit'] ?? bill['flatId'] ?? '').toString();
    final residentName = (bill['resident_name'] ?? bill['residentName'] ?? '').toString();
    final number = (bill['number'] ?? bill['invoice_no'] ?? bill['id'] ?? '').toString();
    final totalMinor = bill['total_minor'] ?? bill['totalMinor'];
    final totalAmount = totalMinor is num
        ? (totalMinor / 100).toStringAsFixed(2)
        : (bill['total'] ?? bill['amount'] ?? bill['totalAmount'] ?? 0).toString();
    final dueDate = (bill['due_date'] ?? bill['dueDate'] ?? '').toString();
    final billDate = (bill['bill_date'] ?? bill['created_at'] ?? bill['billDate'] ?? '').toString();
    final status = (bill['status'] ?? 'Pending').toString();
    final lines = ((bill['breakup'] ?? bill['line_items'] ?? bill['lines']) as List?) ?? const [];

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MAINTENANCE BILL', style: pw.TextStyle(fontSize: 10, letterSpacing: 1.5, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Invoice $number', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            pw.Container(height: 2, width: 60, color: PdfColors.green900),
            pw.SizedBox(height: 16),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Flat: ${flatId.isEmpty ? '-' : flatId}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.Text('Resident: ${residentName.isEmpty ? '-' : residentName}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Bill Date: ${billDate.isEmpty ? '-' : billDate}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.Text('Due Date: ${dueDate.isEmpty ? '-' : dueDate}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('Breakup', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.SizedBox(height: 8),
            if (lines.isEmpty)
              pw.Text('No line items.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: lines.map((item) {
                  final m = item is Map ? item : const {};
                  final label = (m['label'] ?? m['description'] ?? '').toString();
                  final amt = m['amount_minor'] is num
                      ? ((m['amount_minor'] as num) / 100).toStringAsFixed(2)
                      : (m['value'] ?? m['amount'] ?? 0).toString();
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. $amt', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                  ]);
                }).toList(),
              ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total Amount', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs. $totalAmount', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              ]),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Status: ${status.toUpperCase()}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.Spacer(),
            pw.Text('Generated via Sero on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
