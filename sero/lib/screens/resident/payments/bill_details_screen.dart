import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/resident_dues_provider.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/resident/resident_billing_provider.dart';
import 'package:sero/services/payment_service.dart';
import 'receipts_screen.dart';

/// Bill Details / Receipt (design: payment.png screen 2).
///
/// LIVE DATA: residentDuesProvider (GET /funds/maintenance-status).
///  - Pay Now opens the Razorpay TEST checkout directly (DuesCheckout →
///    POST /funds/payments/create-order + /verify). Previously it pushed the
///    read-only Treasury screen, a dead end with no pay action.
///  - Download Receipt opens ReceiptsScreen (GET /finance/receipts + PDF).
class BillDetailsScreen extends ConsumerStatefulWidget {
  const BillDetailsScreen({super.key});

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  bool _paying = false;
  late final DuesCheckout _checkout;

  @override
  void initState() {
    super.initState();
    _checkout = DuesCheckout(
      onProcessing: () {
        if (mounted) setState(() => _paying = true);
      },
      onSuccess: (paymentId) {
        if (!mounted) return;
        setState(() => _paying = false);
        ref.invalidate(residentDuesProvider);
        ref.invalidate(residentBalanceProvider);
        ref.invalidate(residentPaymentsProvider);
        ref.invalidate(receiptsProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: kPrimaryGreen,
          content: Text('Payment successful — ID $paymentId'),
        ));
      },
      onFailure: (message) {
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $message')),
        );
      },
    );
  }

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
  }

  Future<void> _payNow(ResidentDues dues) async {
    if (_paying || !dues.hasDues) return;
    setState(() => _paying = true);
    final user = ref.read(authProvider).value;
    await _checkout.start(
      amount: dues.amountOwed,
      title: 'Maintenance Payment',
      description: dues.unitInfo.isEmpty ? 'Society maintenance dues' : dues.unitInfo,
      contact: user?.phone,
    );
    if (mounted && _paying) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: dues.hasDues && !_paying ? () => _payNow(dues) : null,
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
                  // Receipts live in the §7.2 finance engine
                  // (GET /finance/receipts + /:id/pdf) — ReceiptsScreen
                  // downloads the authenticated PDF with preview/share.
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ReceiptsScreen())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryGreen,
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
