import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/app/theme.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.1), width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 60,
                  color: kPrimaryGreen,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Approval Pending',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been created successfully,\nbut it requires admin approval before you\ncan access the full dashboard.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    elevation: 0,
                  ),
                  child: const Text('Logout and Wait'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Once approved, you will be able to log in.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}











