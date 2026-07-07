import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminMoreScreen extends ConsumerWidget {
  const SuperAdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(superAdminMoreModulesProvider);
    final user = ref.watch(authProvider).value;
    final grouped = <String, List<SuperAdminModuleLink>>{};
    for (final module in modules) {
      grouped.putIfAbsent(module.group, () => []).add(module);
    }

    return Scaffold(
      backgroundColor: kSlateBg,
      drawer: const SuperAdminDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Builder(
            builder: (context) => SuperAdminHeader(
              title: 'More',
              subtitle: 'All platform modules',
              onMenu: () => Scaffold.of(context).openDrawer(),
              onNotifications: () =>
                  Navigator.pushNamed(context, '/notifications'),
              onSettings: () =>
                  Navigator.pushNamed(context, '/super-admin/settings'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _AccountHeader(name: user?.name ?? 'Super Admin'),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          for (final entry in grouped.entries) ...[
            SuperAdminSectionHeader(title: entry.key),
            ...entry.value.map(
              (module) => SuperAdminModuleTile(module: module),
            ),
            const SizedBox(height: 14),
          ],
          const SuperAdminSectionHeader(title: 'Account'),
          SuperAdminModuleTile(
            module: const SuperAdminModuleLink(
              title: 'Profile',
              subtitle: 'View your platform operator profile',
              route: '/profile',
              group: 'Account',
              iconKey: 'users',
            ),
          ),
          SuperAdminModuleTile(
            module: const SuperAdminModuleLink(
              title: 'Logout',
              subtitle: 'Sign out of the Super Admin control center',
              route: 'logout',
              group: 'Account',
              iconKey: 'settings',
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
              ],
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
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
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;

  const _AccountHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: kEmeraldSkyGradient,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'SERO Platform Control Center',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
