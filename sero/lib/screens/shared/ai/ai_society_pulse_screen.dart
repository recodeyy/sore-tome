import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'dart:convert';

// ─── Provider ─────────────────────────────────────────────────────────────────
final aiPulseProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get('/ai/society-pulse');
  if (res.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }
  throw Exception('Failed to load AI pulse');
});

// ─── Main Screen ──────────────────────────────────────────────────────────────
class AISocietyPulseScreen extends ConsumerWidget {
  const AISocietyPulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulseAsync = ref.watch(aiPulseProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kPremiumGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kAccentGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kAccentGreen.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: kAccentGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('AI LIVE', style: GoogleFonts.outfit(color: kAccentGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Society Pulse', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('AI-powered operational intelligence', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: pulseAsync.when(
              loading: () => const _PulseSkeleton(),
              error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(aiPulseProvider)),
              data: (pulse) => _PulseBody(pulse: pulse, ref: ref),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulse Body ───────────────────────────────────────────────────────────────
class _PulseBody extends StatelessWidget {
  final Map<String, dynamic> pulse;
  final WidgetRef ref;
  const _PulseBody({required this.pulse, required this.ref});

  @override
  Widget build(BuildContext context) {
    final complaint = Map<String, dynamic>.from(pulse['complaintHealth'] ?? {});
    final financial = Map<String, dynamic>.from(pulse['financialHealth'] ?? {});
    final maintenance = Map<String, dynamic>.from(pulse['maintenanceHealth'] ?? {});
    final community = Map<String, dynamic>.from(pulse['communityPulse'] ?? {});
    final staffH = Map<String, dynamic>.from(pulse['staffHealth'] ?? {});
    final actions = (pulse['autopilotActions'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autopilot actions banner
          if (actions.isNotEmpty) ...[
            _SectionHeader(title: 'Autopilot Alerts', icon: Icons.bolt_rounded, color: Colors.deepOrange),
            const SizedBox(height: 8),
            ...actions.map((a) => _AutopilotCard(action: a).animate().fadeIn().slideX(begin: -0.05)),
            const SizedBox(height: 20),
          ],

          // Health metrics grid
          _SectionHeader(title: 'Health Overview', icon: Icons.monitor_heart_outlined, color: kAccentGreen),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _HealthCard(
                title: 'Complaints',
                value: '${complaint['openCount'] ?? 0}',
                subtitle: '${complaint['overdueCount'] ?? 0} overdue',
                icon: Icons.report_problem_outlined,
                riskLevel: complaint['slaBreachRisk'] ?? 'low',
              ).animate().fadeIn(delay: 100.ms),
              _HealthCard(
                title: 'Collection',
                value: '${(complaint['collectionRate'] ?? financial['collectionRate'] ?? 0).toStringAsFixed(0)}%',
                subtitle: '${financial['pendingInvoices'] ?? 0} pending',
                icon: Icons.account_balance_wallet_outlined,
                riskLevel: (financial['collectionRate'] ?? 100) < 70 ? 'high' : 'low',
              ).animate().fadeIn(delay: 150.ms),
              _HealthCard(
                title: 'Assets',
                value: '${maintenance['assetsAtRisk'] ?? 0}',
                subtitle: 'at maintenance risk',
                icon: Icons.build_outlined,
                riskLevel: (maintenance['assetsAtRisk'] ?? 0) > 3 ? 'medium' : 'low',
              ).animate().fadeIn(delay: 200.ms),
              _HealthCard(
                title: 'Staff Today',
                value: '${staffH['presentToday'] ?? 0}',
                subtitle: '${staffH['absentToday'] ?? 0} absent',
                icon: Icons.badge_outlined,
                riskLevel: (staffH['absentToday'] ?? 0) > 2 ? 'medium' : 'low',
              ).animate().fadeIn(delay: 250.ms),
            ],
          ),
          const SizedBox(height: 20),

          // Financial anomaly
          if (financial['anomalyFlagged'] == true) ...[
            _SectionHeader(title: 'Financial Anomaly', icon: Icons.warning_amber_rounded, color: Colors.amber),
            const SizedBox(height: 8),
            _AnomalyBanner(detail: financial['anomalyDetail'] ?? 'Unusual financial pattern detected.'),
            const SizedBox(height: 20),
          ],

          // Community pulse
          _SectionHeader(title: 'Community Pulse', icon: Icons.people_outline_rounded, color: kPrimaryBlue),
          const SizedBox(height: 8),
          _CommunityPulseCard(community: community),
          const SizedBox(height: 20),

          // AI transparency footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: kPrimaryGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI insights are suggestions only. All high-impact actions require your approval.',
                    style: GoogleFonts.outfit(color: kPrimaryGreen, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final String riskLevel;

  const _HealthCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.riskLevel,
  });

  Color get _riskColor {
    switch (riskLevel) {
      case 'high':
      case 'critical':
        return Colors.redAccent;
      case 'medium':
        return Colors.orange;
      default:
        return kAccentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: _riskColor, size: 20),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _riskColor, shape: BoxShape.circle),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutopilotCard extends StatelessWidget {
  final Map<String, dynamic> action;
  const _AutopilotCard({required this.action});

  Color get _priorityColor {
    switch (action['priority']) {
      case 'critical': return Colors.redAccent;
      case 'high': return Colors.deepOrange;
      case 'medium': return Colors.amber;
      default: return kAccentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _priorityColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _priorityColor.withValues(alpha: 0.12),
          child: Icon(Icons.bolt_rounded, color: _priorityColor, size: 20),
        ),
        title: Text(
          action['title'] ?? '',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            action['description'] ?? '',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: action['requiresApproval'] == true
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Review', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _AnomalyBanner extends StatelessWidget {
  final String detail;
  const _AnomalyBanner({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Required', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF78350F))),
                const SizedBox(height: 4),
                Text(detail, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF92400E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPulseCard extends StatelessWidget {
  final Map<String, dynamic> community;
  const _CommunityPulseCard({required this.community});

  @override
  Widget build(BuildContext context) {
    final score = (community['engagementScore'] ?? 0) as num;
    final concerns = (community['emergingConcerns'] as List? ?? []).cast<String>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Engagement Score', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    Text('${score.toInt()}%', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: kPrimaryBlue)),
                  ],
                ),
              ),
              _MiniStat(label: 'Polls', value: '${community['recentPolls'] ?? 0}'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Notices', value: '${community['unresolvedNotices'] ?? 0}'),
            ],
          ),
          if (concerns.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('Emerging Concerns', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            ...concerns.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
      ],
    );
  }
}

class _PulseSkeleton extends StatelessWidget {
  const _PulseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(5, (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0))),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text('Could not load AI insights', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
