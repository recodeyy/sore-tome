import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class FinancialCard extends StatelessWidget {
  final String title;
  final String amount;
  final String trend;
  final IconData icon;
  final bool isPositive;
  final bool isHero;
  final bool isNeutral;

  const FinancialCard({
    super.key,
    required this.title,
    required this.amount,
    required this.trend,
    required this.icon,
    this.isPositive = false,
    this.isHero = false,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isHero ? kDeepNavy : Colors.white;
    final textColor = isHero ? Colors.white : const Color(0xFF0F172A);
    final trendColor = isHero ? Colors.white70 : (isPositive ? kAccentGreen : (isNeutral ? const Color(0xFF64748B) : Colors.redAccent));

    return Container(
      padding: EdgeInsets.all(isHero ? 24 : 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: isHero ? null : Border.all(color: kSlateBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: (isHero ? kDeepNavy : const Color(0xFF0F172A)).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHero ? Colors.white.withValues(alpha: 0.1) : kPrimaryGreen.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isHero ? Colors.white : kPrimaryGreen, size: 20),
              ),
              if (isHero)
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              color: isHero ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: isHero ? 32 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: GoogleFonts.outfit(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}




