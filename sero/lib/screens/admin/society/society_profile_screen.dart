import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'society_information_screen.dart';
import 'society_logo_screen.dart';

/// Society Profile — Screen 2 of 6
/// Shows society cover image, logo, and key info details with Edit button.
class SocietyProfileScreen extends StatelessWidget {
  const SocietyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {},
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Cover Image & Logo ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryGreen, kPrimaryGreen.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Simulated building pattern
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Opacity(
                                opacity: 0.15,
                                child: Icon(Icons.apartment_rounded, size: 200, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 20,
                              child: Text(
                                'Green Residency',
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
                          value: MockSocietyData.name,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.tag,
                          label: 'Society Code',
                          value: MockSocietyData.code,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.category_outlined,
                          label: 'Type',
                          value: MockSocietyData.type,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.description_outlined,
                          label: 'Registration Number',
                          value: MockSocietyData.registrationNumber,
                        ),
                        _ProfileInfoRow(
                          icon: Icons.people_outline,
                          label: 'Total Members',
                          value: MockSocietyData.totalMembers.toString(),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.apartment_outlined,
                          label: 'Total Flats',
                          value: MockSocietyData.totalFlats.toString(),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.view_column_outlined,
                          label: 'Total Wings',
                          value: MockSocietyData.totalWings.toString(),
                        ),
                        _ProfileInfoRow(
                          icon: Icons.view_module_outlined,
                          label: 'Total Blocks',
                          value: MockSocietyData.totalBlocks.toString(),
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
