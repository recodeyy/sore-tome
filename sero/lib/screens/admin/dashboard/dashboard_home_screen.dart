import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/quick_action_button.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/screens/admin/admin_more_screen.dart';
import 'package:sero/screens/admin/governance/polls_dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/admin/dashboard_provider.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_dashboard_service.dart';

/// Dashboard Home Overview — Screen 1 of 4
/// Shows greeting, today's overview, quick actions, and recent activity.
class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen> {
  /// Catalog of available quick actions, keyed by a stable id persisted in
  /// dashboard preferences.
  static const Map<String, Map<String, dynamic>> _quickActionCatalog = {
    'notice': {'icon': Icons.campaign_outlined, 'label': 'Add Notice', 'color': null},
    'poll': {'icon': Icons.poll_outlined, 'label': 'New Poll', 'color': 0xFF10B981},
    'member': {'icon': Icons.person_add_outlined, 'label': 'Add Member', 'color': 0xFF064E3B},
    'bill': {'icon': Icons.receipt_long_outlined, 'label': 'Generate Bill', 'color': 0xFF1E3A8A},
    'more': {'icon': Icons.more_horiz, 'label': 'More', 'color': 0xFF475569},
  };
  static const List<String> _defaultOrder = ['notice', 'poll', 'member', 'bill', 'more'];

  /// Ordered list of enabled quick-action ids.
  List<String> _enabled = List.of(_defaultOrder);

  @override
  void initState() {
    super.initState();
    _loadQuickActionPrefs();
  }

  Future<void> _loadQuickActionPrefs() async {
    final prefs = await AdminDashboardService.getPreferences();
    final widgets = prefs['widgets'];
    if (widgets is List && widgets.isNotEmpty) {
      final ids = widgets
          .map((e) => e.toString())
          .where(_quickActionCatalog.containsKey)
          .toList();
      if (ids.isNotEmpty && mounted) setState(() => _enabled = ids);
    }
  }

