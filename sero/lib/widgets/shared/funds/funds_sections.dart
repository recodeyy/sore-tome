import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/fund.dart';

class OverdueSection extends StatelessWidget {
  final List<OverdueResident> overdueList;
  const OverdueSection({super.key, required this.overdueList});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'OUTSTANDING DUES',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: overdueList.length,
            itemBuilder: (context, index) {
              final item = overdueList[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kSlateBorder.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red.shade50,
                      child: Text(
                        item.name[0],
                        style: GoogleFonts.outfit(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          Text('₹${item.amountOwed.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DisbursementsSection extends StatelessWidget {
  final List<FundTransaction> transactions;
  final VoidCallback? onSmartScan;
  final VoidCallback? onManualLog;
  final bool isResidentView;

  const DisbursementsSection({
    super.key,
    required this.transactions,
    this.onSmartScan,
    this.onManualLog,
    this.isResidentView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT DISBURSEMENTS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              if (!isResidentView)
                Row(
                  children: [
                    if (onSmartScan != null)
                      _ActionButton(icon: Icons.qr_code_scanner_rounded, onTap: onSmartScan!),
                    const SizedBox(width: 12),
                    if (onManualLog != null)
                      _ActionButton(icon: Icons.add_rounded, onTap: onManualLog!),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...transactions.map((tx) => _TransactionItem(tx: tx)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: kSlateBorder),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final FundTransaction tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.amount < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isExpense ? Colors.red.shade50 : kPrimaryGreen.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 18,
              color: isExpense ? Colors.red : kPrimaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(tx.category, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(
            '${isExpense ? "-" : "+"}₹${tx.amount.abs().toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isExpense ? const Color(0xFF0F172A) : kPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}




