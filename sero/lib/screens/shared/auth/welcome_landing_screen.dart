import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/shared/brand_logo.dart';

/// First screen an unauthenticated user sees after the splash.
///
/// A light, white-green onboarding page that introduces the app with
/// real product imagery and the headline features, then sends the user
/// into the role-based login flow.
class WelcomeLandingScreen extends StatelessWidget {
  const WelcomeLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kMintBg,
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGreenGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kMintTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const SocietyLogo(size: 30, color: kFreshGreen),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SERO',
                      style: GoogleFonts.outfit(
                        color: kInkGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.outfit(
                          color: kFreshGreenDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms),

                const SizedBox(height: 20),

                // Hero image
                _HeroImage(height: size.height * 0.34)
                    .animate()
                    .fade(duration: 500.ms)
                    .scale(begin: const Offset(0.96, 0.96)),

                const SizedBox(height: 28),

                // Headline
                Text(
                  'Your society,\nbeautifully managed.',
                  style: GoogleFonts.outfit(
                    color: kInkGreen,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ).animate().fade(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 10),

                Text(
                  'Visitors, payments, complaints, amenities and security — '
                  'everything for residents, staff and committee in one place.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4B6358),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ).animate().fade(delay: 250.ms),

                const SizedBox(height: 24),

                // Feature chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _FeatureChip(icon: Icons.qr_code_scanner_rounded, label: 'Visitor Gate Pass'),
                    _FeatureChip(icon: Icons.payments_rounded, label: 'Online Payments'),
                    _FeatureChip(icon: Icons.handyman_rounded, label: 'Complaints'),
                    _FeatureChip(icon: Icons.pool_rounded, label: 'Amenity Booking'),
                    _FeatureChip(icon: Icons.local_parking_rounded, label: 'Parking'),
                    _FeatureChip(icon: Icons.shield_rounded, label: 'Security SOS'),
                  ],
                ).animate().fade(delay: 350.ms),

                const SizedBox(height: 28),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kFreshGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Trusted by residents, committees & security teams',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7B9488),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final double height;
  const _HeroImage({required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/society_building.png',
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              color: kMintTint,
              child: const Icon(Icons.apartment_rounded,
                  size: 80, color: kFreshGreen),
            ),
          ),
          // Subtle green wash + amenity thumbnail to feel like a real product
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: kFreshGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Smart living, simplified',
                    style: GoogleFonts.outfit(
                      color: kInkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kMintTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kMintBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kFreshGreenDark, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: kInkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
