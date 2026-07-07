import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Shared loading / empty / error presenters for live-data screens (spec 15 & 16).
/// Never render fake data — these are the truthful fallbacks.
///
/// UI QA pass (§16): these now delegate to the canonical SERO UI kit
/// (SkeletonCard / ErrorRetryView / EmptyState styling) so every consumer
/// screen gets modern skeleton loading and recoverable error states for free.

class LiveLoadingView extends StatelessWidget {
  final String? label;
  const LiveLoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SkeletonCard(height: 88),
          SkeletonCard(height: 88),
          SkeletonCard(height: 88),
          SkeletonCard(height: 88, margin: EdgeInsets.zero),
        ],
      ),
    );
  }
}

class LiveErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const LiveErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorRetryView(
      message: error.toString().replaceFirst('Exception: ', ''),
      onRetry: onRetry,
    );
  }
}

class LiveEmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const LiveEmptyView({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: kLightMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: kAccentGreen, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
