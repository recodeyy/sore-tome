import 'package:flutter/material.dart';

/// Global error handling.
///
/// IMPORTANT — why this no longer takes over the whole screen:
/// The previous version set `FlutterError.onError` to `setState` a full-screen
/// "Something Went Wrong" page. But `FlutterError.onError` fires for EVERY
/// framework error — including non-fatal ones (a layout overflow, a failed
/// network image, a single provider/StreamBuilder throwing, e.g. the old
/// Firestore "permission denied"). The result: one minor error anywhere blew
/// the entire app away with a scary error page "on every screen".
///
/// New behaviour:
///  - `FlutterError.onError` only LOGS/REPORTS the error; the app keeps running.
///  - `ErrorWidget.builder` replaces ONLY the offending widget subtree with a
///    small, quiet placeholder (nothing in release) so a single bad widget
///    degrades gracefully instead of crashing the whole UI.
class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;
  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  @override
  void initState() {
    super.initState();

    // Log framework errors (and forward to the console / crash reporter) but
    // DO NOT tear down the app. Keep the user where they are.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Caught framework error (non-fatal): ${details.exception}');
    };

    // Replace only the failing widget with a small, recoverable card — NEVER a
    // blank screen. Showing nothing (SizedBox.shrink) hid real crashes as an
    // empty page; a compact message keeps the app usable and tells us what
    // failed. The surrounding app (nav, other tabs) keeps working.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 40),
                const SizedBox(height: 12),
                const Text(
                  "This section couldn't load",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${details.exception}',
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
