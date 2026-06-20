import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Amenities Dashboard Screen — Amenities Module
/// Central hub for booking summary cards, amenity cards with operating status, and upcoming bookings.
class AmenitiesDashboardScreen extends ConsumerWidget {
  const AmenitiesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final amenitiesAsync = ref.watch(amenitiesDashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text('Amenities Dashboard', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF1E293B)), onPressed: null),
                if (unreadCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          unreadCount.toString(),
                          style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: amenitiesAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading amenities…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(amenitiesDashboardProvider),
        ),
        data: (data) {
          final amenities = (data['amenities'] as List?) ??
              (data['items'] as List?) ??
              const [];
          final upcomingBookings = (data['upcoming_bookings'] as List?) ??
              (data['bookings'] as List?) ??
              const [];
          final totalAmenities = amenities.isNotEmpty
              ? amenities.length
              : ((data['total_amenities'] ?? data['totalAmenities'] ?? 0) is num
                  ? ((data['total_amenities'] ?? data['totalAmenities'] ?? 0) as num).toInt()
                  : 0);
          final todaysBookings = (data['todays_bookings'] ?? data['today_bookings'] ?? 0) is num
              ? ((data['todays_bookings'] ?? data['today_bookings'] ?? 0) as num).toInt()
              : 0;
          final pendingApproval = (data['pending_approval'] ?? data['pending'] ?? 0) is num
              ? ((data['pending_approval'] ?? data['pending'] ?? 0) as num).toInt()
              : 0;
          final monthRevenue = '₹ ${data['month_revenue'] ?? data['revenue'] ?? 0}';
          return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Metrics Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _MetricMiniCard(label: 'Total Amenities', value: totalAmenities.toString(), icon: Icons.sports_tennis_outlined, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 10),
                  _MetricMiniCard(label: "Today's Bookings", value: todaysBookings.toString(), icon: Icons.calendar_today_outlined, color: const Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  _MetricMiniCard(label: 'Pending Approval', value: pendingApproval.toString(), icon: Icons.access_time, color: const Color(0xFFEA580C)),
                  const SizedBox(width: 10),
                  _MetricMiniCard(label: 'This Month Revenue', value: monthRevenue, icon: Icons.payments_outlined, color: const Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),

          // ── Amenities Cards ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Amenities',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: amenities.isEmpty
                ? const SliverToBoxAdapter(
                    child: LiveEmptyView(
                      icon: Icons.sports_tennis_outlined,
                      message: 'No amenities available.',
                    ),
                  )
                : SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: amenities.map((a) {
                      final amenity = a is Map ? a : const {};
                      return _AmenityCard(
                        name: (amenity['name'] ?? '').toString(),
                        status: (amenity['status'] ?? '').toString(),
                        time: (amenity['time'] ?? amenity['hours'] ?? '').toString(),
                        bookings: (amenity['bookings'] ?? amenity['bookings_today'] ?? 0) is num
                            ? ((amenity['bookings'] ?? amenity['bookings_today'] ?? 0) as num).toInt()
                            : 0,
                        // Fixed icon (tree-shake safe): backend amenities do not
                        // carry Flutter icon codepoints, and dynamic IconData
                        // breaks release icon tree-shaking.
                        icon: Icons.sports_tennis_outlined,
                        color: amenity['color'] is int
                            ? Color(amenity['color'] as int)
                            : const Color(0xFF0D9488),
                      );
                    }).toList(),
                  ),
          ),

          // ── Upcoming Bookings ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Upcoming Bookings',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: upcomingBookings.isEmpty
                ? const SliverToBoxAdapter(
                    child: LiveEmptyView(
                      icon: Icons.event_busy_outlined,
                      message: 'No upcoming bookings found.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final b = upcomingBookings[index];
                        final booking = b is Map ? b : const {};
                        return _BookingTile(
                          date: (booking['date'] ?? '').toString(),
                          title: (booking['title'] ?? '').toString(),
                          desc: (booking['desc'] ?? booking['description'] ?? '').toString(),
                          time: (booking['time'] ?? '').toString(),
                          status: (booking['status'] ?? '').toString(),
                          color: booking['color'] is int
                              ? Color(booking['color'] as int)
                              : const Color(0xFF2563EB),
                        );
                      },
                      childCount: upcomingBookings.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AdminActions.comingSoon(context, 'Adding amenities'),
        backgroundColor: const Color(0xFF064E3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricMiniCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  final String name;
  final String status;
  final String time;
  final int bookings;
  final IconData icon;
  final Color color;

  const _AmenityCard({
    required this.name,
    required this.status,
    required this.time,
    required this.bookings,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Hero Section
          Container(
             height: 80,
             decoration: BoxDecoration(
               color: const Color(0xFFF1F5F9),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
             ),
             child: Center(
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                 child: Icon(icon, color: Colors.white, size: 24),
               ),
             ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                    Text(' • $time', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bookings Today', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B))),
                    Text(bookings.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final String date;
  final String title;
  final String desc;
  final String time;
  final String status;
  final Color color;

  const _BookingTile({
    required this.date,
    required this.title,
    required this.desc,
    required this.time,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text(date.split(' ').isNotEmpty ? date.split(' ')[0] : date, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                Text(date.split(' ').length > 1 ? date.split(' ')[1] : '', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
                Text(time, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
             child: Text(status, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
