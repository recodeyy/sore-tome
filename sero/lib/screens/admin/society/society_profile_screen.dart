import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/admin/admin_actions.dart';
import 'society_information_screen.dart';

/// Society Profile — Screen 2 of 6
/// Shows society cover image, logo, and key info details with Edit button.
class SocietyProfileScreen extends ConsumerWidget {
  const SocietyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(societyProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Society Profile',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)),
                  onPressed: () => AdminActions.comingSoon(context, 'Profile options'),
                ),
              ],
            ),
          ),

          Expanded(
            child: profileAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading society profile…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(societyProfileProvider),
              ),
              data: (data) {
                final profile = (data['profile'] as Map?) ?? const {};
                final structure = (data['structure'] as Map?) ?? const {};
                final name = (profile['name'] ?? '').toString();
                final code = (profile['code'] ?? '').toString();
                final type = (profile['type'] ?? '').toString();
                final regNumber =
                    (profile['registrationNumber'] ?? profile['registration_number'] ?? '').toString();
                final totalMembers =
                    (structure['totalMembers'] ?? structure['total_members'] ?? profile['totalMembers'] ?? 0).toString();
                final totalFlats =
                    (structure['totalFlats'] ?? structure['total_units'] ?? structure['total_flats'] ?? 0).toString();
                final totalWings =
                    (structure['totalWings'] ?? structure['total_wings'] ?? 0).toString();
                final totalBlocks =
                    (structure['totalBlocks'] ?? structure['total_blocks'] ?? 0).toString();
                return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Cover Image & Logo ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Society building photo
                            Image.asset(
                              'assets/images/society_building.png',
                              fit: BoxFit.cover,
                            ),
                            // Dark gradient overlay for legibility
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black54],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 20,
                              child: Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logo overlay
                      Positioned(
                        bottom: -28,
                        left: 20,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF064E3B), size: 32),
                        ),
                      ),
                      // Camera for changing cover
                      Positioned(
                        bottom: -28,
                        right: 20,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ── Profile Details ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.business,
                          label: 'Society Name',
                          value: name,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.tag,
                          label: 'Society Code',
                          value: code,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.category_outlined,
                          label: 'Type',
                          value: type,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.description_outlined,
                          label: 'Registration Number',
                          value: regNumber,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.people_outline,
                          label: 'Total Members',
                          value: totalMembers,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.apartment_outlined,
                          label: 'Total Flats',
                          value: totalFlats,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.view_column_outlined,
                          label: 'Total Wings',
                          value: totalWings,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.view_module_outlined,
                          label: 'Total Blocks',
                          value: totalBlocks,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Edit Profile Button ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SocietyInformationScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF064E3B)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
