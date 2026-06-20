import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'dart:convert';

final financialAnomaliesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService.get('/ai/financial-anomalies');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['anomalies'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load anomalies');
});

class FinancialAnomalyScreen extends ConsumerWidget {
  const FinancialAnomalyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(financialAnomaliesProvider);

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
                    colors: [Color(0xFF92400E), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Financial Anomaly Radar', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('AI-powered leakage & duplicate detection', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
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
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.gavel_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI flags patterns for human review only. No fraud accusations are made. All findings require treasurer verification before action.',
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF78350F), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  anomaliesAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
                    error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(financialAnomaliesProvider)),
                    data: (anomalies) => anomalies.isEmpty
                        ? _CleanFinancials()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${anomalies.length} Item${anomalies.length == 1 ? '' : 's'} Flagged',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Requires Review', style: GoogleFonts.outfit(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...anomalies.asMap().entries.map((entry) =>
                                _AnomalyCard(anomaly: entry.value, index: entry.key)
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: entry.key * 80))
                                    .slideY(begin: 0.04)
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

class _AnomalyCard extends StatelessWidget {
  final Map<String, dynamic> anomaly;
  final int index;
  const _AnomalyCard({required this.anomaly, required this.index});

  Color get _severityColor {
    switch (anomaly['severity']) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orange;
      default: return Colors.amber;
    }
  }

  IconData get _typeIcon {
    switch (anomaly['type']) {
      case 'duplicate_invoice': return Icons.content_copy_rounded;
      case 'unusual_expense': return Icons.trending_up_rounded;
      case 'utility_spike': return Icons.electric_bolt_rounded;
      case 'budget_overrun': return Icons.account_balance_wallet_outlined;
      case 'suspicious_adjustment': return Icons.edit_note_rounded;
      default: return Icons.warning_amber_rounded;
    }
  }

  String get _typeLabel {
    switch (anomaly['type']) {
      case 'duplicate_invoice': return 'Duplicate Invoice';
      case 'unusual_expense': return 'Unusual Expense';
      case 'utility_spike': return 'Utility Spike';
      case 'budget_overrun': return 'Budget Overrun';
      case 'suspicious_adjustment': return 'Suspicious Adjustment';
      default: return 'Anomaly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (anomaly['amount'] ?? 0) as num;
    final confidence = ((anomaly['confidence'] ?? 0.0) as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _severityColor.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_typeIcon, color: _severityColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_typeLabel, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _severityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text((anomaly['severity'] ?? '').toString().toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    Text(
                      '${(confidence * 100).toInt()}% confidence',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  anomaly['whyFlagged'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                ),
                if (anomaly['recommendedAction'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: kPrimaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            anomaly['recommendedAction'],
                            style: GoogleFonts.outfit(fontSize: 12, color: kPrimaryGreen, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Flagged for review. (Saving review status needs a backend endpoint.)')),
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: Text('Mark for Review', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Anomaly dismissed for this view.')),
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

class _CleanFinancials extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, size: 72, color: kAccentGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Financials Look Healthy', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('No anomalies detected in your financial records this month.', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.cloud_off_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text('Could not load anomaly scan', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
