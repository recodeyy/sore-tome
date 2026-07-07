import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final List<SummarySubStat> subStats;
  final IconData icon;
  final Color bgColor;

  const MainSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subStats,
    required this.icon,
    this.bgColor = const Color(0xFF064E3B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              color: Colors.white24,
              width: 32,
              thickness: 1,
              indent: 4,
              endIndent: 4,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: subStats
                  .map((s) => Padding(
                        padding: EdgeInsets.only(
                          bottom: s == subStats.last ? 0 : 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.label,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: Text(
                                s.value,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SummarySubStat {
  final String label;
  final String value;

  const SummarySubStat(this.label, this.value);
}
