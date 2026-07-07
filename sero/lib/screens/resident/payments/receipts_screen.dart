import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/receipt.dart';
import 'package:sero/providers/resident/resident_billing_provider.dart';
import 'package:sero/services/api_client.dart';
import 'package:sero/widgets/shared/payment_status_chip.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Receipts (§7.2 b) — the resident's own receipts from GET /finance/receipts.
/// Tap downloads the PDF bytes from GET /finance/receipts/:id/pdf with the
/// Bearer auth header (the endpoint requires auth — a plain url_launcher would
/// 401), caches them in the temp dir (path_provider) and opens an in-app
/// preview via the `printing` package (share/print built in). No new deps.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  String? _downloadingId; // double-tap protection per row

  Future<void> _openPdf(Receipt receipt) async {
    if (_downloadingId != null) return;
    setState(() => _downloadingId = receipt.id);
    try {
      final headers = await ApiClient.getHeaders();
      final res = await http
          .get(
            Uri.parse('${ApiClient.baseUrl}/finance/receipts/${receipt.id}/pdf'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.statusCode == 403
              ? 'You can only download your own receipts.'
              : 'Could not download the receipt (${res.statusCode}).'),
        ));
        return;
      }
      final bytes = res.bodyBytes;
      // Cache a copy in the temp dir so the preview's share sheet has a file.
      try {
        final dir = await getTemporaryDirectory();
        await File('${dir.path}/${receipt.number}.pdf').writeAsBytes(bytes);
      } catch (_) {
        // Preview works from memory; caching is best-effort.
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ReceiptPdfPreview(title: receipt.number, bytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download the receipt. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text('Receipts',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async => ref.invalidate(receiptsProvider),
        child: receiptsAsync.when(
          loading: () => const SkeletonList(itemCount: 5, itemHeight: 96),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              ErrorRetryView(
                message: 'Could not load your receipts.',
                onRetry: () => ref.invalidate(receiptsProvider),
              ),
            ],
          ),
          data: (receipts) {
            if (receipts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No receipts yet',
                    message:
                        'Receipts appear here after a payment is captured. Tap one to download its PDF.',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              itemBuilder: (_, i) => _receiptCard(receipts[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _receiptCard(Receipt r) {
    final downloading = _downloadingId == r.id;
    final date = r.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: downloading ? null : () => _openPdf(r),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kLightMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: downloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimaryGreen))
                          : const Icon(Icons.receipt_long_rounded,
                              color: kPrimaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.number,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: kTextPrimary,
                                  fontSize: 14)),
                          Text(
                            [
                              if (r.invoiceNumber != null) r.invoiceNumber!,
                              if (r.invoicePeriod != null) r.invoicePeriod!,
                              if (date != null)
                                '${date.day}/${date.month}/${date.year}',
                            ].join('  ·  '),
                            style: GoogleFonts.outfit(
                                color: kTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text('₹${r.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: kTextPrimary,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _providerChip(r),
                    PaymentStatusChip(status: r.paymentStatus),
                    if (r.isVoid)
                      const StatusChip(label: 'VOID', semantic: ChipSemantic.error),
                    StatusChip(
                      label: downloading ? 'DOWNLOADING…' : 'PDF',
                      semantic: ChipSemantic.neutral,
                      icon: Icons.picture_as_pdf_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerChip(Receipt r) {
    if (r.provider == 'upi_demo') {
      return const StatusChip(label: 'UPI DEMO', semantic: ChipSemantic.warning);
    }
    if (r.provider == 'razorpay') {
      return StatusChip(
        label: r.testMode ? 'RAZORPAY · TEST' : 'RAZORPAY',
        semantic: ChipSemantic.info,
      );
    }
    return StatusChip(
        label: r.provider.toUpperCase(), semantic: ChipSemantic.neutral);
  }
}

/// In-app PDF preview backed by the `printing` package (already a dependency);
/// gives pinch-zoom pages plus built-in print/share actions.
class _ReceiptPdfPreview extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _ReceiptPdfPreview({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '$title.pdf',
      ),
    );
  }
}
