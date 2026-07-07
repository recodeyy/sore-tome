import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FinancialOverviewCard extends StatelessWidget {
  final String total;
  final double progress;
  final String target;
  final String percentage;
  final VoidCallback onTap;
  final VoidCallback onEditTarget;

  const FinancialOverviewCard({
    super.key,
    required this.total,
    required this.progress,
    required this.target,
    required this.percentage,
    required this.onTap,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF345D7E),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "COLLECTION TOTAL",
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onEditTarget,
                    child: Row(
                      children: [
                        Text(
                          "TARGET: $target",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "$percentage COLLECTED",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
    );
  }
}






