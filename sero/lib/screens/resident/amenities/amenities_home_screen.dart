import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/models/facility_booking.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import '../facilities/facilities_screen.dart';

/// Amenities Home (design: amenities.png screen 1).
///
/// LIVE DATA:
///  - Quick Access grid  -> facilitiesProvider (Firestore `facilities` filtered by society_id)
///  - Upcoming Bookings   -> userBookingsProvider (Firestore `bookings` for this user)
///  - Book Now flow       -> FacilitiesScreen -> POST /facilities/:id/book
class AmenitiesHomeScreen extends ConsumerWidget {
  const AmenitiesHomeScreen({super.key});

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('gym') || n.contains('fitness')) return Icons.fitness_center_rounded;
    if (n.contains('pool') || n.contains('swim')) return Icons.pool_rounded;
    if (n.contains('squash') || n.contains('tennis') || n.contains('court')) {
      return Icons.sports_tennis_rounded;
    }
    if (n.contains('guest')) return Icons.bedroom_parent_rounded;
    if (n.contains('club')) return Icons.meeting_room_rounded;
    if (n.contains('park')) return Icons.local_parking_rounded;
    return Icons.apartment_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async {
          ref.invalidate(facilitiesProvider);
          ref.invalidate(userBookingsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 140),
          children: [
            // ── Hero banner (Club House photo + green overlay) ──
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/images/amenity_clubhouse.png', fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            kPrimaryGreen.withValues(alpha: 0.92),
                            kPrimaryGreen.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Premium Amenities',
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('for a better living',
                            style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Access ──
            _label('Quick Access'),
            const SizedBox(height: 12),
            facilitiesAsync.when(
              loading: () => const SkeletonCard(height: 120, margin: EdgeInsets.zero),
              error: (e, _) => _errorBox('Could not load amenities'),
              data: (facilities) {
                if (facilities.isEmpty) {
                  return _emptyBox(Icons.pool_outlined, 'No amenities available yet');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: facilities.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final f = facilities[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FacilitiesScreen())),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: kSlateBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryGreen.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(f.name), color: kPrimaryGreen, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(f.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: kDeepNavy)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Upcoming Bookings ──
            _label('Upcoming Bookings'),
            const SizedBox(height: 12),
            bookingsAsync.when(
              loading: () => const SkeletonCard(height: 88, margin: EdgeInsets.zero),
              error: (e, _) => _errorBox('Could not load bookings'),
              data: (bookings) {
                final upcoming = bookings
                    .where((b) => b.endTime.isAfter(DateTime.now()) && b.status != 'cancelled')
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                if (upcoming.isEmpty) {
                  return _emptyBox(Icons.event_busy_outlined, 'No upcoming bookings');
                }
                return Column(children: upcoming.map(_bookingTile).toList());
              },
            ),
            const SizedBox(height: 24),

            // ── Book CTA ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const FacilitiesScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text('Book an Amenity',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingTile(Booking b) {
    final d = b.startTime;
    final dateStr = '${d.day}/${d.month}/${d.year}';
    final timeStr =
        '${TimeOfDay.fromDateTime(b.startTime).format24()} - ${TimeOfDay.fromDateTime(b.endTime).format24()}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAccentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: kAccentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                Text('$dateStr • $timeStr',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kBadgeGreenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(b.status.toUpperCase(),
                style: GoogleFonts.outfit(
                    color: kBadgeGreenText, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));

  Widget _emptyBox(IconData icon, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBadgeRedBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(msg, style: GoogleFonts.outfit(color: kBadgeRedText, fontSize: 13)),
      );
}

extension on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
