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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryGreen, kDeepNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const SocietyLogo(size: 72)
                    .animate()
                    .fade(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 16),
                Text(
                  'SERO',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 8,
                  ),
                ).animate().fade(delay: 200.ms),
                Text(
                  'Choose how you use SERO',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
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
                    color: Colors.white54,
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
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(isSuper ? 40 : 20),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSuper ? kPrimaryBlue.withAlpha(60) : kAccentGreen.withAlpha(40),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: isSuper ? Colors.lightBlueAccent : kAccentGreen,
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: 0.05);
  }
}
