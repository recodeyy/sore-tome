import 'package:flutter/foundation.dart';
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

    // Replace only the failing widget. In release, show nothing (an empty box)
    // so users never see a red/grey crash panel; in debug, show a compact note.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kReleaseMode) return const SizedBox.shrink();
      return Material(
        color: const Color(0xFFFFF1F2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Widget error: ${details.exception}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
