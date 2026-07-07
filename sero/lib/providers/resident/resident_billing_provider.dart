import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/invoice.dart';
import '../../models/receipt.dart';
import '../../services/api_client.dart';

/// §7.2 resident billing — live Postgres finance API.
///
/// LIVE DATA:
///  - publishedInvoicesProvider -> GET /finance/invoices?status=published
///  - invoiceDetailProvider     -> GET /finance/invoices/:id (includes lines)
///  - receiptsProvider          -> GET /finance/receipts?limit= (residents see own)
///  - upiQrProvider             -> GET /funds/payments/upi-qr?invoiceId= (DEMO/TEST)

/// Published invoices for the society. The API scopes receipts (not invoices)
/// per resident, so the Pay screen cross-references [receiptsProvider] to hide
/// invoices that already have a captured payment.
final publishedInvoicesProvider =
    FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final res =
      await ApiClient.request('GET', '/finance/invoices?status=published&limit=100');
  if (res.statusCode != 200) {
    throw Exception('Failed to load invoices (${res.statusCode})');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['invoices'] as List? ?? const [])
      .map((j) => Invoice.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// One invoice with its line items (GET /finance/invoices/:id).
final invoiceDetailProvider =
    FutureProvider.autoDispose.family<Invoice, String>((ref, invoiceId) async {
  final res = await ApiClient.request('GET', '/finance/invoices/$invoiceId');
  if (res.statusCode != 200) {
    throw Exception('Failed to load invoice (${res.statusCode})');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return Invoice.fromJson(data['invoice'] as Map<String, dynamic>);
});

/// The resident's own receipts, newest first.
final receiptsProvider = FutureProvider.autoDispose<List<Receipt>>((ref) async {
  final res = await ApiClient.request('GET', '/finance/receipts?limit=100');
  if (res.statusCode != 200) {
    throw Exception('Failed to load receipts (${res.statusCode})');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['receipts'] as List? ?? const [])
      .map((j) => Receipt.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Invoice ids that already have a captured (non-void) payment.
final settledInvoiceIdsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final receipts = ref.watch(receiptsProvider).value ?? const <Receipt>[];
  return receipts
      .where((r) => !r.isVoid && r.paymentStatus == 'captured' && r.invoiceId != null)
      .map((r) => r.invoiceId!)
      .toSet();
});

/// Server-built UPI intent + QR for an invoice's outstanding balance (DEMO).
class UpiQrData {
  final String upiUri;
  final String qrPngBase64;
  final int amountMinor;
  final double amount;
  final String currency;
  final String payeeVpa;
  final String payeeName;
  final String invoiceNumber;
  final String note; // "DEMO/TEST"

  UpiQrData({
    required this.upiUri,
    required this.qrPngBase64,
    required this.amountMinor,
    required this.amount,
    required this.currency,
    required this.payeeVpa,
    required this.payeeName,
    required this.invoiceNumber,
    required this.note,
  });

  factory UpiQrData.fromJson(Map<String, dynamic> json) {
    final payee = json['payee'] as Map<String, dynamic>? ?? const {};
    return UpiQrData(
      upiUri: json['upiUri'] as String? ?? '',
      qrPngBase64: json['qrPngBase64'] as String? ?? '',
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      payeeVpa: payee['vpa'] as String? ?? '',
      payeeName: payee['name'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      note: json['note'] as String? ?? 'DEMO/TEST',
    );
  }
}

final upiQrProvider =
    FutureProvider.autoDispose.family<UpiQrData, String>((ref, invoiceId) async {
  final res =
      await ApiClient.request('GET', '/funds/payments/upi-qr?invoiceId=$invoiceId');
  if (res.statusCode != 200) {
    String message = 'Failed to build UPI QR (${res.statusCode})';
    try {
      final err = jsonDecode(res.body)['error'];
      if (err is String && err.isNotEmpty) message = err;
    } catch (_) {}
    throw Exception(message);
  }
  return UpiQrData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
});
