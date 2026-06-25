import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';




class ResidentIssuesHero extends StatelessWidget {
  final VoidCallback onNewTicketTap;
  final ValueChanged<String> onSearchChanged;

  const ResidentIssuesHero({
    super.key,
    required this.onNewTicketTap,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMMUNITY CARE',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'How can we help\nyou today?',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        hintText: 'Search reported issues...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onNewTicketTap,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fade(delay: 80.ms),
    );
  }
}

class SocietyHealthMonitor extends StatelessWidget {
  final int openCount;
  final int inProgressCount;

  const SocietyHealthMonitor({
    super.key,
    required this.openCount,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Society Health',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kAccentGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: kAccentGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Active Repairs',
                          style: GoogleFonts.outfit(
                            color: kAccentGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HealthStat(
                    label: 'ONGOING',
                    value: inProgressCount.toString(),
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 24),
                  _HealthStat(
                    label: 'REPORTED',
                    value: openCount.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ],
          ),
        ),
      ).animate().fade(delay: 150.ms),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HealthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ],
    );
  }
}

// ActionButton removed - using streamlined pill design inline

class IssuesEmptyState extends StatelessWidget {
  const IssuesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 34,
              color: kPrimaryGreen.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'All clear!',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'No issues in this category',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}







