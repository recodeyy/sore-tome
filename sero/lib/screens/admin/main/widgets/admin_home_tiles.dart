import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PendingItemTile extends StatelessWidget {
  final String name;
  final String priority;
  final Color color;

  const PendingItemTile({
    super.key,
    required this.name,
    required this.priority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              priority,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentUpdateTile extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final String time;
  final Color badgeColor;
  final Color textColor;

  const RecentUpdateTile({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}






