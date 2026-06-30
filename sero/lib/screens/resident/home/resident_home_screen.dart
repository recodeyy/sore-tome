import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import '../../shared/profile/profile_screen.dart';
import '../notifications/notifications_center_screen.dart';
import '../payments/bills_dues_screen.dart';
import '../issues/resident_issues_screen.dart';
import '../visitors/visitor_approval_screen.dart';
import 'quick_actions_screen.dart';

/// Resident Dashboard — matches the "1. RESIDENT DASHBOARD" design mockup.
/// Greeting header, flat/due card with Pay Now, Quick Overview tiles,
/// Upcoming, and Recent Activity — all wired to live providers.
class ResidentHomeScreen extends ConsumerWidget {
  /// Opens the shared resident drawer owned by [ResidentShell].
  final VoidCallback? onMenuTap;
  const ResidentHomeScreen({super.key, this.onMenuTap});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final balanceAsync = ref.watch(residentBalanceProvider);
    final issuesAsync = ref.watch(issuesProvider);
    final noticesAsync = ref.watch(noticesProvider);
    final passesAsync = ref.watch(activeGuestPassesProvider);

    final openComplaints =
        issuesAsync.maybeWhen(data: (l) => l.where((i) => i.status == 'open').length, orElse: () => 0);
    final visitors = passesAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async {
          ref.invalidate(residentBalanceProvider);
          ref.invalidate(issuesProvider);
          ref.invalidate(noticesProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.zero,
          children: [
            _header(context, user),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _flatDueCard(context, user, balanceAsync),
                    const SizedBox(height: 22),
                    _quickOverview(context, openComplaints, visitors),
                    const SizedBox(height: 22),
                    _upcoming(context),
                    const SizedBox(height: 22),
                    _recentActivity(context, noticesAsync),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Green greeting header ──────────────────────────────────────────────────
  Widget _header(BuildContext context, dynamic user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kPrimaryGreen, Color(0xFF0B7A5A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 44),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
            child: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${_greeting()} ',
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  const Text('👋', style: TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 2),
                Text(user?.name ?? 'Resident',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _circleIcon(Icons.notifications_none_rounded,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Flat + Total Due card with Pay Now ─────────────────────────────────────
  Widget _flatDueCard(BuildContext context, dynamic user, AsyncValue<double> balanceAsync) {
    final flat = (user?.flatNumber ?? '').toString();
    final block = (user?.block ?? '').toString();
    final flatLabel = [block, flat].where((s) => s.isNotEmpty).join('-');
    final balance = balanceAsync.maybeWhen(data: (b) => b, orElse: () => 0.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flatLabel.isEmpty ? 'My Home' : flatLabel,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Hubtown Sunmist, Premium Tower',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF064E3B)]),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Due', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('₹${balance.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsDuesScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pay Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Overview (4 tiles) ───────────────────────────────────────────────
  Widget _quickOverview(BuildContext context, int complaints, int visitors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRow(context, 'Quick Overview',
            onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickActionsScreen()))),
        const SizedBox(height: 12),
        Row(children: [
          _overviewTile(context, Icons.report_problem_outlined, const Color(0xFFEF4444), '$complaints', 'Complaints',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentIssuesScreen()))),
          const SizedBox(width: 12),
          _overviewTile(context, Icons.people_alt_outlined, const Color(0xFF0EA5E9), '$visitors', 'Visitors',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorApprovalScreen()))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _overviewTile(context, Icons.payments_outlined, const Color(0xFF10B981), '—', 'Payments',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsDuesScreen()))),
          const SizedBox(width: 12),
          _overviewTile(context, Icons.folder_outlined, const Color(0xFF6366F1), '—', 'Documents',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ]),
      ],
    );
  }

  Widget _overviewTile(BuildContext context, IconData icon, Color color, String value, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFF2F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upcoming ───────────────────────────────────────────────────────────────
  Widget _upcoming(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRow(context, 'Upcoming'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFF2F6)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kPrimaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.event_outlined, color: kPrimaryGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Society Meeting',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    Text('See the Community tab for events',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Recent Activity (live notices) ─────────────────────────────────────────
  Widget _recentActivity(BuildContext context, AsyncValue<List<dynamic>> noticesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionRow(context, 'Recent Activity'),
        const SizedBox(height: 12),
        noticesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen))),
          ),
          error: (e, _) => _activityItem(Icons.info_outline, 'Could not load activity', '$e'.split('\n').first),
          data: (notices) {
            if (notices.isEmpty) {
              return _activityItem(Icons.notifications_none, 'No recent activity', 'You are all caught up');
            }
            return Column(
              children: notices.take(4).map((n) {
                final title = (n.title ?? 'Notice').toString();
                final sub = (n.body ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _activityItem(Icons.campaign_outlined, title, sub),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _activityItem(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF2F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: kPrimaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                if (sub.isNotEmpty)
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionRow(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text('View All', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimaryGreen)),
          ),
      ],
    );
  }
}
