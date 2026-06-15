import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class RegistrationPendingScreen extends ConsumerWidget {
  const RegistrationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- TOP ICON SECTION ---
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.supervised_user_circle_rounded,
                color: kPrimaryGreen,
                size: 64,
              ),
            ).animate(onPlay: (c) => c.repeat())
             .shimmer(duration: 2.seconds, color: kPrimaryGreen.withValues(alpha: 0.2))
             .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds, curve: Curves.easeInOut),

            const SizedBox(height: 48),

            // --- STATUS TEXT ---
            Text(
              "Verification in Progress",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ).animate().fade().slideY(begin: 0.2),

            const SizedBox(height: 16),

            Text(
              "Your profile is being reviewed by the society secretary. We'll unlock your dashboard once approved.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 64),

            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Direct call logic or prompt
                },
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                label: Text(
                  "CALL SOCIETY OFFICE",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ).animate().fade(delay: 400.ms).scaleY(begin: 0.8),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: Text(
                "Cancel & Logout",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fade(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
