import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';






class GovernanceSearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  const GovernanceSearchBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: false,
                onChanged: (v) => (context as Element).markNeedsBuild(), // Force list filter on type
                decoration: InputDecoration(
                  hintText: 'Lookup clauses or protocols...',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.01, curve: Curves.easeOutQuad);
  }
}







