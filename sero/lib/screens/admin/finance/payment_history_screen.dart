import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/common/status_badge.dart';

/// Payment History — Screen 4 of 6
/// Searchable list of transactions with status filtering and detailed rows.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Payment History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFF1E293B)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search by Flat, Bill No., Name..',
              onChanged: (v) {},
              onFilterTap: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _FilterChip(label: 'All Status', active: true),
                const SizedBox(width: 8),
                _FilterChip(label: 'All Months', active: false),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Icon(Icons.tune, size: 18, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // ── Payment List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              itemCount: MockFinanceData.paymentHistory.length,
              itemBuilder: (context, index) {
                final payment = MockFinanceData.paymentHistory[index];
                return _PaymentItemRow(
                  title: payment['title'],
                  subtitle: payment['subtitle'],
                  amount: payment['amount'],
                  date: payment['date'],
                  status: payment['status'],
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
