import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable status badge/chip widget
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final Color? textColor;
  final double fontSize;
  final EdgeInsets? padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.bgColor,
    this.textColor,
    this.fontSize = 10,
    this.padding,
  });

  /// Predefined status badges
  factory StatusBadge.active() => const StatusBadge(
        label: 'Active',
        bgColor: Color(0xFFD1FAE5),
        textColor: Color(0xFF059669),
      );

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        bgColor: Color(0xFFFEF3C7),
        textColor: Color(0xFFD97706),
      );

  factory StatusBadge.owner() => const StatusBadge(
        label: 'Owner',
        bgColor: Color(0xFFF0FDF4),
        textColor: Color(0xFF064E3B),
      );

  factory StatusBadge.tenant() => const StatusBadge(
        label: 'Tenant',
        bgColor: Color(0xFFFFF7ED),
        textColor: Color(0xFFEA580C),
      );

  factory StatusBadge.newBadge() => const StatusBadge(
        label: 'New',
        bgColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF16A34A),
      );

  factory StatusBadge.important() => const StatusBadge(
        label: 'Important',
        bgColor: Color(0xFFFEF3C7),
        textColor: Color(0xFFD97706),
      );

  factory StatusBadge.general() => const StatusBadge(
        label: 'General',
        bgColor: Color(0xFFEFF6FF),
        textColor: Color(0xFF2563EB),
      );

  @override
  Widget build(BuildContext context) {
    // Pill geometry aligned with the canonical StatusChip (sero_ui.dart).
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: textColor ?? const Color(0xFF64748B),
        ),
      ),
    );
  }
}
