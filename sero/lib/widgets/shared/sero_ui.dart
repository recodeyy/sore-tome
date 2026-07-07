import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

/// SERO shared UI kit — canonical status chips, empty states, error views and
/// loading skeletons styled with the unified palette (MR-010).
///
/// Usage:
///   StatusChip(label: 'Paid', semantic: ChipSemantic.success)
///   EmptyState(icon: Icons.people_outline, title: 'No visitors yet', ...)
///   ErrorRetryView(message: 'Could not load bills', onRetry: _load)
///   SkeletonList(itemCount: 4)

// ─── StatusChip ───────────────────────────────────────────────────────────────

enum ChipSemantic { success, warning, error, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipSemantic semantic;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.semantic = ChipSemantic.neutral,
    this.icon,
  });

  static (Color bg, Color fg) _colorsFor(ChipSemantic s) {
    switch (s) {
      case ChipSemantic.success:
        return (kLightMint, kPrimaryGreen);
      case ChipSemantic.warning:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case ChipSemantic.error:
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
      case ChipSemantic.info:
        return (const Color(0xFFE0F2FE), const Color(0xFF0369A1));
      case ChipSemantic.neutral:
        return (const Color(0xFFF1F5F9), kTextSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(semantic);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ErrorRetryView ───────────────────────────────────────────────────────────

class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// Optional backend request id shown small for support escalation.
  final String? requestId;

  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: kError, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
            ),
            if (requestId != null && requestId!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Ref: $requestId',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: kTextSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryGreen,
                side: const BorderSide(color: kPrimaryGreen, width: 1.4),
                minimumSize: const Size(140, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

/// A single softly pulsing placeholder card (shimmer-free).
class SkeletonCard extends StatefulWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const SkeletonCard({
    super.key,
    this.height = 88,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        height: widget.height,
        margin: widget.margin,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kSlateBg,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSlateBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.55,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: kSlateBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A vertical list of [SkeletonCard]s for list-loading states.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 88,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => SkeletonCard(height: itemHeight),
    );
  }
}
