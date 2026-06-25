import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/main_summary_card.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

class ParkingDashboardScreen extends ConsumerWidget {
  const ParkingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final parkingAsync = ref.watch(parkingDashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kPremiumGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          'Parking Dashboard',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              children: [
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: parkingAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading parking data…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(parkingDashboardProvider),
        ),
        data: (data) {
          final slots = (data['slots'] as List?) ?? const [];
          final requests = (data['requests'] as List?) ?? const [];
          final violations = (data['violations'] as List?) ?? const [];
          String statusOf(dynamic s) =>
              (s is Map ? (s['status'] ?? '').toString() : '').toLowerCase();
          final totalSlots = slots.length;
          final allocatedSlots =
              slots.where((s) => statusOf(s) == 'allocated' || statusOf(s) == 'occupied').length;
          final reservedSlots = slots.where((s) => statusOf(s) == 'reserved').length;
          final availableSlots = totalSlots - allocatedSlots - reservedSlots;
          final residentVehicles = slots
              .where((s) => s is Map && (s['vehicle_type'] ?? s['type']) != 'visitor')
              .where((s) => statusOf(s) == 'allocated' || statusOf(s) == 'occupied')
              .length;
          final visitorVehicles = slots
              .where((s) => s is Map && (s['vehicle_type'] ?? s['type']) == 'visitor')
              .length;
          final pendingRequests = requests.length;
          final violationCases = violations.length;
          final pct = (int v) =>
              totalSlots == 0 ? '0 (0%)' : '$v (${((v / totalSlots) * 100).round()}%)';
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Main Summary Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: MainSummaryCard(
                    title: 'Total Parking Slots',
                    value: totalSlots.toString(),
                    icon: Icons.local_parking_rounded,
                    subStats: [
                      SummarySubStat('Allocated', allocatedSlots.toString()),
                      SummarySubStat('Available', availableSlots.toString()),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Stat Cards Grid ──
              SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  value: residentVehicles.toString(),
                  label: 'Resident Vehicles',
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  trend: 'Active',
                  trendUp: true,
                ),
                StatCard(
                  value: visitorVehicles.toString(),
                  label: 'Visitor Vehicles',
                  icon: Icons.directions_car_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  iconBgColor: const Color(0xFFF0F9FF),
                  trend: 'Today',
                  trendUp: true,
                ),
                StatCard(
                  value: pendingRequests.toString(),
                  label: 'Pending Requests',
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  iconBgColor: const Color(0xFFFFFBEB),
                  trend: '$pendingRequests Requests',
                  trendUp: false,
                ),
                StatCard(
                  value: violationCases.toString(),
                  label: 'Violation Cases',
                  icon: Icons.report_problem_outlined,
                  iconColor: const Color(0xFFEF4444),
                  iconBgColor: const Color(0xFFFEF2F2),
                  trend: 'This Month',
                  trendUp: false,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Parking Overview Chart ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Parking Overview',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kSlateBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'This Month',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        DonutChart(
                          centerValue: totalSlots.toString(),
                          centerLabel: 'Total',
                          size: 120,
                          segments: [
                            DonutSegment(value: allocatedSlots.toDouble(), color: const Color(0xFF059669), label: 'Allocated'),
                            DonutSegment(value: availableSlots.toDouble(), color: const Color(0xFF2563EB), label: 'Available'),
                            DonutSegment(value: reservedSlots.toDouble(), color: const Color(0xFFF59E0B), label: 'Reserved'),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              _buildChartLegend('Allocated', pct(allocatedSlots), const Color(0xFF059669)),
                              const SizedBox(height: 12),
                              _buildChartLegend('Available', pct(availableSlots), const Color(0xFF2563EB)),
                              const SizedBox(height: 12),
                              _buildChartLegend('Reserved', pct(reservedSlots), const Color(0xFFF59E0B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Recent Activity ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Activity',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: violations.isEmpty
                  ? const LiveEmptyView(
                      icon: Icons.local_parking_rounded,
                      message: 'No recent parking activity.',
                    )
                  : Column(
                      children: violations.take(10).map((v) {
                        final m = v is Map ? v : const {};
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0x1AEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.report_problem_outlined,
                                    size: 20, color: Color(0xFFEF4444)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (m['type'] ?? m['reason'] ?? 'Violation').toString(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (m['slot_id'] ?? m['vehicle_number'] ?? '').toString(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: (m['status'] ?? 'Open').toString(),
                                bgColor: const Color(0xFFEF4444),
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin/parking/allocation'),
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, 'Dashboard', true, () {}),
            _buildNavItem(context, Icons.local_parking_rounded, 'Slots', false, () => Navigator.pushNamed(context, '/admin/parking/allocation')),
            _buildNavItem(context, Icons.person_pin_circle_outlined, 'Visitors', false, () {}),
            _buildNavItem(context, Icons.report_problem_outlined, 'Violations', false, () {}),
            _buildNavItem(context, Icons.more_horiz_rounded, 'More', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
