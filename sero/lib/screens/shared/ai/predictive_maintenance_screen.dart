import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'dart:convert';

final maintenancePredictionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService.get('/ai/maintenance-predictions');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['predictions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load predictions');
});

class PredictiveMaintenanceScreen extends ConsumerWidget {
  const PredictiveMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(maintenancePredictionsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Predictive Maintenance', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('AI failure-risk scoring for society assets', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: predictionsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text('Could not load predictions', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => ref.invalidate(maintenancePredictionsProvider), child: const Text('Retry')),
                    ],
                  ),
                ),
                data: (predictions) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (predictions.isEmpty)
                      _EmptyState()
                    else ...[
                      // Summary row
                      _SummaryRow(predictions: predictions),
                      const SizedBox(height: 20),
                      Text(
                        '${predictions.length} Asset${predictions.length == 1 ? '' : 's'} Need Attention',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      ...predictions.asMap().entries.map((entry) =>
                        _AssetRiskCard(prediction: entry.value, index: entry.key)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: entry.key * 60))
                            .slideY(begin: 0.04)
                      ),
                    ],
                    const SizedBox(height: 80),
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

class _SummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  const _SummaryRow({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final critical = predictions.where((p) => p['riskLevel'] == 'critical').length;
    final high = predictions.where((p) => p['riskLevel'] == 'high').length;
    final medium = predictions.where((p) => p['riskLevel'] == 'medium').length;

    return Row(
      children: [
        _SumCard(label: 'Critical', count: critical, color: Colors.redAccent),
        const SizedBox(width: 10),
        _SumCard(label: 'High', count: high, color: Colors.deepOrange),
        const SizedBox(width: 10),
        _SumCard(label: 'Medium', count: medium, color: Colors.amber),
      ],
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SumCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AssetRiskCard extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final int index;
  const _AssetRiskCard({required this.prediction, required this.index});

  Color get _riskColor {
    switch (prediction['riskLevel']) {
      case 'critical': return Colors.redAccent;
      case 'high': return Colors.deepOrange;
      case 'medium': return Colors.amber;
      default: return kAccentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (prediction['failureRiskScore'] ?? 0) as num;
    final evidence = (prediction['evidence'] as List? ?? []).cast<String>();
    final costDelay = (prediction['costOfDelay'] ?? 0) as num;
    final confidence = ((prediction['confidence'] ?? 0.0) as num).toDouble();

    // Parse date safely
    String dateStr = 'Soon';
    if (prediction['recommendedMaintenanceDate'] != null) {
      try {
        final d = DateTime.parse(prediction['recommendedMaintenanceDate']);
        final diff = d.difference(DateTime.now()).inDays;
        dateStr = diff <= 0 ? 'Overdue' : 'In $diff days';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _riskColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction['assetName'] ?? 'Unknown Asset',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Maintenance recommended: $dateStr',
                        style: GoogleFonts.outfit(fontSize: 12, color: _riskColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Risk gauge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52, height: 52,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: _riskColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                        strokeWidth: 5,
                      ),
                    ),
                    Text('${score.toInt()}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _riskColor)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (evidence.isNotEmpty) ...[
                  Text('Evidence', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  ...evidence.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
                        Expanded(child: Text(e, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _MiniInfoChip(label: 'Cost of delay: ₹${costDelay.toInt()}', icon: Icons.monetization_on_outlined, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    _MiniInfoChip(label: '${(confidence * 100).toInt()}% confidence', icon: Icons.verified_outlined, color: kPrimaryBlue),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scheduling a work order from a prediction is not available yet.')),
                        ),
                        icon: const Icon(Icons.add_task_rounded, size: 16),
                        label: Text('Schedule Work Order', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prediction dismissed for this view.')),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        side: const BorderSide(color: kSlateBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Dismiss', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MiniInfoChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
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
            Icon(Icons.verified_rounded, size: 72, color: kAccentGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('All Assets Healthy', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('No maintenance risks detected for your society assets.', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
