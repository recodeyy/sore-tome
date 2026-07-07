import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/widgets/common/mini_chart.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

/// Complaints Dashboard Screen — Complaints Module (1/2)
/// Key metrics overview, status breakdown chart, and recent complaints list.
class ComplaintsDashboardScreen extends ConsumerWidget {
  const ComplaintsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
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
        title: Text('Complaints', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
      body: ref.watch(complaintsDashboardProvider).when(
        loading: () => const LiveLoadingView(label: 'Loading complaints…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(complaintsDashboardProvider),
        ),
        data: (payload) {
          final analytics = (payload['analytics'] as Map?)?.cast<String, dynamic>() ?? const {};
          final complaints = (payload['complaints'] as List?) ?? const [];
          int n(String k) => (analytics[k] as num?)?.toInt() ?? 0;
          final total = n('total');
          final openOnly = n('open_only');
          final inProgress = n('in_progress');
          final resolvedOnly = n('resolved_only');
          final closed = n('closed');
          final overdue = n('overdue');
          final dueToday = n('due_today');
          String pct(int v) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(complaintsDashboardProvider),
            child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Metrics Grid ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _SummaryCard(
                  label: 'Total Complaints',
                  value: total.toString(),
                  subtitle: 'All Time',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF0D9488),
                ),
                _SummaryCard(
                  label: 'Open',
                  value: openOnly.toString(),
                  subtitle: pct(openOnly),
                  icon: Icons.notifications_none,
                  color: const Color(0xFFEA580C),
                ),
                _SummaryCard(
                  label: 'In Progress',
                  value: inProgress.toString(),
                  subtitle: pct(inProgress),
                  icon: Icons.hourglass_empty,
                  color: const Color(0xFF2563EB),
                ),
                _SummaryCard(
                  label: 'Resolved',
                  value: resolvedOnly.toString(),
                  subtitle: pct(resolvedOnly),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF059669),
                ),
                _SummaryCard(
                  label: 'Overdue',
                  value: overdue.toString(),
                  subtitle: pct(overdue),
                  icon: Icons.access_time,
                  color: const Color(0xFFDC2626),
                ),
                _SummaryCard(
                  label: 'Due Today',
                  value: dueToday.toString(),
                  subtitle: pct(dueToday),
                  icon: Icons.calendar_today_outlined,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),

          // ── Complaints by Status Chart ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complaints by Status', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 20),
                    total == 0
                        ? const LiveEmptyView(
                            icon: Icons.assignment_outlined,
                            message: 'No complaints yet.',
                          )
                        : Row(
                            children: [
                              DonutChart(
                                segments: [
                                  DonutSegment(value: openOnly.toDouble(), color: const Color(0xFFEA580C), label: 'Open'),
                                  DonutSegment(value: inProgress.toDouble(), color: const Color(0xFF2563EB), label: 'In Progress'),
                                  DonutSegment(value: resolvedOnly.toDouble(), color: const Color(0xFF059669), label: 'Resolved'),
                                  DonutSegment(value: closed.toDouble(), color: const Color(0xFF64748B), label: 'Closed'),
                                ],
                                size: 110,
                                centerValue: total.toString(),
                                centerLabel: 'Total',
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    _DonutLegend(color: const Color(0xFFEA580C), label: 'Open', value: '$openOnly (${pct(openOnly)})'),
                                    _DonutLegend(color: const Color(0xFF2563EB), label: 'In Progress', value: '$inProgress (${pct(inProgress)})'),
                                    _DonutLegend(color: const Color(0xFF059669), label: 'Resolved', value: '$resolvedOnly (${pct(resolvedOnly)})'),
                                    _DonutLegend(color: const Color(0xFF64748B), label: 'Closed', value: '$closed (${pct(closed)})'),
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

          // ── Recent Complaints ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Complaints',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          if (complaints.isEmpty)
            const SliverToBoxAdapter(
              child: LiveEmptyView(
                icon: Icons.assignment_outlined,
                message: 'No complaints yet.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final complaint = (complaints[index] as Map).cast<String, dynamic>();
                    final status = (complaint['status'] ?? '').toString();
                    final color = status == 'in_progress'
                        ? const Color(0xFF2563EB)
                        : status == 'open'
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF059669);
                    return _ComplaintRow(
                      id: (complaint['code'] ?? complaint['id'] ?? '').toString(),
                      title: (complaint['title'] ?? '').toString(),
                      location: (complaint['location'] ?? complaint['category'] ?? '').toString(),
                      status: status,
                      color: color,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/complaints/details',
                        arguments: complaint['id'],
                      ),
                    );
                  },
                  childCount: complaints.length,
                ),
              ),
            ),

          // ── Action Button ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/post-issue'),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text('Raise New Complaint', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                    Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _DonutLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)))),
          Text(value, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _ComplaintRow extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _ComplaintRow({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.report_problem_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(id, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      _miniStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(location, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _miniStatusBadge(String status) {
    final sColor = status == 'In Progress' ? const Color(0xFF2563EB) : (status == 'Open' ? const Color(0xFFEA580C) : const Color(0xFF059669));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700, color: sColor)),
    );
  }
}
