import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/quick_action_button.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

/// Staff Dashboard Screen — Staff Module (1/2)
/// Key metrics overview for staff attendance, leaves, payroll, and activities.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

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
        title: Text('Staff Dashboard', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Summary Hero Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF064E3B).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Staff', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 4),
                            Text(
                              MockStaffData.totalStaff.toString(),
                              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text('Active Staff', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_right_alt, color: Colors.white, size: 14),
                              ],
                            ),
                            Text(
                              MockStaffData.activeStaff.toString(),
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SummaryStat(label: 'Present Today', value: MockStaffData.presentToday.toString(), percent: '${MockStaffData.presentPercent}%', color: const Color(0xFF10B981)),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                        _SummaryStat(label: 'On Leave', value: MockStaffData.onLeave.toString(), percent: '${MockStaffData.onLeavePercent}%', color: const Color(0xFFFB923C)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Overview Section ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Overview',
              actionText: 'This Month',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _OverviewCard(label: 'Attendance', value: '92.4%', icon: Icons.assignment_turned_in_outlined, color: const Color(0xFF059669)),
                _OverviewCard(label: 'Leaves', value: '8', icon: Icons.description_outlined, color: const Color(0xFF2563EB)),
                _OverviewCard(label: 'Pending Payroll', value: '₹ 2,45,780', icon: Icons.payments_outlined, color: const Color(0xFFEA580C)),
                _OverviewCard(label: 'Overtime Hours', value: '120h', icon: Icons.more_time_outlined, color: const Color(0xFF7C3AED)),
              ],
            ),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Quick Actions'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                QuickActionButton(label: 'Mark\nAttendance', icon: Icons.check_circle_outline, bgColor: const Color(0xFF059669), onTap: () {}),
                QuickActionButton(label: 'Leave\nRequests', icon: Icons.email_outlined, bgColor: const Color(0xFFEA580C), onTap: () {}),
                QuickActionButton(label: 'Duty\nRoster', icon: Icons.calendar_view_day_outlined, bgColor: const Color(0xFF7C3AED), onTap: () {}),
                QuickActionButton(label: 'Payroll\nSummary', icon: Icons.account_balance_outlined, bgColor: const Color(0xFF2563EB), onTap: () {}),
              ],
            ),
          ),

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
            sliver: MockStaffData.recentActivity.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No staff activity found.',
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final act = MockStaffData.recentActivity[index];
                        return _ActivityTile(
                          title: act['title'],
                          desc: act['desc'],
                          type: act['type'],
                          color: Color(act['color']),
                        );
                      },
                      childCount: MockStaffData.recentActivity.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin/staff/list'),
        backgroundColor: const Color(0xFF064E3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String percent;
  final Color color;

  const _SummaryStat({required this.label, required this.value, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(percent, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({required this.label, required this.value, required this.icon, required this.color});

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String desc;
  final String type;
  final Color color;

  const _ActivityTile({required this.title, required this.desc, required this.type, required this.color});

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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              type == 'attendance' ? Icons.check_circle_outline : (type == 'leave' ? Icons.description_outlined : Icons.payments_outlined),
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                Text(desc, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Icon(
            type == 'attendance' ? Icons.check_circle : (type == 'leave' ? Icons.access_time : Icons.description),
            color: color, size: 18,
          ),
        ],
      ),
    );
  }
}
