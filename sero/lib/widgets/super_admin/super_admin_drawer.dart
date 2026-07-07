import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/navigation_provider.dart';

class SuperAdminDrawer extends ConsumerWidget {
  const SuperAdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
            decoration: const BoxDecoration(gradient: kPremiumGradient),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Super Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'SUPER ADMIN',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'SERO PLATFORM CONTROL',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _group('Platform'),
                _item(context, ref, 'Overview', Icons.dashboard_outlined, 0),
                _item(context, ref, 'Societies', Icons.business_outlined, 1),
                _item(context, ref, 'Users', Icons.people_outline, 4),
                _item(context, ref, 'Society Approvals',
                    Icons.fact_check_outlined, 4),
                _item(context, ref, 'KYC Verification',
                    Icons.verified_user_outlined, 4),
                _group('Revenue'),
                _item(context, ref, 'Revenue Dashboard',
                    Icons.account_balance_wallet_outlined, 2),
                _item(
                    context, ref, 'Subscriptions', Icons.autorenew_outlined, 2),
                _item(context, ref, 'Plans and Pricing',
                    Icons.local_offer_outlined, 2),
                _group('Operations'),
                _item(context, ref, 'Support Tickets',
                    Icons.support_agent_outlined, 3),
                _item(context, ref, 'Global Announcements',
                    Icons.campaign_outlined, 4),
                _item(context, ref, 'Feature Controls', Icons.tune_outlined, 4),
                _group('Security'),
                _item(context, ref, 'Audit Logs', Icons.policy_outlined, 4),
                _item(context, ref, 'Impersonation',
                    Icons.switch_account_outlined, 4),
                _item(context, ref, 'System Health',
                    Icons.monitor_heart_outlined, 4),
                const Divider(height: 24, indent: 20, endIndent: 20),
                _logout(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: const Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    int tabIndex,
  ) {
    final selected = ref.watch(superAdminNavigationProvider) == tabIndex;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading:
          Icon(icon, color: selected ? kPrimaryGreen : const Color(0xFF64748B)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: selected ? kPrimaryGreen : const Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      onTap: () {
        ref.read(superAdminNavigationProvider.notifier).state = tabIndex;
        Navigator.pop(context);
      },
    );
  }

  Widget _logout(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
      title: Text(
        'Logout',
        style: GoogleFonts.outfit(
          color: const Color(0xFFEF4444),
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () {
        ref.read(authProvider.notifier).logout();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }
}
