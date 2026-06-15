import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'rules_cards.dart';
import 'package:sero/providers/shared/ai_provider.dart';

class GovernanceMetricsBar extends ConsumerWidget {
  final VoidCallback onDraftTap;
  const GovernanceMetricsBar({super.key, required this.onDraftTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiRulesAsync = ref.watch(aiRulesProvider);
    final jobsAsync = ref.watch(aiJobsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Metric 1: Active Rules
            aiRulesAsync.when(
              data: (rules) => MetricCard(
                title: '${rules.length} Active',
                subtitle: 'Rules discovered in documents',
                icon: Icons.gavel_rounded,
                iconColor: Colors.white,
                gradient: const [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              loading: () => const MetricPlaceholder(),
              error: (_, __) => const MetricCard(
                title: '--',
                subtitle: 'Error fetching rules',
                icon: Icons.error_outline_rounded,
                iconColor: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            
            // Metric 2: AI Syncing Job Status
            jobsAsync.when(
              data: (jobs) {
                final pending = jobs.where((j) => j['status'] != 'indexed' && j['status'] != 'failed').length;
                return MetricCard(
                  title: '$pending Pending',
                  subtitle: 'Bylaws currently being indexed',
                  icon: Icons.update_rounded,
                  iconColor: const Color(0xFF64748B),
                  color: Colors.white,
                  badgeText: pending > 0 ? 'SYNCING' : 'IDLE',
                );
              },
              loading: () => const MetricPlaceholder(),
              error: (_, __) => const MetricCard(
                title: '0',
                subtitle: 'No active ingestions',
                icon: Icons.cloud_off_rounded,
                iconColor: Color(0xFF64748B),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            
            // Metric 3: Quick Action (Draft)
            MetricCard(
              title: 'Draft Rule',
              subtitle: 'Manual protocol creation',
              icon: Icons.add_rounded,
              iconColor: const Color(0xFF0D9488), // kPrimaryGreen equivalent
              color: const Color(0xFFF8FAFC),
              isCenter: true,
              onTap: onDraftTap,
            ),
          ],
        ),
      ),
    );
  }
}







