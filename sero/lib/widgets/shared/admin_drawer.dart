import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/navigation_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final String adminName = user?.name ?? 'Admin';
    final String adminRole = user?.role == 'main_admin' ? 'Main Admin' : 'Admin';
    final String societyName = 'Green Residency';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Drawer Header
          _buildHeader(adminName, adminRole, societyName),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(context, ref, 'Dashboard', Icons.dashboard_outlined, '/admin/dashboard', tabIndex: 0),
                _buildDrawerItem(context, ref, 'Members', Icons.people_outline, '', tabIndex: 1),
                _buildDrawerItem(context, ref, 'Billing', Icons.account_balance_wallet_outlined, '/admin/finance', tabIndex: 2),
                _buildDrawerItem(context, ref, 'Operations', Icons.widgets_outlined, '', tabIndex: 3),
                _buildDrawerItem(context, ref, 'Complaint Management', Icons.report_problem_outlined, '/admin/complaints'),
                _buildDrawerItem(context, ref, 'More Modules', Icons.more_horiz, '', tabIndex: 4),
                const Divider(height: 24, indent: 20, endIndent: 20),
                _buildDrawerItem(context, ref, 'Society Setup', Icons.business_outlined, '/admin/society-setup'),
                _buildDrawerItem(context, ref, 'Communication', Icons.forum_outlined, '/admin/notices'),
                _buildDrawerItem(context, ref, 'Staff Management', Icons.groups_outlined, '/admin/staff'),
                _buildDrawerItem(context, ref, 'Amenities', Icons.pool_outlined, '/admin/amenities'),
                _buildDrawerItem(context, ref, 'Parking', Icons.local_parking_outlined, '/admin/parking'),
                _buildDrawerItem(context, ref, 'Asset Management', Icons.inventory_2_outlined, '/admin/assets'),
                _buildDrawerItem(context, ref, 'Reports', Icons.bar_chart_outlined, '/admin/reports'),
                const Divider(height: 32, indent: 20, endIndent: 20),
                _buildDrawerItem(context, ref, 'Profile', Icons.person_outline, '/profile'),
                _buildDrawerItem(context, ref, 'Settings', Icons.settings_outlined, '/settings'),
                const SizedBox(height: 8),
                _buildLogoutItem(context, ref),
              ],
            ),
          ),
          
          // App Version
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'v1.0.0 (BETA)',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String role, String society) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: kPremiumGradient,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    society,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, WidgetRef ref, String title, IconData icon, String route, {int? tabIndex}) {
    final currentIndex = ref.watch(adminNavigationProvider);
    bool isSelected;
    
    if (tabIndex != null) {
      isSelected = currentIndex == tabIndex;
    } else {
      isSelected = ModalRoute.of(context)?.settings.name == route;
    }

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? kPrimaryGreen : const Color(0xFF64748B),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? kPrimaryGreen : const Color(0xFF1E293B),
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (tabIndex != null) {
          ref.read(adminNavigationProvider.notifier).state = tabIndex;
        } else if (!isSelected) {
          Navigator.pushNamed(context, route);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(
        Icons.logout_rounded,
        color: Color(0xFFEF4444),
        size: 22,
      ),
      title: Text(
        'Logout',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFEF4444),
        ),
      ),
      onTap: () => _showLogoutDialog(context, ref),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
