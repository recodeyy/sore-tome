import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

/// Shared admin UI action helpers.
///
/// Used to give every interactive element on the admin screens a real
/// behaviour. Where a backend / dedicated screen does not yet exist, we
/// surface a clear "coming soon" SnackBar instead of doing nothing.
class AdminActions {
  AdminActions._();

  /// Shows a consistent "coming soon" SnackBar for features that are not
  /// yet backed by a screen or service.
  static void comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimaryGreen,
          content: Text(
            '$feature coming soon',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
  }
}
