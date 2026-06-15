import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/widgets/admin/issue_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/ai_provider.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notices/ai_notice_writer_screen.dart';
import 'funds/admin_funds_screen.dart';

class AdminHome extends ConsumerStatefulWidget {
  const AdminHome({super.key});

  @override
  ConsumerState<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<AdminHome> {
  final _service = FirestoreService();
  List<Issue> _pendingIssues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final issues = await _service.getIssues();
    if (!mounted) return;
    setState(() {
      _pendingIssues =
          issues.where((i) => i.status != 'resolved').toList();
      _loading = false;
    });
  }

  Future<void> _resolve(String id) async {
    await _service.updateIssueStatus(id, 'resolved');
    setState(() {
      _pendingIssues.removeWhere((i) => i.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionLabel('Quick actions'),
                        const SizedBox(height: 6),
                        _quickActions(),
                        const SizedBox(height: 12),
                        _sectionLabel('Pending issues'),
                        const SizedBox(height: 6),
                        ..._pendingIssues.map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: IssueCard(
                              issue: i,
                              showResolveButton: true,
                              onResolve: () => _resolve(i.id),
                            ),
                          ),
                        ),
                        if (_pendingIssues.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No pending issues 🎉',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A8A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _sectionLabel('Real-time AI Analytics'),
                        const SizedBox(height: 8),
                        ref.watch(aiStatsProvider).when(
                          data: (stats) => Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _AdminStatCard(
                                    value: stats['complaints']['total'].toString(), 
                                    label: 'Total Issues',
                                    icon: Icons.error_outline,
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: _AdminStatCard(
                                    value: stats['complaints']['open'].toString(), 
                                    label: 'Open Now',
                                    color: Colors.orange.shade50,
                                    icon: Icons.pending_actions,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _AdminStatCard(
                                    value: stats['ai_actions']['completed']?.toString() ?? '0', 
                                    label: 'AI Tasks Done',
                                    icon: Icons.auto_awesome,
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: _AdminStatCard(
                                    value: stats['notices']['total'].toString(), 
                                    label: 'Notices Sent',
                                    icon: Icons.campaign,
                                  )),
                                ],
                              ),
                            ],
                          ),
                          loading: () => const Center(child: LinearProgressIndicator()),
                          error: (e, s) => Text('Stats unavailable: $e', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel('Financial Insights'),
                        const SizedBox(height: 8),
                        ref.watch(financeAnalysisProvider).when(
                          data: (finance) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Top Spending: ${finance['topCategory']}',
                                   style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kPrimaryGreen),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   'AI detected high frequency in ${finance['topCategory'].toLowerCase()} expenses this month.',
                                   style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                 ),
                               ],
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    // ✅ BUG-11 FIX: Load society name dynamically from authProvider instead of hardcoding
    final user = ref.watch(authProvider).value;
    final societyLabel = user != null
        ? '${user.societyId} · ${user.role.replaceAll('_', ' ').toUpperCase()}'
        : 'Admin Panel';

    return Container(
      color: kPrimaryGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Panel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            societyLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Builder(builder: (context) {
      final actions = [
        {'icon': '🪄', 'label': 'AI Writer', 'screen': const AiNoticeWriterScreen()},
        {'icon': '📢', 'label': 'Post notice', 'route': '/admin/post-notice'},
        // ✅ BUG-10 FIX: "Add event" stays on the notice flow (correct for sharing notices/events)
        {'icon': '🎉', 'label': 'Add event', 'route': '/admin/post-notice'},
        // ✅ BUG-10 FIX: "Update funds" now navigates to AdminFundsScreen
        {'icon': '💰', 'label': 'Update funds', 'screen': const AdminFundsScreen()},
      ];
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: actions
            .map(
              (a) => GestureDetector(
                onTap: () {
                  if (a.containsKey('screen')) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => a['screen'] as Widget));
                  } else {
                    Navigator.pushNamed(context, a['route'] as String);
                  }
                },
                child: Card(
                  elevation: 0,
                  color: a['label'] == 'AI Writer' ? kPrimaryGreen.withValues(alpha: 0.1) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: a['label'] == 'AI Writer' ? kPrimaryGreen.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a['icon'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          a['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: a['label'] == 'AI Writer' ? kPrimaryGreen : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    });
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8A8A8A),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final IconData? icon;
  const _AdminStatCard({required this.value, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (icon != null) Icon(icon, size: 16, color: const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}






