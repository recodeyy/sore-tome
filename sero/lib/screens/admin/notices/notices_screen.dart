import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

/// Notices Screen — Communication Module (1/2)
/// Features tabbed viewing (All/Published/Drafts) and searchable notice cards.
class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Notices', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF1E293B)), onPressed: null),
                if (ref.watch(notificationProvider.notifier).unreadCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          ref.watch(notificationProvider.notifier).unreadCount.toString(),
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
      body: Column(
        children: [
          // ── Tabs ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(8)),
                tabs: const [
                  Tab(child: Text('All Notices', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  Tab(child: Text('Published', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  Tab(child: Text('Drafts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search notices...',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),

          // ── Notices List (live) ──
          Expanded(
            child: ref.watch(noticesProvider).when(
                  loading: () => const LiveLoadingView(label: 'Loading notices…'),
                  error: (e, _) => LiveErrorView(
                    error: e,
                    onRetry: () =>
                        ref.read(noticesProvider.notifier).fetchNotices(),
                  ),
                  data: (notices) {
                    final filtered = _query.isEmpty
                        ? notices
                        : notices
                            .where((n) =>
                                n.title.toLowerCase().contains(_query) ||
                                n.body.toLowerCase().contains(_query))
                            .toList();
                    if (filtered.isEmpty) {
                      return const LiveEmptyView(
                        icon: Icons.campaign_outlined,
                        message: 'No notices yet.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(noticesProvider.notifier).fetchNotices(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final notice = filtered[index];
                          final color = notice.tag == 'new'
                              ? const Color(0xFF2563EB)
                              : notice.tag == 'today'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF7C3AED);
                          return _NoticeCard(
                            title: notice.title,
                            message: notice.body,
                            date: _formatDate(notice.createdAt),
                            category: notice.tag,
                            icon: Icons.campaign_outlined,
                            color: color,
                          );
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin/communication/create-notice'),
            icon: const Icon(Icons.add, size: 20),
            label: Text('Create New Notice', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: const Color(0xFF064E3B).withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final String category;
  final IconData icon;
  final Color color;

  const _NoticeCard({
    required this.title,
    required this.message,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
              ),
              _CategoryBadge(label: category, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
              const Icon(Icons.more_horiz, size: 18, color: Color(0xFFCBD5E1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
