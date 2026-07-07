import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/screens/resident/profile/resident_profile_screen.dart';
import 'package:sero/screens/resident/visitors/visitor_approval_screen.dart';
import 'package:sero/screens/resident/issues/resident_issues_screen.dart';
import 'package:sero/screens/resident/emergency/emergency_home_screen.dart';

/// Side drawer menu (design: complain.png screen 1).
///
/// Routes each entry to a real wired destination where one exists (Profile,
/// Visitor Approvals, My Complaints, Emergency SOS / Contacts, Logout).
/// Entries with no backend yet (Family / Vehicles / KYC / Domestic Help /
/// Documents / Settings / Help) open the relevant honest placeholder
/// (the profile screen already shows truthful empty states for family/vehicle/KYC).
class ResidentDrawer extends ConsumerWidget {
  const ResidentDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: kPremiumGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 34)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Resident',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(
                    'Flat ${user?.flatNumber ?? "—"}'
                    '${user?.block.isNotEmpty == true ? " • Block ${user!.block}" : ""}',
                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _section('Account'),
                  _item(context, Icons.person_outline, 'Profile',
                      () => const ResidentProfileScreen()),
                  _item(context, Icons.group_outlined, 'Family Members',
                      () => const ResidentProfileScreen()),
                  _item(context, Icons.directions_car_outlined, 'My Vehicles',
                      () => const ResidentProfileScreen()),
                  _item(context, Icons.badge_outlined, 'KYC Documents',
                      () => const ResidentProfileScreen()),
                  _section('Community'),
                  _item(context, Icons.people_alt_outlined, 'Visitor Approvals',
                      () => const VisitorApprovalScreen()),
                  _item(context, Icons.report_problem_outlined, 'My Complaints',
                      () => const ResidentIssuesScreen()),
                  _section('Safety & Documents'),
                  _item(context, Icons.emergency_outlined, 'Emergency SOS',
                      () => const EmergencyHomeScreen()),
                  _item(context, Icons.contact_phone_outlined, 'Emergency Contacts',
                      () => const EmergencyHomeScreen()),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded, color: kPrimaryGreen),
                    title: Text('Switch Portal',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy)),
                    subtitle: Text('Admin / Staff / Resident',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: kBadgeRedText),
                    title: Text('Logout',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kBadgeRedText)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(t.toUpperCase(),
            style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
      );

  Widget _item(BuildContext context, IconData icon, String label, Widget Function() builder) => ListTile(
        leading: Icon(icon, color: kPrimaryGreen, size: 22),
        title: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: kDeepNavy, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
        },
      );
}
