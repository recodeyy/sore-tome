import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PendingApprovalsHero extends StatelessWidget {
  final String count;
  final List<Widget> children;
  final VoidCallback onTap;

  const PendingApprovalsHero({
    super.key,
    required this.count,
    required this.children,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                count,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF991B1B),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "PENDING APPROVALS",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF991B1B).withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.1);
  }
}






