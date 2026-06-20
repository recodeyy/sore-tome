import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/admin/dashboard_provider.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Dashboard Insights — Screen 3 of 4
/// Shows circular progress indicators for KPIs, complaint summary donut,
/// visitor summary, and upcoming events.
class DashboardInsightsScreen extends ConsumerWidget {
  const DashboardInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final dashboardAsync = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: dashboardAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading insights…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (stats) {
          final collectionEfficiency = stats.financials.percentage.toDouble().clamp(0, 100) / 100.0;
          const complaintResolution = 0.0;
          const occupancyRate = 0.0;
          final openComplaintsCount = stats.topIssues.length;
          const inProgressComplaints = 0;
          const resolvedComplaints = 0;
          const closedComplaints = 0;
          final totalComplaints = openComplaintsCount;
          const checkedIn = 0;
          const checkedOut = 0;
          final upcomingEvents = stats.recentUpdates
              .where((u) => u.type == 'event')
              .toList();
          return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Dashboard',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1E293B), size: 20),
                    onPressed: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 22),
                      onPressed: null,
                    ),
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
            ],
          ),

          // ── Insights KPI Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Insights', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/admin/reports'),
                    child: Text('View All', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryGreen)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircularIndicator(
                      value: collectionEfficiency,
                      label: 'Collection\nEfficiency',
                      sublabel: '${(collectionEfficiency * 100).round()}%',
                      color: kPrimaryGreen,
                      size: 72,
                    ),
                    CircularIndicator(
                      value: complaintResolution,
                      label: 'Complaint\nResolution',
                      sublabel: '${(complaintResolution * 100).round()}%',
                      color: const Color(0xFFD97706),
                      size: 72,
                    ),
                    CircularIndicator(
                      value: occupancyRate,
                      label: 'Occupancy\nRate',
                      sublabel: '${(occupancyRate * 100).round()}%',
                      color: const Color(0xFF059669),
                      size: 72,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Complaint Summary ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Complaint Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Text('This Month', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    DonutChart(
                      segments: [
                        DonutSegment(value: openComplaintsCount.toDouble(), color: const Color(0xFF064E3B), label: 'Open'),
                        DonutSegment(value: inProgressComplaints.toDouble(), color: const Color(0xFF10B981), label: 'In Progress'),
                        DonutSegment(value: resolvedComplaints.toDouble(), color: const Color(0xFF6EE7B7), label: 'Resolved'),
                        DonutSegment(value: closedComplaints.toDouble(), color: const Color(0xFFD1D5DB), label: 'Closed'),
                      ],
                      centerValue: totalComplaints.toString(),
                      centerLabel: 'Total',
                      size: 110,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ComplaintLegendRow(color: const Color(0xFF064E3B), label: 'Open', count: openComplaintsCount),
                          _ComplaintLegendRow(color: const Color(0xFF10B981), label: 'In Progress', count: inProgressComplaints),
                          _ComplaintLegendRow(color: const Color(0xFF6EE7B7), label: 'Resolved', count: resolvedComplaints),
                          _ComplaintLegendRow(color: const Color(0xFFD1D5DB), label: 'Closed', count: closedComplaints),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Visitor Summary ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Visitor Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Text('Today', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Checked In', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                checkedIn.toString(),
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  '—',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('vs Yesterday', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Checked Out', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                checkedOut.toString(),
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  '—',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('vs Yesterday', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Upcoming Events ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Events', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/admin/notices'),
                    child: Text('View All', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryGreen)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: upcomingEvents.isEmpty
                ? const SliverToBoxAdapter(
                    child: LiveEmptyView(
                      icon: Icons.event_outlined,
                      message: 'No upcoming events yet.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = upcomingEvents[index];
                        final date = event.createdAt;
                        const months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                        final day = date != null ? date.day.toString() : '--';
                        final month = date != null ? months[date.month] : '';
                        final details = (event.description ?? event.body ?? '').toString();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      day,
                                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryGreen),
                                    ),
                                    Text(
                                      month,
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimaryGreen),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                                    ),
                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        details,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFCBD5E1)),
                            ],
                          ),
                        );
                      },
                      childCount: upcomingEvents.length,
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AdminActions.comingSoon(context, 'Creating events'),
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ComplaintLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _ComplaintLegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
          ),
          Text(count.toString(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
