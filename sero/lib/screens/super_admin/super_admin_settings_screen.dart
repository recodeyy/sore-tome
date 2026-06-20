import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

/// Settings Hub (reference screen 12). A categorized list of platform
/// control-plane settings with colourful icon tiles that route to the
/// dedicated administration screens.
class SuperAdminSettingsScreen extends ConsumerWidget {
  const SuperAdminSettingsScreen({super.key});

  static const _items = <_SettingItem>[
    _SettingItem(
      title: 'White-label Settings',
      subtitle: 'Branding, themes, and custom domains',
      icon: Icons.palette_outlined,
      color: Color(0xFF6366F1),
      route: '/super-admin/settings/branding',
    ),
    _SettingItem(
      title: 'Support Tickets',
      subtitle: 'Queue, assignment, SLA, escalations',
      icon: Icons.support_agent_outlined,
      color: Color(0xFF0EA5E9),
      route: '/super-admin/support',
    ),
    _SettingItem(
      title: 'Audit Logs',
      subtitle: 'Immutable platform actions and access logs',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFF59E0B),
      route: '/super-admin/audit',
    ),
    _SettingItem(
      title: 'Security Settings',
      subtitle: 'Sessions, MFA policies, IP allowlists',
      icon: Icons.shield_outlined,
      color: Color(0xFFEF4444),
      route: '/super-admin/system-health',
    ),
    _SettingItem(
      title: 'API & Access Control',
      subtitle: 'Clients, keys, webhooks, delivery logs',
      icon: Icons.api_outlined,
      color: Color(0xFF10B981),
      route: '/super-admin/api-access',
    ),
    _SettingItem(
      title: 'Impersonation Log',
      subtitle: 'Audited support access with expiry',
      icon: Icons.switch_account_outlined,
      color: Color(0xFF8B5CF6),
      route: '/super-admin/impersonation',
    ),
    _SettingItem(
      title: 'Feature Controls',
      subtitle: 'Registry, rollouts, overrides, kill switches',
      icon: Icons.toggle_on_outlined,
      color: Color(0xFF14B8A6),
      route: '/super-admin/features',
    ),
    _SettingItem(
      title: 'General Settings',
      subtitle: 'Control-plane preferences and policies',
      icon: Icons.settings_outlined,
      color: Color(0xFF64748B),
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Settings Hub',
            subtitle: 'Platform configuration & administration',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                for (final item in _items) ...[
                  _SettingTile(item: item),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _SettingTile extends StatelessWidget {
  final _SettingItem item;

  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, item.route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kSlateBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
