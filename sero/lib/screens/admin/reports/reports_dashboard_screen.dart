import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'financial_report_screen.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

/// Reports Dashboard — Screen 1 of 2
/// Overview of report generation, downloads, and categories.
class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Text(
              'Reports Dashboard',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 24),
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
                    BoxShadow(
                      color: const Color(0xFF064E3B).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
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
                            Text(
                              'Total Reports',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              MockReportsData.totalReportsGenerated.toString(),
                              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Generated This Month',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.bar_chart, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SummaryMiniItem(
                          label: 'Downloads (This Month)',
                          value: MockReportsData.totalDownloads.toString(),
                          icon: Icons.file_download_outlined,
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                        _SummaryMiniItem(
                          label: 'Scheduled Reports',
                          value: MockReportsData.scheduledReports.toString(),
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Report Categories ──
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Report Categories'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: MockReportsData.categories.map((cat) {
                return _CategoryCard(
                  title: cat['title'] as String,
                  count: cat['count'] as int,
                  icon: IconData(cat['icon'] as int, fontFamily: 'MaterialIcons'),
                  color: Color(cat['color'] as int),
                  onTap: () {
                    if (cat['title'] == 'Financial Reports') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportScreen()));
                    }
                  },
                );
              }).toList(),
            ),
          ),

          // ── Recent Reports ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Reports',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: MockReportsData.recentReports.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No reports generated yet.',
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = MockReportsData.recentReports[index];
                        return _RecentReportTile(
                          title: report['title'] as String,
                          subtitle: report['subtitle'] as String,
                          date: report['date'] as String,
                          type: report['type'] as String,
                          icon: IconData(report['icon'] as int, fontFamily: 'MaterialIcons'),
                          color: Color(report['color'] as int),
                        );
                      },
                      childCount: MockReportsData.recentReports.length,
                    ),
                  ),
          ),

          // ── Schedule Button ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF064E3B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF064E3B)),
                    const SizedBox(width: 10),
                    Text(
                      'Schedule New Report',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF064E3B)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMiniItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count Reports',
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String type;
  final IconData icon;
  final Color color;

  const _RecentReportTile({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    Icon(
                      type == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
                      size: 12,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      type,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
