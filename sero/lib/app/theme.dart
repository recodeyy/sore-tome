import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Premium Green & Blue Palette
const kPrimaryGreen = Color(0xFF064E3B); // Deep Emerald
const kPrimaryBlue = Color(0xFF1E3A8A);  // Deep Navy Blue
const kAccentGreen = Color(0xFF10B981);  // Emerald 500
const kAccentBlue = Color(0xFF0EA5E9);   // Sky 500
const kSlateBg = Color(0xFFF8FAFC);      // Soft Slate background
const kSlateBorder = Color(0xFFE2E8F0);  // Slate border

// Premium Gradient for AppBars and Headers
const kPremiumGradient = LinearGradient(
  colors: [kPrimaryGreen, Color(0xFF111827)], // Deep Emerald to near-black navy
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kEmeraldSkyGradient = LinearGradient(
  colors: [kPrimaryGreen, kPrimaryBlue], // Deep Emerald to Deep Navy Blue
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kGlassGradient = LinearGradient(
  colors: [Colors.white12, Colors.white10],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Existing functional colors (kept for compatibility)
const kLightGreen = Color(0xFFEAF3DE);
const kTextGreen = Color(0xFF3B6D11);
const kDarkGreen = Color(0xFF0F6E56);
const kDeepNavy = Color(0xFF0F172A); 

// Badge palette
const kBadgeGreenBg = Color(0xFFD4F0E2);
const kBadgeGreenText = Color(0xFF0F6E56);
const kBadgeAmberBg = Color(0xFFFAEEDA);
const kBadgeAmberText = Color(0xFF854F0B);
const kBadgeRedBg = Color(0xFFFCEBEB);
const kBadgeRedText = Color(0xFFA32D2D);
const kBadgeBlueBg = Color(0xFFE6F1FB);
const kBadgeBlueText = Color(0xFF185FA5);

ThemeData appTheme() {
  final base = ThemeData.light();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryGreen,
      primary: kPrimaryGreen,
      secondary: kPrimaryBlue,
      tertiary: kAccentGreen,
      surface: Colors.white,
      surfaceContainer: kSlateBg,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: kSlateBg,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Handled by gradient in screens
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: kSlateBorder.withValues(alpha: 0.4), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: const Color(0xFF94A3B8),
      selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kSlateBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kSlateBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
    ),
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
      bodyLarge: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF1E293B), fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF334155), height: 1.5),
      bodySmall: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
      titleLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: kPrimaryGreen, letterSpacing: -0.8),
      titleMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// Custom FAB location to stay above the floating pill navbar (~80px offset)
class PillNavbarFabLocation extends FloatingActionButtonLocation {
  const PillNavbarFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Standard endFloat offset
    final double x = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dx;
    final double y = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry).dy - 80.0;
    return Offset(x, y);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.pillNavbarFab';
}

const kPillNavbarFabLocation = PillNavbarFabLocation();



