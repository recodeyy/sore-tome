import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/main_summary_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Main Summary Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MainSummaryCard(
                title: 'Total Assets',
                value: MockAssetsData.totalAssets.toString(),
                icon: Icons.inventory_2_outlined,
                subStats: [
                  SummarySubStat('Operational', MockAssetsData.operational.toString()),
                  SummarySubStat('Under Maintenance', MockAssetsData.underMaintenance.toString()),
                  SummarySubStat('Out of Service', MockAssetsData.outOfService.toString()),
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
              children: MockAssetsData.categories.map((cat) {
                return _buildCategoryCard(context, cat);
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
            sliver: MockAssetsData.upcomingMaintenance.isEmpty
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
                        final item = MockAssetsData.upcomingMaintenance[index];
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
                                  color: Color(item['color']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconForMaintenance(item['title']),
                                  size: 20,
                                  color: Color(item['color']),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['date'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: item['dueIn'],
                                bgColor: Color(item['color']),
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: MockAssetsData.upcomingMaintenance.length,
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
            sliver: MockAssetsData.recentActivity.isEmpty
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
                        final activity = MockAssetsData.recentActivity[index];
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
                                  color: Color(activity['color']).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 20,
                                  color: Color(activity['color']),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['title'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activity['subtitle'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: activity['status'],
                                bgColor: Color(activity['color']),
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: MockAssetsData.recentActivity.length,
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
    return GestureDetector(
      onTap: () {
        if (cat['name'] == 'Lifts') {
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
                color: Color(cat['color']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat['icon'], color: Color(cat['color']), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              cat['name'],
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cat['count'].toString(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cat['status'],
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(cat['color']),
              ),
            ),
          ],
        ),
      ),
    );
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
