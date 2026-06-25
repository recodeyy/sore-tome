import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

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
          IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)), onPressed: () => AdminActions.comingSoon(context, 'Bill options')),
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
              data: (bill) => _buildBody(context, bill),
            ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> bill) {
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
                onPressed: () => AdminActions.comingSoon(context, 'Bill download'),
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
}
