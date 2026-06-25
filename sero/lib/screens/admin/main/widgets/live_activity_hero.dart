import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveActivityHero extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback onManageAccess;
  final VoidCallback onAccessLogs;

  const LiveActivityHero({
    super.key,
    required this.count,
    required this.label,
    required this.onManageAccess,
    required this.onAccessLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "LIVE ACTIVITY",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontSize: 84,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onManageAccess,
                    icon: const Icon(Icons.remove_red_eye, size: 18),
                    label: const Text("Manage Access"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF345D7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccessLogs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEAFE),
                      foregroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Access Logs"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fade(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}






