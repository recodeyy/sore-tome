import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';

class SpendingBreakdownCard extends StatelessWidget {
  final Map<String, double> breakdown;
  final double totalSpent;

  const SpendingBreakdownCard({
    super.key,
    required this.breakdown,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPENDING BREAKDOWN',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.pie_chart_outline_rounded, color: kPrimaryGreen, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((e) {
            final percentage = totalSpent > 0 ? (e.value / totalSpent) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('₹${e.value.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: kPrimaryGreen.withValues(alpha: 0.8),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.1);
  }
}




