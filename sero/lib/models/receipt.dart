/// Receipt from the Postgres finance API (GET /finance/receipts).
/// Money fields are integer minor units (paise); pg returns bigint as strings,
/// so parsing tolerates both String and num.
class Receipt {
  final String id;
  final String number; // e.g. RCPT-000001
  final int amountMinor;
  final String currency;
  final String status; // issued | void
  final DateTime? createdAt;
  final String provider; // razorpay | upi_demo | manual
  final String? providerPaymentId;
  final String paymentStatus; // pending | processing | verified | captured | failed | refunded
  final bool testMode;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? invoicePeriod;

  Receipt({
    required this.id,
    required this.number,
    required this.amountMinor,
    this.currency = 'INR',
    required this.status,
    this.createdAt,
    required this.provider,
    this.providerPaymentId,
    required this.paymentStatus,
    this.testMode = false,
    this.invoiceId,
    this.invoiceNumber,
    this.invoicePeriod,
  });

  double get amount => amountMinor / 100.0;
  bool get isVoid => status == 'void';

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final metadata = json['payment_metadata'];
    final testMode =
        metadata is Map<String, dynamic> && metadata['testMode'] == true;
    return Receipt(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      amountMinor: _toInt(json['amount_minor']),
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'issued',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      provider: json['provider'] as String? ?? 'manual',
      providerPaymentId: json['provider_payment_id'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'captured',
      testMode: testMode,
      invoiceId: json['invoice_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      invoicePeriod: json['invoice_period'] as String?,
    );
  }
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}
