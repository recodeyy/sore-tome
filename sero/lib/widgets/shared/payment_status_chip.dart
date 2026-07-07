import 'package:flutter/material.dart';

import 'sero_ui.dart';

/// Canonical StatusChip semantics for payment lifecycle states (§7.2 d):
/// pending → warning, processing → info, verified/captured → success,
/// failed → error, refunded (and anything unknown) → neutral.
ChipSemantic paymentStatusSemantic(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return ChipSemantic.warning;
    case 'processing':
      return ChipSemantic.info;
    case 'verified':
    case 'captured':
      return ChipSemantic.success;
    case 'failed':
      return ChipSemantic.error;
    case 'refunded':
    default:
      return ChipSemantic.neutral;
  }
}

/// A [StatusChip] pre-wired with payment-state semantics.
class PaymentStatusChip extends StatelessWidget {
  final String status;

  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: status.toUpperCase(),
      semantic: paymentStatusSemantic(status),
    );
  }
}
