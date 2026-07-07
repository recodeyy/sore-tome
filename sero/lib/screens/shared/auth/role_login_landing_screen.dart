import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/shared/brand_logo.dart';

class RoleLoginLandingScreen extends StatelessWidget {
  const RoleLoginLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: kMintBg,
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGreenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kMintTint,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const SocietyLogo(size: 56, color: kFreshGreen),
                )
                    .animate()
                    .fade(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 16),
                Text(
                  'SERO',
                  style: GoogleFonts.outfit(
                    color: kInkGreen,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                ).animate().fade(delay: 200.ms),
                Text(
                  'Choose how you use SERO',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4B6358),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fade(delay: 300.ms),
                const SizedBox(height: 32),
                Expanded(
                  child: isTablet
                      ? GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: _buildCards(context),
                        )
                      : ListView(
                          children: _buildCards(context),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need help signing in? Contact support',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7B9488),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    return [
      _PortalCard(
        title: 'Member / Resident',
        subtitle: 'Pay bills, approve visitors, book amenities, and raise complaints.',
        icon: Icons.home_rounded,
        onTap: () => Navigator.pushNamed(context, '/login/resident'),
      ),
      _PortalCard(
        title: 'Society Admin',
        subtitle: 'Manage society members, committee operations, billing, and staff.',
        icon: Icons.business_rounded,
        onTap: () => Navigator.pushNamed(context, '/login/admin'),
      ),
      _PortalCard(
        title: 'Staff & Security',
        subtitle: 'Log visitor entry/exit, record parcel handovers, and trigger SOS.',
        icon: Icons.shield_rounded,
        onTap: () => Navigator.pushNamed(context, '/login/staff'),
      ),
      _PortalCard(
        title: 'Super Admin',
        subtitle: 'Manage societies, control platform settings, and view logs.',
        icon: Icons.admin_panel_settings_rounded,
        onTap: () => Navigator.pushNamed(context, '/login/super-admin'),
        isSuper: true,
      ),
    ];
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSuper;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSuper = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSuper ? kPrimaryBlue.withAlpha(40) : kMintBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kFreshGreen.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSuper ? kPrimaryBlue.withAlpha(22) : kMintTint,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: isSuper ? kPrimaryBlue : kFreshGreenDark,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: kInkGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5B7468),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSuper ? kPrimaryBlue : kFreshGreen,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: 0.05);
  }
}
