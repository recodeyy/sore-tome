import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/main_summary_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/admin/admin_actions.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

const _kCategoryColors = <String, int>{
  'lift': 0xFF2563EB,
  'generator': 0xFFF59E0B,
  'pump': 0xFF059669,
  'cctv': 0xFF7C3AED,
  'fire': 0xFFEF4444,
  'other': 0xFF64748B,
};

int _colorForType(String? type) => _kCategoryColors[type] ?? 0xFF64748B;

class AssetsDashboardScreen extends ConsumerWidget {
  const AssetsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
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
          'Assets Dashboard',
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
      body: ref.watch(assetsDashboardProvider).when(
        loading: () => const LiveLoadingView(label: 'Loading assets…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(assetsDashboardProvider),
        ),
        data: (dash) {
          final totals = (dash['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
          final categories = (dash['categories'] as List?) ?? const [];
          final upcoming = (dash['upcomingMaintenance'] as List?) ?? const [];
          final recent = (dash['recentActivity'] as List?) ?? const [];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(assetsDashboardProvider),
            child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Main Summary Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MainSummaryCard(
                title: 'Total Assets',
                value: (totals['total'] ?? 0).toString(),
                icon: Icons.inventory_2_outlined,
                subStats: [
                  SummarySubStat('Operational', (totals['operational'] ?? 0).toString()),
                  SummarySubStat('Under Maintenance', (totals['underMaintenance'] ?? 0).toString()),
                  SummarySubStat('Out of Service', (totals['outOfService'] ?? 0).toString()),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Asset Category Grid ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: categories.map((cat) {
                return _buildCategoryCard(context, cat as Map<String, dynamic>);
              }).toList(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Upcoming Maintenance ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Upcoming Maintenance',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: upcoming.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No upcoming maintenance.',
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = upcoming[index] as Map<String, dynamic>;
                        final color = _colorForType(item['asset_type'] as String?);
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
                                decoration: BoxDecoration(
                                  color: Color(color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconForMaintenance((item['asset_name'] ?? '').toString()),
                                  size: 20,
                                  color: Color(color),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['title'] ?? '').toString(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['asset_name'] ?? ''} · Due ${(item['next_due_on'] ?? '').toString().split('T').first}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: upcoming.length,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: recent.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Center(
                        child: Text(
                          'No recent activity.',
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = recent[index] as Map<String, dynamic>;
                        final statusLabel = (activity['status'] ?? '').toString();
                        final color = statusLabel == 'completed'
                            ? 0xFF059669
                            : statusLabel == 'in_progress'
                                ? 0xFFF59E0B
                                : 0xFF2563EB;
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
                                decoration: BoxDecoration(
                                  color: Color(color).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 20,
                                  color: Color(color),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (activity['title'] ?? '').toString(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${activity['asset_name'] ?? ''} · ${activity['kind'] ?? ''}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: statusLabel,
                                bgColor: Color(color),
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AdminActions.comingSoon(context, 'Adding assets'),
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
            _buildNavItem(context, Icons.inventory_2_outlined, 'Assets', false, () {}),
            _buildNavItem(context, Icons.build_outlined, 'Maintenance', false, () {}),
            _buildNavItem(context, Icons.description_outlined, 'Logs', false, () {}),
            _buildNavItem(context, Icons.more_horiz_rounded, 'More', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    final type = (cat['type'] ?? 'other').toString();
    final color = _colorForType(type);
    final count = (cat['count'] ?? 0).toString();
    final operational = (cat['operational'] ?? 0);
    final label = type.isEmpty ? 'Other' : '${type[0].toUpperCase()}${type.substring(1)}';
    return GestureDetector(
      onTap: () {
        if (type == 'lift') {
          Navigator.pushNamed(context, '/admin/assets/details');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(type), color: Color(color), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$operational operational',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'lift':
        return Icons.elevator_outlined;
      case 'generator':
        return Icons.ev_station_outlined;
      case 'pump':
        return Icons.water_drop_outlined;
      case 'cctv':
        return Icons.videocam_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  IconData _getIconForMaintenance(String title) {
    if (title.contains('Generator')) return Icons.ev_station_outlined;
    if (title.contains('Lift')) return Icons.elevator_outlined;
    if (title.contains('Water Pump')) return Icons.water_drop_outlined;
    return Icons.build_outlined;
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
