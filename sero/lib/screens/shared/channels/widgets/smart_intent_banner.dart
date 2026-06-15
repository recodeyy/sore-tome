import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartIntentBanner extends StatelessWidget {
  final VoidCallback onCreateTicket;

  const SmartIntentBanner({super.key, required this.onCreateTicket});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Sero detected a maintenance intent. Log this issue officially?",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: onCreateTicket,
              child: Text("CREATE TICKET", style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0.0);
  }
}






