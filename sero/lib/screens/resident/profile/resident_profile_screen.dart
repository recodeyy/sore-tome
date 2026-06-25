import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/resident/resident_profile_provider.dart';

/// Resident Profile Overview (design: profile.png screen 1).
///
/// LIVE DATA:
///  - Identity / unit / role -> authProvider (current UserModel from backend session)
///  - Family Members -> residentFamilyProvider (GET /resident/family)
///  - Vehicles -> residentVehiclesProvider (GET /resident/vehicles)
///  - KYC Documents -> residentKycProvider (GET /resident/kyc)
///
/// Each section shows truthful loading / empty / error states; rows are never
/// fabricated — an empty list means none are configured for this resident.
class ResidentProfileScreen extends ConsumerWidget {
  const ResidentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 140),
        children: [
          // ── Header card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: kPremiumGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage:
                      (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Resident',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (user?.residentType ?? 'owner').toUpperCase(),
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Account details (LIVE) ──
          _label('Account Details'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSlateBorder),
            ),
            child: Column(
              children: [
                _detailRow(Icons.home_outlined, 'Flat / Unit',
                    user?.flatNumber.isNotEmpty == true ? user!.flatNumber : '—'),
                _divider(),
                _detailRow(Icons.apartment_outlined, 'Block',
                    user?.block.isNotEmpty == true ? user!.block : '—'),
                _divider(),
                _detailRow(Icons.phone_outlined, 'Phone',
                    user?.phone.isNotEmpty == true ? user!.phone : '—'),
                _divider(),
                _detailRow(Icons.verified_user_outlined, 'Status',
                    (user?.status ?? 'pending').toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _label('Family Members'),
          const SizedBox(height: 12),
          ref.watch(residentFamilyProvider).when(
                loading: () => _loadingBox(),
                error: (_, __) => _errorBox('Could not load family members'),
                data: (list) => list.isEmpty
                    ? _emptyBox(Icons.group_outlined, 'No family members added yet')
                    : _card(list
                        .map((f) => _detailRow(
                            Icons.person_outline,
                            f.relation.isNotEmpty ? f.relation : 'Member',
                            f.name + (f.phone.isNotEmpty ? '  ·  ${f.phone}' : '')))
                        .toList()),
              ),
          const SizedBox(height: 24),

          _label('Vehicle Registration'),
          const SizedBox(height: 12),
          ref.watch(residentVehiclesProvider).when(
                loading: () => _loadingBox(),
                error: (_, __) => _errorBox('Could not load vehicles'),
                data: (list) => list.isEmpty
                    ? _emptyBox(Icons.directions_car_outlined, 'No vehicles registered yet')
                    : _card(list
                        .map((v) => _detailRow(
                            Icons.directions_car_outlined,
                            v.type.isNotEmpty ? v.type.toUpperCase() : 'VEHICLE',
                            v.plate + (v.makeModel.isNotEmpty ? '  ·  ${v.makeModel}' : '')))
                        .toList()),
              ),
          const SizedBox(height: 24),

          _label('KYC Documents'),
          const SizedBox(height: 12),
          ref.watch(residentKycProvider).when(
                loading: () => _loadingBox(),
                error: (_, __) => _errorBox('Could not load documents'),
                data: (list) => list.isEmpty
                    ? _emptyBox(Icons.badge_outlined, 'No documents uploaded yet')
                    : _card(list
                        .map((d) => _detailRow(
                            Icons.badge_outlined,
                            d.docType.isNotEmpty ? d.docType : 'Document',
                            d.status.toUpperCase()))
                        .toList()),
              ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'In-app document upload is not available yet. Please submit KYC documents to your society office.',
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryGreen,
                side: const BorderSide(color: kSlateBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text('Add Document', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),

          // ── Switch Portal ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryGreen,
                side: const BorderSide(color: kPrimaryGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text('Switch Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sign out ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBadgeRedText,
                side: const BorderSide(color: kBadgeRedText),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kPrimaryGreen),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: kDeepNavy, fontSize: 13)),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: kSlateBorder);

  Widget _card(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) children.add(_divider());
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _loadingBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: kBadgeRedText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));

  Widget _emptyBox(IconData icon, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
}
