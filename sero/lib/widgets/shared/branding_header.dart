import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/screens/resident/visitors/visitor_approval_screen.dart';
import 'brand_logo.dart';

class BrandingHeader extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  const BrandingHeader({super.key, this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 20,
          right: 20,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: kPrimaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SocietyLogo(size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'The Sero',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorApprovalScreen()));
                  },
                  child: const Icon(
                    Icons.security_rounded, // Gate icon
                    color: Color(0xFF64748B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onNotificationsTap,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF64748B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1F5F9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



