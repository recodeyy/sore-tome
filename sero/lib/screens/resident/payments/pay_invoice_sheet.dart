import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/invoice.dart';
import 'package:sero/providers/resident/resident_billing_provider.dart';
import 'package:sero/providers/shared/resident_dues_provider.dart';
import 'package:sero/services/payment_service.dart';
import 'package:sero/widgets/shared/payment_status_chip.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

import 'upi_qr_screen.dart';

/// "Pay now" bottom sheet (§7.2 a): invoice breakdown (due date, late fee,
/// line items) + two payment options:
///  - Card/UPI via Razorpay (TEST): create-order -> checkout -> Processing…
///    until POST /finance/payments/verify returns (client callback is NOT
///    success) -> success/failure card.
///  - UPI QR (Demo): server-built QR; an admin confirms demo payments.
Future<void> showPayInvoiceSheet(BuildContext context, Invoice invoice) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PayInvoiceSheet(invoice: invoice),
  );
}

enum _PayPhase { idle, creating, checkout, verifying, success, failed }

class PayInvoiceSheet extends ConsumerStatefulWidget {
  final Invoice invoice;

  const PayInvoiceSheet({super.key, required this.invoice});

  @override
  ConsumerState<PayInvoiceSheet> createState() => _PayInvoiceSheetState();
}

class _PayInvoiceSheetState extends ConsumerState<PayInvoiceSheet> {
  _PayPhase _phase = _PayPhase.idle;
  String _failureMessage = '';
  String? _receiptNumber;
  late final InvoiceCheckout _checkout;

  bool get _inFlight =>
      _phase == _PayPhase.creating ||
      _phase == _PayPhase.checkout ||
      _phase == _PayPhase.verifying;

