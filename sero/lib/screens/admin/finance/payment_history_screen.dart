import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';

/// Payment History — Screen 4 of 6
/// Searchable list of transactions with status filtering and detailed rows.
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _query = '';
  String? _statusFilter; // null = all
  DateTimeRange? _dateRange;

  static const List<String> _statuses = ['Paid', 'Pending', 'Failed', 'Draft', 'Published'];

  bool get _hasActiveFilters => _statusFilter != null || _dateRange != null;

  DateTime? _parseDate(Map m) {
    final raw = (m['date'] ?? m['created_at'] ?? m['due_date'] ?? '').toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _passesFilters(Map m) {
    if (_statusFilter != null) {
      final s = (m['status'] ?? '').toString().toLowerCase();
      if (s != _statusFilter!.toLowerCase()) return false;
    }
    if (_dateRange != null) {
      final d = _parseDate(m);
      if (d != null) {
        final from = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
        final to = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
        if (d.isBefore(from) || d.isAfter(to)) return false;
      }
    }
    return true;
  }

  void _openFilters() {
    String? tmpStatus = _statusFilter;
    DateTimeRange? tmpRange = _dateRange;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Filter Payments', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Text('Status', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _selectChip('All', tmpStatus == null, () => setSheet(() => tmpStatus = null)),
                    ..._statuses.map((s) => _selectChip(s, tmpStatus == s, () => setSheet(() => tmpStatus = s))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Date Range', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: sheetCtx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: tmpRange,
                    );
                    if (picked != null) setSheet(() => tmpRange = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          tmpRange == null
                              ? 'Any date'
                              : '${DateFormat('dd MMM yyyy').format(tmpRange!.start)} - ${DateFormat('dd MMM yyyy').format(tmpRange!.end)}',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        if (tmpRange != null)
                          GestureDetector(onTap: () => setSheet(() => tmpRange = null), child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() { _statusFilter = null; _dateRange = null; });
                          Navigator.pop(sheetCtx);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: kPrimaryGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text('Clear', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimaryGreen)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() { _statusFilter = tmpStatus; _dateRange = tmpRange; });
                          Navigator.pop(sheetCtx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text('Apply', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kPrimaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? kPrimaryGreen : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(paymentHistoryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Payment History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFF1E293B)), onPressed: _openFilters),
              if (_hasActiveFilters)
                Positioned(right: 10, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kPrimaryGreen, shape: BoxShape.circle))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search by Flat, Bill No., Name..',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onFilterTap: _openFilters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openFilters,
                  child: _FilterChip(label: _statusFilter ?? 'All Status', active: _statusFilter != null),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openFilters,
                  child: _FilterChip(label: _dateRange == null ? 'All Dates' : 'Date Range', active: _dateRange != null),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openFilters,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Icon(Icons.tune, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // ── Payment List ──
          Expanded(
            child: invoicesAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading payments…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(paymentHistoryProvider),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const LiveEmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: 'No payment history yet.',
                  );
                }
                final filtered = invoices.where((inv) {
                  final m = inv is Map ? inv : const {};
                  if (!_passesFilters(m)) return false;
                  if (_query.isEmpty) return true;
                  final hay = [
                    m['title'], m['invoice_no'], m['unit'], m['flat'],
                    m['resident_name'], m['subtitle'], m['status'],
                  ].where((e) => e != null).join(' ').toLowerCase();
                  return hay.contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const LiveEmptyView(
                    icon: Icons.search_off,
                    message: 'No payments match your search.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index] is Map ? filtered[index] as Map : const {};
                    return _PaymentItemRow(
                      title: (m['title'] ?? m['invoice_no'] ?? m['unit'] ?? 'Invoice').toString(),
                      subtitle: (m['subtitle'] ?? m['resident_name'] ?? m['flat'] ?? '').toString(),
                      amount: '₹ ${m['amount'] ?? m['total'] ?? 0}',
                      date: (m['date'] ?? m['created_at'] ?? m['due_date'] ?? '').toString(),
                      status: (m['status'] ?? 'Pending').toString(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _PaymentItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final String status;

  const _PaymentItemRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Center(
               child: Icon(
                 status == 'Paid' ? Icons.check_circle_outline : 
                 status == 'Pending' ? Icons.access_time : Icons.cancel_outlined,
                 color: statusColor, size: 22,
               ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(date, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              _buildStatusBadge(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid': return const Color(0xFF059669);
      case 'Pending': return const Color(0xFFEA580C);
      case 'Failed': return const Color(0xFFDC2626);
      default: return const Color(0xFF64748B);
    }
  }
}
