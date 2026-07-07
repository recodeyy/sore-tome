import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/resident/resident_billing_provider.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// UPI QR (Demo) — §7.2 a. Renders the server-built QR
/// (GET /funds/payments/upi-qr?invoiceId=) for the invoice's outstanding
/// balance. DEMO/TEST only: scanning does not settle anything; a society
/// admin confirms demo UPI payments (upi-demo/mark-paid).
class UpiQrScreen extends ConsumerWidget {
  final String invoiceId;
  final String invoiceNumber;

  const UpiQrScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrAsync = ref.watch(upiQrProvider(invoiceId));

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text('UPI QR (Demo)',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: qrAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(children: [SkeletonCard(height: 320), SkeletonCard(height: 120)]),
        ),
        error: (e, _) => ErrorRetryView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(upiQrProvider(invoiceId)),
        ),
        data: (qr) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── DEMO / TEST MODE banner ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kWarning.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, color: Color(0xFFB45309), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEMO / TEST MODE',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFFB45309))),
                        Text('This QR does not move real money.',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: const Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── QR card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kSlateBorder),
              ),
              child: Column(
                children: [
                  Text('Scan with any UPI app',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary)),
                  const SizedBox(height: 12),
                  if (qr.qrPngBase64.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(qr.qrPngBase64),
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('₹${qr.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary)),
                  const SizedBox(height: 4),
                  Text(qr.invoiceNumber.isNotEmpty ? qr.invoiceNumber : invoiceNumber,
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: kTextSecondary)),
                  const Divider(height: 28),
                  _detailRow('Payee', qr.payeeName),
                  _detailRow('VPA', qr.payeeVpa, copyable: true, context: context),
                  _detailRow('Currency', qr.currency),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── awaiting-confirmation note ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kLightMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kSlateBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: kPrimaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("I've paid — awaiting confirmation",
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryGreen)),
                        const SizedBox(height: 4),
                        Text(
                          'Demo UPI payments are confirmed manually by your '
                          'society admin. Once the admin verifies the transfer '
                          'reference, this invoice will be marked paid and a '
                          'receipt will appear under Receipts.',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: kTextSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool copyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary)),
          Row(
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary)),
              if (copyable && context != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('VPA copied')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 15, color: kTextSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