  void _runQuickAction(String id) {
    switch (id) {
      case 'notice':
        Navigator.pushNamed(context, '/admin/communication/create-notice');
        break;
      case 'poll':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsDashboardScreen()));
        break;
      case 'member':
        Navigator.pushNamed(context, '/admin/society/flats');
        break;
      case 'bill':
        Navigator.pushNamed(context, '/admin/finance/generate-bills');
        break;
      case 'more':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMoreScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: dashboardAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading dashboard…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (stats) {
          final fin = stats.financials;
          final currency = fin.currency;
          String money(num v) => '$currency ${v.toStringAsFixed(0)}';
          final pendingApprovals = stats.pendingApprovalsCount;
          final openComplaints = stats.topIssues.length;
          final recentUpdates = stats.recentUpdates;
          return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top App Bar ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF064E3B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: const Icon(Icons.menu, color: Colors.white, size: 24),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                                if (ref.watch(notificationProvider.notifier).unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          ref.watch(notificationProvider.notifier).unreadCount.toString(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Builder(builder: (_) {
                    final hour = DateTime.now().hour;
                    final greet = hour < 12
                        ? 'Good Morning'
                        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
                    final adminName = ref.watch(authProvider).value?.name ?? 'Admin';
                    final today = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greet, $adminName 👋',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref.watch(societyProfileProvider).maybeWhen(
                                data: (d) => ((d['profile'] as Map?)?['name'] ?? 'My Society').toString(),
                                orElse: () => 'My Society',
                              ),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          today,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Today's Overview ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Overview",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/admin/dashboard/insights'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                StatCard(
                  value: pendingApprovals.toString(),
                  label: 'Pending\nApprovals',
                  icon: Icons.pending_actions,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFF7ED),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/insights'),
                ),
                StatCard(
                  value: openComplaints.toString(),
                  label: 'Open\nComplaints',
                  icon: Icons.report_outlined,
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFFEF2F2),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/insights'),
                ),
                StatCard(
                  value: money(fin.totalCollected),
                  label: "Today's\nCollection",
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFF0FDF4),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/revenue'),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                StatCard(
                  value: money(fin.balance),
                  label: 'Maintenance\nDue',
                  icon: Icons.calendar_today,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/revenue'),
                ),
                StatCard(
                  value: '0',
                  label: 'Visitors\nToday',
                  icon: Icons.directions_walk,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/insights'),
                ),
                StatCard(
                  value: '0',
                  label: 'Staff On\nDuty',
                  icon: Icons.badge,
                  iconColor: const Color(0xFF064E3B),
                  iconBgColor: const Color(0xFFF0FDF4),
                  onTap: () => Navigator.pushNamed(context, '/admin/dashboard/insights'),
                ),
              ],
            ),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCustomizeQuickActions,
                    child: Text(
                      'Edit',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _enabled.isEmpty
                  ? Text(
                      'No quick actions. Tap Edit to add some.',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _enabled.map((id) {
                        final meta = _quickActionCatalog[id]!;
                        return QuickActionButton(
                          icon: meta['icon'] as IconData,
                          label: meta['label'] as String,
                          bgColor: meta['color'] != null ? Color(meta['color'] as int) : null,
                          onTap: () => _runQuickAction(id),
                        );
                      }).toList(),
                    ),
            ),
          ),

          // ── Recent Activity ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Activity',
              actionText: 'View All',
              onAction: () => Navigator.pushNamed(context, '/admin/dashboard/notices'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: recentUpdates.isEmpty
                ? const SliverToBoxAdapter(
                    child: LiveEmptyView(
                      icon: Icons.history,
                      message: 'No recent activity yet.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = recentUpdates[index];
                        return _RecentActivityTile(
                          icon: _getActivityIcon(item.type),
                          iconColor: _getActivityColor(item.type),
                          title: item.title,
                          subtitle: (item.body ?? item.description ?? '').toString(),
                          amount: null,
                          time: item.createdAt != null
                              ? '${item.createdAt!.day}/${item.createdAt!.month}'
                              : '',
                        );
                      },
                      childCount: recentUpdates.length,
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

  /// Bottom-sheet to reorder and toggle the dashboard quick actions. The
  /// resulting order is persisted to dashboard preferences and reflected live.
  Future<void> _showCustomizeQuickActions() async {
    // Working copy: full id list (enabled first, in order) + an enabled set.
    final order = <String>[
      ..._enabled,
      ..._defaultOrder.where((id) => !_enabled.contains(id)),
    ];
    final on = _enabled.toSet();

    final saved = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  Text('Customize Quick Actions',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('Toggle and drag to reorder.',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 12),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      setSheetState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final id = order.removeAt(oldIndex);
                        order.insert(newIndex, id);
                      });
                    },
                    children: [
                      for (int i = 0; i < order.length; i++)
                        Padding(
                          key: ValueKey(order[i]),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_indicator, color: Color(0xFFCBD5E1)),
                                ),
                                const SizedBox(width: 8),
                                Icon(_quickActionCatalog[order[i]]!['icon'] as IconData,
                                    size: 20, color: const Color(0xFF64748B)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_quickActionCatalog[order[i]]!['label'] as String,
                                      style: GoogleFonts.outfit(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                ),
                                Switch(
                                  value: on.contains(order[i]),
                                  activeThumbColor: kPrimaryGreen,
                                  onChanged: (v) => setSheetState(() {
                                    if (v) {
                                      on.add(order[i]);
                                    } else {
                                      on.remove(order[i]);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        order.where(on.contains).toList(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save',
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

    if (saved != null && mounted) {
      setState(() => _enabled = saved);
      // Persist to dashboard preferences (best-effort; reflected live regardless).
      final ok = await AdminDashboardService.saveQuickActions(saved);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: kPrimaryGreen,
            behavior: SnackBarBehavior.floating,
            content: Text(ok ? 'Quick actions updated' : 'Saved locally (sync failed)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
          ));
      }
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'complaint':
        return Icons.error_outline;
      case 'visitor':
        return Icons.person_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'payment':
        return const Color(0xFF059669);
      case 'complaint':
        return const Color(0xFFEA580C);
      case 'visitor':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _RecentActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? amount;
  final String time;

  const _RecentActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (amount != null)
                Text(
                  amount!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              Text(
                time,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
