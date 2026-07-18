import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/resident_dues_provider.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/resident/resident_billing_provider.dart';
import 'package:sero/models/fund.dart';
import 'package:sero/models/invoice.dart';
import 'package:sero/services/payment_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import 'bill_details_screen.dart';
import 'auto_pay_setup_screen.dart';
import 'pay_invoice_sheet.dart';
import 'receipts_screen.dart';

/// Bills & Dues + Payment History (design: payment.png screens 1 & 3).
///
/// LIVE DATA:
///  - Total Due / dues breakdown -> residentDuesProvider (GET /funds/maintenance-status)
///  - Published invoices (§7.2)  -> publishedInvoicesProvider (GET /finance/invoices)
///  - Payment history (Paid tab) -> residentPaymentsProvider (GET /funds/transactions)
///  - Pay All (legacy dues)      -> PaymentService (POST /funds/payments/*) → Razorpay
///  - Pay invoice (§7.2)         -> PayInvoiceSheet (POST /finance/payments/*) → Razorpay
///  - Receipts                   -> ReceiptsScreen (GET /finance/receipts + /:id/pdf)
class BillsDuesScreen extends ConsumerStatefulWidget {
  const BillsDuesScreen({super.key});

  @override
  ConsumerState<BillsDuesScreen> createState() => _BillsDuesScreenState();
}

class _BillsDuesScreenState extends ConsumerState<BillsDuesScreen> {
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

  /// Opens the Razorpay (TEST) checkout for the resident's outstanding
  /// maintenance dues via the legacy /funds payment path. The backend verifies
  /// the signature and records the credit transaction; providers refresh in
  /// the checkout callbacks.
  Future<void> _payDues(ResidentDues dues) async {
    if (_paying || !dues.hasDues) return;
    setState(() => _paying = true);
    final user = ref.read(authProvider).value;
    await _checkout.start(
      amount: dues.amountOwed,
      title: 'Maintenance Payment',
      description: dues.unitInfo.isEmpty ? 'Society maintenance dues' : dues.unitInfo,
      contact: user?.phone,
    );
    // start() returns once the checkout sheet is open (or failed to open);
    // reset the spinner if no callback has fired yet so the button recovers
    // when the user dismisses the sheet without paying.
    if (mounted && _paying) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final duesAsync = ref.watch(residentDuesProvider);
    final paymentsAsync = ref.watch(residentPaymentsProvider);
    final invoicesAsync = ref.watch(publishedInvoicesProvider);
    final settledIds = ref.watch(settledInvoiceIdsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async {
          ref.invalidate(residentDuesProvider);
          ref.invalidate(residentPaymentsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 140),
          children: [
            Text('Bills & Dues',
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.w700, color: kDeepNavy)),
            const SizedBox(height: 16),

            // ── Total Due card ──
            duesAsync.when(
              loading: () => const _DueSkeleton(),
              error: (e, _) => ErrorRetryView(
                message: 'Could not load your dues.',
                onRetry: () => ref.invalidate(residentDuesProvider),
              ),
              data: (dues) => _buildDueCard(context, dues),
            ),
            const SizedBox(height: 12),

            // ── Published invoices (§7.2 finance engine) ──
            invoicesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(), // legacy dues card above still works
              data: (invoices) {
                final open = invoices.where((i) => !settledIds.contains(i.id)).toList();
                if (open.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _label('Invoices'),
                    const SizedBox(height: 12),
                    ...open.map((inv) => _invoiceRow(context, inv)),
                  ],
                );
              },
            ),

            // Quick links to Bill Details / Receipt and Auto-Pay setup
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BillDetailsScreen())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreen,
                      side: const BorderSide(color: kSlateBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text('Bill Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AutoPaySetupScreen())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreen,
                      side: const BorderSide(color: kSlateBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: Text('Auto-Pay', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ReceiptsScreen())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreen,
                      side: const BorderSide(color: kSlateBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text('Receipts', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _label('Outstanding'),
            const SizedBox(height: 12),
            duesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (dues) {
                if (!dues.hasDues) {
                  return _emptyBox(Icons.check_circle_outline, 'No outstanding bills');
                }
                return _billRow(
                  'Maintenance',
                  dues.monthsOverdue > 0
                      ? '${dues.monthsOverdue} month${dues.monthsOverdue > 1 ? 's' : ''} pending'
                      : 'Pending',
                  dues.amountOwed,
                  dues.monthsOverdue > 1 ? 'OVERDUE' : 'PENDING',
                );
              },
            ),
            const SizedBox(height: 24),

            _label('Payment History'),
            const SizedBox(height: 12),
            paymentsAsync.when(
              loading: () => const Column(children: [
                SkeletonCard(height: 72),
                SkeletonCard(height: 72),
                SkeletonCard(height: 72),
              ]),
              error: (e, _) => ErrorRetryView(
                message: 'Could not load payment history.',
                onRetry: () => ref.invalidate(residentPaymentsProvider),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments yet',
                    message: 'Payments you make will appear here with receipts.',
                  );
                }
                return Column(children: payments.map(_paidRow).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueCard(BuildContext context, ResidentDues dues) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kPremiumGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Due',
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 4),
          Text('₹${dues.amountOwed.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
          if (dues.unitInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(dues.unitInfo,
                style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Opens the Razorpay TEST checkout (UPI / cards / netbanking)
              // directly — previously this pushed the read-only Treasury
              // screen, a dead end with no pay action.
              onPressed: dues.hasDues && !_paying ? () => _payDues(dues) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kPrimaryGreen,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                  _paying ? 'Opening checkout…' : (dues.hasDues ? 'Pay All' : 'All Clear'),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// One published §7.2 invoice with a Pay button that opens [PayInvoiceSheet]
  /// (Razorpay TEST checkout; backend-verified; receipt generated on capture).
  Widget _invoiceRow(BuildContext context, Invoice inv) {
    final total = (inv.totalMinor + inv.lateFeeMinor) / 100.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kLightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_outlined, color: kPrimaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.number,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                Text(
                  [
                    if (inv.period != null && inv.period!.isNotEmpty) inv.period!,
                    if (inv.dueDate != null) 'Due ${inv.dueDate!.split('T').first}',
                  ].join('  ·  '),
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${total.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => showPayInvoiceSheet(context, inv),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Pay',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String title, String subtitle, double amount, String status) {
    final isOverdue = status == 'OVERDUE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isOverdue ? kBadgeRedText : kBadgeAmberText).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.home_repair_service_outlined,
                color: isOverdue ? kBadgeRedText : kBadgeAmberText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                Text(subtitle,
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOverdue ? kBadgeRedBg : kBadgeAmberBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: GoogleFonts.outfit(
                        color: isOverdue ? kBadgeRedText : kBadgeAmberText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paidRow(FundTransaction t) {
    final d = t.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBadgeGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline, color: kBadgeGreenText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title.isEmpty ? 'Payment' : t.title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                Text('${d.day}/${d.month}/${d.year}',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Text('₹${t.amount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kBadgeGreenText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));

  Widget _emptyBox(IconData icon, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );

}

class _DueSkeleton extends StatelessWidget {
  const _DueSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
}
