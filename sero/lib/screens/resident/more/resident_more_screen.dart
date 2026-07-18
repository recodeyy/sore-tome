import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

import '../amenities/amenities_home_screen.dart';
import '../parking/my_parking_screen.dart';
import '../parcels/parcels_screen.dart';
import '../domestic/domestic_help_screen.dart';
import '../documents/documents_screen.dart';
import '../rules/resident_rules_screen.dart';
import '../issues/resident_issues_screen.dart';
import '../payments/receipts_screen.dart';
import '../profile/resident_profile_screen.dart';

/// Resident "More" tab (MR-012): a hub linking to every secondary feature
/// that moved out of the bottom navigation (Amenities, Parking, Documents,
/// Rules, Family, Vehicles, Complaints, Profile, Settings).
class ResidentMoreScreen extends StatelessWidget {
  const ResidentMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.pool_rounded,
        label: 'Amenities',
        subtitle: 'Book facilities',
        onTap: (ctx) => _push(ctx, const AmenitiesHomeScreen()),
      ),
      _MoreItem(
        icon: Icons.local_parking_rounded,
        label: 'Parking',
        subtitle: 'My slots',
        onTap: (ctx) => _push(ctx, const MyParkingScreen()),
      ),
      _MoreItem(
        icon: Icons.inventory_2_rounded,
        label: 'Parcels',
        subtitle: 'Gate deliveries',
        onTap: (ctx) => _push(ctx, const ParcelsScreen()),
      ),
      _MoreItem(
        icon: Icons.cleaning_services_rounded,
        label: 'Domestic Help',
        subtitle: 'Maid, cook, driver',
        onTap: (ctx) => _push(ctx, const DomesticHelpScreen()),
      ),
      _MoreItem(
        icon: Icons.receipt_long_rounded,
        label: 'Receipts',
        subtitle: 'Payment receipts',
        onTap: (ctx) => _push(ctx, const ReceiptsScreen()),
      ),
      _MoreItem(
        icon: Icons.description_rounded,
        label: 'Documents',
        subtitle: 'Society papers',
        onTap: (ctx) => _push(ctx, const DocumentsScreen()),
      ),
      _MoreItem(
        icon: Icons.gavel_rounded,
        label: 'Rules',
        subtitle: 'Bye-laws & rules',
        onTap: (ctx) => _push(ctx, const ResidentRulesScreen()),
      ),
      _MoreItem(
        icon: Icons.group_rounded,
        label: 'Family',
        subtitle: 'Family members',
        onTap: (ctx) => _push(ctx, const ResidentProfileScreen()),
      ),
      _MoreItem(
        icon: Icons.directions_car_rounded,
        label: 'Vehicles',
        subtitle: 'My vehicles',
        onTap: (ctx) => _push(ctx, const ResidentProfileScreen()),
      ),
      _MoreItem(
        icon: Icons.report_problem_rounded,
        label: 'Complaints',
        subtitle: 'Raise & track',
        onTap: (ctx) => _push(ctx, const ResidentIssuesScreen()),
      ),
      _MoreItem(
        icon: Icons.person_rounded,
        label: 'Profile',
        subtitle: 'Your account',
        onTap: (ctx) => _push(ctx, const ResidentProfileScreen()),
      ),
      _MoreItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        subtitle: 'App preferences',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/settings'),
      ),
    ];

    return Scaffold(
      backgroundColor: kSlateBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'More',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Everything else in your society, one tap away',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MoreTile(item: items[index]),
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final void Function(BuildContext) onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;

  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => item.onTap(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kSlateBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kLightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: kPrimaryGreen, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
