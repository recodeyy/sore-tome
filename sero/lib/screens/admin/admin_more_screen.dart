import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/common/info_list_tile.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kPremiumGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          'More Modules',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Management'),
            _buildModuleItem(
              context,
              ref,
              Icons.apartment,
              'Society Setup',
              'Configure wings, blocks, and units',
              '/admin/society-setup',
              const Color(0xFF0369A1),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.campaign_outlined,
              'Communication',
              'Post notices and send messages',
              '/admin/notices',
              const Color(0xFF7C3AED),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.people_outline,
              'Staff Management',
              'Manage society staff and attendance',
              '/admin/staff',
              const Color(0xFF059669),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.pool_outlined,
              'Amenities',
              'Manage club house, gym, and bookings',
              '/admin/amenities',
              const Color(0xFFEA580C),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Facility'),
            _buildModuleItem(
              context,
              ref,
              Icons.local_parking_rounded,
              'Parking',
              'Manage slot allocation and vehicles',
              '/admin/parking',
              const Color(0xFF0EA5E9),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.inventory_2_outlined,
              'Asset Management',
              'Track maintenance of lifts, pumps, etc.',
              '/admin/assets',
              const Color(0xFF2563EB),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('AI Intelligence'),
            _buildModuleItem(
              context,
              ref,
              Icons.monitor_heart_outlined,
              'Society Pulse',
              'AI health metrics, alerts and autopilot',
              '/ai/pulse',
              const Color(0xFF064E3B),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.hub_outlined,
              'Complaint Intelligence',
              'AI root-cause & cluster detection',
              '/ai/complaint-intelligence',
              const Color(0xFF0369A1),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.build_circle_outlined,
              'Predictive Maintenance',
              'AI failure-risk scoring for assets',
              '/ai/maintenance',
              const Color(0xFF7C3AED),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.warning_amber_rounded,
              'Financial Anomaly Radar',
              'AI duplicate & leakage detection',
              '/ai/financial-anomaly',
              const Color(0xFF92400E),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Reporting'),
            _buildModuleItem(
              context,
              ref,
              Icons.bar_chart_outlined,
              'Reports',
              'Download financial and audit reports',
              '/admin/reports',
              const Color(0xFFDC2626),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            _buildModuleItem(
              context,
              ref,
              Icons.person_outline,
              'Profile',
              'View and edit your personal details',
              '/profile',
              const Color(0xFF064E3B),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.settings_outlined,
              'Settings',
              'App preferences and profile settings',
              '/settings',
              const Color(0xFF64748B),
            ),
            _buildModuleItem(
              context,
              ref,
              Icons.logout_rounded,
              'Logout',
              'Sign out from your account',
              'logout',
              const Color(0xFF1E293B),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModuleItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InfoListTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        iconColor: color,
        iconBgColor: color.withOpacity(0.1),
        onTap: () {
          if (route == 'logout') {
            _showLogoutDialog(context, ref);
          } else if (route.isNotEmpty) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Logout', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
