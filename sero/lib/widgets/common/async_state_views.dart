import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared loading / empty / error presenters for live-data screens (spec 15 & 16).
/// Never render fake data — these are the truthful fallbacks.

class LiveLoadingView extends StatelessWidget {
  final String? label;
  const LiveLoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!, style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            ],
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load live data.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
