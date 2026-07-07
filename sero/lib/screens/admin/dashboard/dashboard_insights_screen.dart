import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/admin/dashboard_provider.dart';
import 'package:sero/services/admin/admin_dashboard_service.dart';

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
        onPressed: () => _showCreateEventSheet(context, ref),
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Bottom-sheet form to create a society event, POSTed to /events-v2.
Future<void> _showCreateEventSheet(BuildContext context, WidgetRef ref) async {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  DateTime? date;
  TimeOfDay? time;
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          InputDecoration dec(String label) => InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
              );

          final dateLabel = date == null
              ? 'Pick date'
              : '${date!.day}/${date!.month}/${date!.year}';
          final timeLabel = time == null ? 'Pick time' : time!.format(sheetContext);

          Widget pickerTile(IconData icon, String label, VoidCallback onTap) => InkWell(
                onTap: submitting ? null : onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text(label, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B))),
                    ],
                  ),
                ),
              );

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Create Event',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, enabled: !submitting, decoration: dec('Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  enabled: !submitting,
                  maxLines: 3,
                  decoration: dec('Description (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, enabled: !submitting, decoration: dec('Location (optional)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: pickerTile(Icons.calendar_today_outlined, dateLabel, () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: date ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 3),
                        );
                        if (picked != null) setSheetState(() => date = picked);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: pickerTile(Icons.access_time, timeLabel, () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: time ?? TimeOfDay.now(),
                        );
                        if (picked != null) setSheetState(() => time = picked);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(sheetContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(content: Text('Please enter a title')));
                              return;
                            }
                            if (date == null || time == null) {
                              ScaffoldMessenger.of(sheetContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(content: Text('Please pick a date and time')));
                              return;
                            }
                            setSheetState(() => submitting = true);
                            try {
                              final starts = DateTime(
                                date!.year, date!.month, date!.day, time!.hour, time!.minute,
                              );
                              await AdminDashboardService.createEvent(
                                title: title,
                                description: descCtrl.text.trim(),
                                location: locationCtrl.text.trim(),
                                startsAt: starts.toUtc().toIso8601String(),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              ref.invalidate(dashboardProvider);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(
                                  backgroundColor: kPrimaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('Event "$title" created',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
                                ));
                            } catch (e) {
                              setSheetState(() => submitting = false);
                              ScaffoldMessenger.of(sheetContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(content: Text('Could not create event: $e')));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Create Event',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
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
