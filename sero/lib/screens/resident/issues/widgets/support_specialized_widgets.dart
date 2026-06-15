import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/facility_booking.dart';
import 'package:sero/providers/shared/community_providers.dart';

// --- 1. Reservation View ---
class ReservationView extends ConsumerWidget {
  const ReservationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return facilitiesAsync.when(
      data: (facilities) {
        if (facilities.isEmpty) {
          return _buildEmptyState(
            'No facilities registered',
            'Your society has not linked any amenities yet.',
            Icons.domain_disabled_rounded,
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final f = facilities[index];
                return _FacilityCard(facility: f).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1);
              },
              childCount: facilities.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildEmptyState(String title, String sub, IconData icon) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(sub, style: GoogleFonts.outfit(color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports_tennis_rounded, color: kPrimaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  facility.availabilityHours,
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {}, // Booking flow
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('BOOK'),
          ),
        ],
      ),
    );
  }
}

// --- 2. Records View ---
class RecordsView extends ConsumerWidget {
  const RecordsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(societyRecordsProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No society records available yet.')),
          );
        }

        final governance = records.where((r) => r.category == 'Governance').toList();
        final mom = records.where((r) => r.category == 'MOM').toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (governance.isNotEmpty) ...[
                _sectionLabel('GOVERNANCE DOCUMENTS'),
                ...governance.map((r) => _RecordItem(
                  title: r.title,
                  type: r.description,
                  icon: Icons.description_rounded,
                  color: const Color(0xFF8B5CF6),
                )),
                const SizedBox(height: 32),
              ],
              if (mom.isNotEmpty) ...[
                _sectionLabel('MEETING MINUTES (MOM)'),
                ...mom.map((r) => _RecordItem(
                  title: r.title,
                  type: r.description,
                  icon: Icons.assignment_rounded,
                  color: kPrimaryGreen,
                )),
              ],
              if (governance.isEmpty && mom.isEmpty)
                ...records.map((r) => _RecordItem(
                  title: r.title,
                  type: r.description,
                  icon: Icons.article_rounded,
                  color: kPrimaryBlue,
                )),
            ]),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error loading records: $e'))),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: const Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String title;
  final String type;
  final IconData icon;
  final Color color;
  const _RecordItem({required this.title, required this.type, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(type, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
