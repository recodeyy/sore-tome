import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'dart:convert';

final complaintClustersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService.get('/ai/complaint-clusters');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['clusters'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load complaint clusters');
});

class ComplaintIntelligenceScreen extends ConsumerWidget {
  const ComplaintIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clustersAsync = ref.watch(complaintClustersProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kEmeraldSkyGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Complaint Intelligence', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('AI root-cause & cluster detection', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kPrimaryBlue.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_fix_high_rounded, color: kPrimaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI groups related complaints to reveal systemic issues. Multiple reports about water pressure across floors = 1 infrastructure incident.',
                            style: GoogleFonts.outfit(fontSize: 12, color: kPrimaryBlue, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  clustersAsync.when(
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            Text('Could not load clusters', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(complaintClustersProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (clusters) => clusters.isEmpty
                        ? _EmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${clusters.length} Cluster${clusters.length == 1 ? '' : 's'} Detected',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              ...clusters.asMap().entries.map((entry) =>
                                _ClusterCard(cluster: entry.value, index: entry.key)
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: entry.key * 80))
                                    .slideY(begin: 0.05)
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  final Map<String, dynamic> cluster;
  final int index;
  const _ClusterCard({required this.cluster, required this.index});

  @override
  Widget build(BuildContext context) {
    final confidence = ((cluster['confidence'] ?? 0.0) as num).toDouble();
    final affectedUnits = (cluster['affectedUnits'] as List? ?? []).cast<String>();
    final complaintIds = (cluster['complaintIds'] as List? ?? []).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimaryGreen.withValues(alpha: 0.15),
                  child: Text('${index + 1}', style: GoogleFonts.outfit(color: kPrimaryGreen, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cluster['rootCause'] ?? 'Unknown root cause',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                ),
                _ConfidenceBadge(confidence: confidence),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cluster['explanation'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Tag(label: '${complaintIds.length} complaints', color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    _Tag(label: '${affectedUnits.length} units', color: kPrimaryBlue),
                    if (cluster['estimatedResolutionHours'] != null) ...[
                      const SizedBox(width: 8),
                      _Tag(label: '~${cluster['estimatedResolutionHours']}h to resolve', color: kAccentGreen),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Creating a grouped infrastructure incident is not available yet.')),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text('Create Infrastructure Incident', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreen,
                      side: const BorderSide(color: kPrimaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();
    final color = confidence >= 0.8 ? kAccentGreen : confidence >= 0.6 ? Colors.orange : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$pct% AI', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 72, color: kAccentGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Clusters Detected', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(
              'No recurring complaint patterns found in the past 14 days. All issues appear to be isolated.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
