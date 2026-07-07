import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

import '../complaints/complaints_dashboard_screen.dart';
import '../main/admin_access_logs_screen.dart';

/// Admin "Operations" tab (§6/§9): a lightweight hub for day-to-day society
/// operations — complaints, visitor/security overview, staff and parking —
/// mirroring the resident More-grid pattern so admin mobile stays uncluttered.
class AdminOperationsHubScreen extends StatelessWidget {
  const AdminOperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_OpsItem>[
      _OpsItem(
        icon: Icons.report_problem_rounded,
        label: 'Complaints',
        subtitle: 'Route & resolve',
        onTap: (ctx) => _push(ctx, const ComplaintsDashboardScreen()),
      ),
      _OpsItem(
        icon: Icons.shield_rounded,
        label: 'Visitors & Security',
        subtitle: 'Gate activity logs',
        onTap: (ctx) => _push(ctx, const AdminAccessLogsScreen()),
      ),
      _OpsItem(
        icon: Icons.badge_rounded,
        label: 'Staff',
        subtitle: 'Attendance & roster',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/staff'),
      ),
      _OpsItem(
        icon: Icons.local_parking_rounded,
        label: 'Parking',
        subtitle: 'Slots & vehicles',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/parking'),
      ),
      _OpsItem(
        icon: Icons.campaign_rounded,
        label: 'Notices',
        subtitle: 'Announce & inform',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/notices'),
      ),
      _OpsItem(
        icon: Icons.pool_rounded,
        label: 'Amenities',
        subtitle: 'Facility bookings',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/amenities'),
      ),
      _OpsItem(
        icon: Icons.inventory_2_rounded,
        label: 'Assets',
        subtitle: 'Lifts, pumps & more',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/assets'),
      ),
      _OpsItem(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        subtitle: 'Download & share',
        onTap: (ctx) => Navigator.pushNamed(ctx, '/admin/reports'),
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
                      'Operations',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day-to-day society operations, one tap away',
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _OpsTile(item: items[index]),
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

class _OpsItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final void Function(BuildContext) onTap;

  const _OpsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _OpsTile extends StatelessWidget {
  final _OpsItem item;

  const _OpsTile({required this.item});

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
