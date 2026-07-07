import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/resident_dues_provider.dart';
import 'package:sero/screens/resident/funds/resident_funds_screen.dart';

/// Bill Details / Receipt (design: payment.png screen 2).
///
/// LIVE DATA: residentDuesProvider (GET /funds/maintenance-status). Pay Now
/// routes to ResidentFundsScreen (POST /funds/payments/*).
///
/// HONEST GAP: routes/funds.js exposes no receipt-PDF/download endpoint, so
/// "Download Receipt" is disabled with an explanatory note rather than faking
/// a file. Once a receipt endpoint exists, wire the button to it.
class BillDetailsScreen extends ConsumerWidget {
  const BillDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(residentDuesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text('Bill Details',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: duesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (e, _) => Center(
            child: Text('Could not load bill', style: GoogleFonts.outfit(color: kBadgeRedText))),
        data: (dues) {
          final amount = dues.amountOwed;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kSlateBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Maintenance Bill',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: kDeepNavy, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: dues.hasDues ? kBadgeAmberBg : kBadgeGreenBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(dues.hasDues ? 'PENDING' : 'PAID',
                              style: GoogleFonts.outfit(
                                  color: dues.hasDues ? kBadgeAmberText : kBadgeGreenText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (dues.unitInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(dues.unitInfo,
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                    ],
                    const Divider(height: 28),
                    _row('Bill Type', 'Maintenance'),
                    _row('Months Pending',
                        dues.monthsOverdue > 0 ? '${dues.monthsOverdue}' : '—'),
                    _row('Status', dues.hasDues ? 'Unpaid' : 'Cleared'),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: kDeepNavy, fontSize: 16)),
                        Text('₹${amount.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: kPrimaryGreen, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: dues.hasDues
                      ? () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ResidentFundsScreen()))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(dues.hasDues ? 'Pay Now' : 'No Dues',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // No receipt-download endpoint in routes/funds.js yet.
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Receipt download is not available yet — no receipt endpoint on the server.')),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: const BorderSide(color: kSlateBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Download Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
            Text(v, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: kDeepNavy, fontSize: 13)),
          ],
        ),
      );
}