  @override
  void initState() {
    super.initState();
    _checkout = InvoiceCheckout(
      onProcessing: () {
        if (mounted) setState(() => _phase = _PayPhase.verifying);
      },
      onSuccess: (result) {
        if (!mounted) return;
        final receipt = result['receipt'];
        setState(() {
          _phase = _PayPhase.success;
          _receiptNumber =
              receipt is Map<String, dynamic> ? receipt['number'] as String? : null;
        });
        _refreshBilling();
      },
      onFailure: (message) {
        if (!mounted) return;
        setState(() {
          _phase = _PayPhase.failed;
          _failureMessage = message;
        });
      },
    );
  }

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
  }

  void _refreshBilling() {
    ref.invalidate(receiptsProvider);
    ref.invalidate(publishedInvoicesProvider);
    ref.invalidate(residentDuesProvider);
  }

  Future<void> _startRazorpay() async {
    if (_inFlight) return; // double-tap protection
    setState(() => _phase = _PayPhase.creating);
    await _checkout.start(
      invoiceId: widget.invoice.id,
      invoiceNumber: widget.invoice.number,
    );
    // If create-order failed, onFailure already moved us to `failed`;
    // otherwise the Razorpay checkout is now open.
    if (mounted && _phase == _PayPhase.creating) {
      setState(() => _phase = _PayPhase.checkout);
    }
  }

  void _openUpiQr() {
    if (_inFlight) return;
    final invoice = widget.invoice;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiQrScreen(
          invoiceId: invoice.id,
          invoiceNumber: invoice.number,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(invoiceDetailProvider(widget.invoice.id));
    final invoice = detailAsync.value ?? widget.invoice;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kSlateBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              switch (_phase) {
                _PayPhase.verifying => _processingCard(),
                _PayPhase.success => _successCard(invoice),
                _PayPhase.failed => _failureCard(),
                _ => _payBody(invoice, detailAsync.isLoading),
              },
            ],
          ),
        ),
      ),
    );
  }

  // ── idle / creating / checkout ─────────────────────────────────────────────

  Widget _payBody(Invoice invoice, bool loadingDetail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Pay ${invoice.number}',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
            ),
            StatusChip(
              label: invoice.isOverdue ? 'OVERDUE' : 'DUE',
              semantic:
                  invoice.isOverdue ? ChipSemantic.error : ChipSemantic.warning,
            ),
          ],
        ),
        if (invoice.period != null || invoice.dueDate != null) ...[
          const SizedBox(height: 4),
          Text(
            [
              if (invoice.period != null) 'Period ${invoice.period}',
              if (invoice.dueDate != null) 'Due ${_fmtDate(invoice.dueDate!)}',
            ].join('  ·  '),
            style: GoogleFonts.outfit(fontSize: 12, color: kTextSecondary),
          ),
        ],
        const SizedBox(height: 16),
        _breakdownCard(invoice, loadingDetail),
        const SizedBox(height: 20),
        // Option 1: Razorpay (Test)
        ElevatedButton.icon(
          onPressed: _inFlight ? null : _startRazorpay,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _phase == _PayPhase.creating || _phase == _PayPhase.checkout
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.credit_card_rounded, size: 20),
          label: Text(
            _phase == _PayPhase.checkout
                ? 'Waiting for checkout…'
                : 'Card / UPI via Razorpay (Test)',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        // Option 2: UPI QR (Demo)
        OutlinedButton.icon(
          onPressed: _inFlight ? null : _openUpiQr,
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryGreen,
            side: const BorderSide(color: kSlateBorder),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.qr_code_2_rounded, size: 20),
          label: Text('UPI QR (Demo)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(
          'Test mode — no real money moves. Card payments are verified by the '
          'server before the invoice is marked paid.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }

  Widget _breakdownCard(Invoice invoice, bool loadingDetail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSlateBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Column(
        children: [
          if (invoice.lines.isNotEmpty) ...[
            ...invoice.lines.map((l) => _row(
                  l.component != null && l.component!.isNotEmpty
                      ? '${l.description} (${l.component})'
                      : l.description,
                  '₹${l.amount.toStringAsFixed(2)}',
                )),
            const Divider(height: 20),
          ] else if (loadingDetail) ...[
            _row('Loading line items…', ''),
            const Divider(height: 20),
          ],
          _row('Subtotal', '₹${(invoice.subtotalMinor / 100).toStringAsFixed(2)}'),
          _row('Tax', '₹${(invoice.taxMinor / 100).toStringAsFixed(2)}'),
          if (invoice.hasLateFee)
            _row('Late fee', '₹${invoice.lateFee.toStringAsFixed(2)}',
                valueColor: kError),
          const Divider(height: 20),
          _row('Total', '₹${invoice.total.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: bold ? 14 : 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: bold ? kTextPrimary : kTextSecondary)),
          ),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? (bold ? kPrimaryGreen : kTextPrimary))),
        ],
      ),
    );
  }

  // ── processing / success / failure ────────────────────────────────────────

  Widget _processingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(color: kPrimaryGreen, strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text('Processing…',
              style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w800, color: kTextPrimary)),
          const SizedBox(height: 6),
          Text(
            'Confirming your payment with the server.\nPlease keep the app open.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _successCard(Invoice invoice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: kLightMint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: kAccentGreen, size: 38),
          ),
          const SizedBox(height: 16),
          Text('Payment successful',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
          const SizedBox(height: 6),
          Text(
            '₹${invoice.total.toStringAsFixed(2)} paid for ${invoice.number}'
            '${_receiptNumber != null ? '\nReceipt $_receiptNumber' : ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 12),
          const Center(child: PaymentStatusChip(status: 'captured')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _failureCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: kError, size: 38),
          ),
          const SizedBox(height: 16),
          Text('Payment failed',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
          const SizedBox(height: 6),
          Text(
            _failureMessage.isEmpty
                ? 'The payment could not be completed.'
                : _failureMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _phase = _PayPhase.idle),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Try again',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, color: kTextSecondary)),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year}';
  }
}
