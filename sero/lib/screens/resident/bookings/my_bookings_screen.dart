import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/my_bookings_provider.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident My Bookings — read-only list of amenity bookings.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Bookings',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: async.when(
          loading: () => const LiveLoadingView(label: 'Loading your bookings…'),
          error: (e, _) => LiveErrorView(
              error: e, onRetry: () => ref.invalidate(myBookingsProvider)),
          data: (bookings) {
            if (bookings.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  LiveEmptyView(
                    icon: Icons.event_busy_outlined,
                    message:
                        'No bookings yet.\nBook an amenity to see it here.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: bookings.length,
              itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
            );
          },
        ),
      ),
    );
  }
}

String _formatRange(String startIso, String endIso) {
  final start = DateTime.tryParse(startIso)?.toLocal();
  final end = DateTime.tryParse(endIso)?.toLocal();
  if (start == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String t(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  final datePart = '${start.day} ${months[start.month - 1]}';
  if (end == null) return '$datePart, ${t(start)}';
  return '$datePart, ${t(start)} – ${t(end)}';
}

class _BookingCard extends StatelessWidget {
  final MyBooking booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = _formatRange(booking.startAt, booking.endAt);
    final color = _statusColor(booking.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Color(0xFF059669), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.amenityName.isNotEmpty
                      ? booking.amenityName
                      : 'Amenity',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(when,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          if (booking.status.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(booking.status.toUpperCase(),
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
        ],
      ),
    );
  }
}
