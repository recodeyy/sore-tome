import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/resident_dues_provider.dart';
import 'package:sero/models/fund.dart';
import '../funds/resident_funds_screen.dart';
import 'bill_details_screen.dart';
import 'auto_pay_setup_screen.dart';

/// Bills & Dues + Payment History (design: payment.png screens 1 & 3).
///
/// LIVE DATA:
///  - Total Due / dues breakdown -> residentDuesProvider (GET /funds/maintenance-status)
///  - Payment history (Paid tab) -> residentPaymentsProvider (GET /funds/transactions)
///  - Pay flow                   -> ResidentFundsScreen (POST /funds/payments/*)
class BillsDuesScreen extends ConsumerWidget {
  const BillsDuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(residentDuesProvider);
    final paymentsAsync = ref.watch(residentPaymentsProvider);

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
              error: (e, _) => _errorBox('Could not load your dues'),
              data: (dues) => _buildDueCard(context, dues),
            ),
            const SizedBox(height: 12),

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
              loading: () => const Center(
                  child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: kPrimaryGreen))),
              error: (e, _) => _errorBox('Could not load payment history'),
              data: (payments) {
                if (payments.isEmpty) {
                  return _emptyBox(Icons.receipt_long_outlined, 'No payments yet');
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
              onPressed: dues.hasDues
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ResidentFundsScreen()))
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kPrimaryGreen,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(dues.hasDues ? 'Pay All' : 'All Clear',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
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

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kBadgeRedBg, borderRadius: BorderRadius.circular(16)),
        child: Text(msg, style: GoogleFonts.outfit(color: kBadgeRedText, fontSize: 13)),
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
