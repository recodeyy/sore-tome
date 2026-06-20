import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/quick_action_button.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/models/notice.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Dashboard Notices & Quick Stats — Screen 4 of 4  
/// Shows notice highlights, quick stats, and shortcuts section.
class DashboardNoticesScreen extends ConsumerWidget {
  const DashboardNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final noticesAsync = ref.watch(noticesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: noticesAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading notices…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.read(noticesProvider.notifier).fetchNotices(),
        ),
        data: (notices) {
          // Quick-stats have no provider source on this screen → show 0 truthfully.
          const totalMembers = 0;
          const totalFlats = 0;
          const totalStaff = 0;
          const totalVehicles = 0;
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

          // ── Notice Highlights ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notice Highlights', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
            sliver: notices.isEmpty
                ? const SliverToBoxAdapter(
                    child: LiveEmptyView(
                      icon: Icons.campaign_outlined,
                      message: 'No notices yet.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final Notice notice = notices[index];
                        final badge = notice.tag == 'new'
                            ? 'New'
                            : (notice.tag == 'today' ? 'Important' : 'General');
                        final d = notice.createdAt;
                        return _NoticeCard(
                          badge: badge,
                          title: notice.title,
                          description: notice.body,
                          date: '${d.day}/${d.month}/${d.year}',
                        );
                      },
                      childCount: notices.length,
                    ),
                  ),
          ),

          // ── Quick Stats ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Stats', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                CompactStatCard(
                  value: totalMembers.toString(),
                  label: 'Total Members',
                  icon: Icons.people_outline,
                ),
                CompactStatCard(
                  value: totalFlats.toString(),
                  label: 'Total Flats',
                  icon: Icons.apartment,
                ),
                CompactStatCard(
                  value: totalStaff.toString(),
                  label: 'Total Staff',
                  icon: Icons.badge_outlined,
                ),
                CompactStatCard(
                  value: totalVehicles.toString(),
                  label: 'Total Vehicles',
                  icon: Icons.directions_car_outlined,
                ),
              ],
            ),
          ),

          // ── Shortcuts ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text('Shortcuts', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickActionButton(
                      icon: Icons.campaign_outlined,
                      label: 'Add Notice',
                      bgColor: kPrimaryGreen,
                      onTap: () => Navigator.pushNamed(context, '/admin/communication/create-notice'),
                    ),
                    QuickActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Generate Bill',
                      bgColor: const Color(0xFF10B981),
                      onTap: () => Navigator.pushNamed(context, '/admin/finance/generate-bills'),
                    ),
                    QuickActionButton(
                      icon: Icons.person_add_outlined,
                      label: 'Add Member',
                      bgColor: const Color(0xFF1E3A8A),
                      onTap: () => Navigator.pushNamed(context, '/admin/society/flats'),
                    ),
                    QuickActionButton(
                      icon: Icons.poll_outlined,
                      label: 'Create Poll',
                      bgColor: const Color(0xFF7C3AED),
                      onTap: () => AdminActions.comingSoon(context, 'Polls'),
                    ),
                    QuickActionButton(
                      icon: Icons.more_horiz,
                      label: 'More',
                      bgColor: const Color(0xFF475569),
                      onTap: () => Navigator.pushNamed(context, '/admin/reports'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin/communication/create-notice'),
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String badge;
  final String title;
  final String description;
  final String date;

  const _NoticeCard({
    required this.badge,
    required this.title,
    required this.description,
    required this.date,
  });

  StatusBadge _getBadge() {
    switch (badge) {
      case 'New':
        return StatusBadge.newBadge();
      case 'Important':
        return StatusBadge.important();
      default:
        return StatusBadge.general();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
