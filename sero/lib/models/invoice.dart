/// Invoice from the Postgres finance API (/finance/invoices).
/// Money fields are integer minor units (paise); pg returns bigint as strings,
/// so parsing tolerates both String and num.
class Invoice {
  final String id;
  final String number;
  final String? period;
  final String status; // draft | published | cancelled
  final int subtotalMinor;
  final int taxMinor;
  final int totalMinor;
  final String currency;
  final String? dueDate;
  final DateTime? createdAt;
  final int lateFeeMinor;
  final String? lateFeeAppliedAt;
  final List<InvoiceLine> lines;

  Invoice({
    required this.id,
    required this.number,
    this.period,
    required this.status,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.totalMinor,
    this.currency = 'INR',
    this.dueDate,
    this.createdAt,
    this.lateFeeMinor = 0,
    this.lateFeeAppliedAt,
    this.lines = const [],
  });

  double get total => totalMinor / 100.0;
  double get lateFee => lateFeeMinor / 100.0;
  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get hasLateFee => lateFeeMinor > 0;

  /// True when the due date has passed.
  bool get isOverdue {
    final due = DateTime.tryParse(dueDate ?? '');
    return due != null && due.isBefore(DateTime.now());
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      period: json['period'] as String?,
      status: json['status'] as String? ?? 'draft',
      subtotalMinor: _toInt(json['subtotal_minor']),
      taxMinor: _toInt(json['tax_minor']),
      totalMinor: _toInt(json['total_minor']),
      currency: json['currency'] as String? ?? 'INR',
      dueDate: json['due_date'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      lateFeeMinor: _toInt(json['late_fee_minor']),
      lateFeeAppliedAt: json['late_fee_applied_at']?.toString(),
      lines: (json['lines'] as List?)
              ?.map((l) => InvoiceLine.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class InvoiceLine {
  final String description;
  final String? component;
  final int quantity;
  final int unitPriceMinor;
  final int taxMinor;
  final int amountMinor;

  InvoiceLine({
    required this.description,
    this.component,
    required this.quantity,
    required this.unitPriceMinor,
    required this.taxMinor,
    required this.amountMinor,
  });

  double get amount => amountMinor / 100.0;

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      description: json['description'] as String? ?? '',
      component: json['component'] as String?,
      quantity: _toInt(json['quantity'], fallback: 1),
      unitPriceMinor: _toInt(json['unit_price_minor']),
      taxMinor: _toInt(json['tax_minor']),
      amountMinor: _toInt(json['amount_minor']),
    );
  }
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}
