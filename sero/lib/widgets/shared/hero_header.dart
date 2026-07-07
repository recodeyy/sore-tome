import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';

class HeroHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onRefresh;
  final String? label;

  const HeroHeader({
    super.key,
    this.title = 'Overview',
    this.subtitle,
    this.description,
    this.onRefresh,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (label ?? 'CONSOLE').toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                if (onRefresh != null)
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 14, color: kPrimaryGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (subtitle != null) 
              Text(
                subtitle!,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ).animate().fade(delay: 50.ms).slideY(begin: 0.05),
    );
  }
}



