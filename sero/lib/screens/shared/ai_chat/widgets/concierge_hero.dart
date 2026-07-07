import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConciergeHero extends StatelessWidget {
  final String userRole;
  const ConciergeHero({super.key, this.userRole = 'resident'});

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Text(
              isAdmin ? 'COMMAND AI' : 'SERO AI',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: isAdmin ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAdmin 
                ? 'Society Operational Intelligence. Analyzing governance,\nfinancial health, and community records in real-time.'
                : 'Your premium architectural assistant for seamless\nestate administration and resident harmony.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ).animate().fade().slideY(begin: 0.1),
    );
  }
}






