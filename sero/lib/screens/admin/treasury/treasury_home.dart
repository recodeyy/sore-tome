import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/shared/funds_provider.dart';
import '../../../models/fund.dart';
import '../../../app/theme.dart';
import '../../../widgets/shared/shimmer_skeleton.dart';

class TreasuryHome extends ConsumerStatefulWidget {
  const TreasuryHome({super.key});

  @override
  ConsumerState<TreasuryHome> createState() => _TreasuryHomeState();
}

class _TreasuryHomeState extends ConsumerState<TreasuryHome> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(fundSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Financial Overview',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: kPrimaryGreen),
            onPressed: () => _showScanReceiptDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(fundSummaryProvider);
            ref.invalidate(overdueResidentsProvider);
            ref.invalidate(fundsProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainBalanceCard(summary),
                const SizedBox(height: 24),
                _buildDefaultersSection(),
                const SizedBox(height: 32),
                _buildRecentLedger(),
              ],
            ),
          ),
        ),
        loading: () => const _LoadingDashboard(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('RECORD', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildMainBalanceCard(FundSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SOCIETY BALANCE',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${summary.totalCollected - summary.totalSpent}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _balanceSmallItem('Collected', '₹${summary.totalCollected}', Colors.greenAccent),
              const Spacer(),
              _balanceSmallItem('Spent', '₹${summary.totalSpent}', Colors.redAccent),
              const Spacer(),
              _balanceSmallItem('Outstanding', '₹${summary.outstandingDues}', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _balanceSmallItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDefaultersSection() {
    final overdueAsync = ref.watch(overdueResidentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENDING DUES',
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        overdueAsync.when(
          data: (residents) {
            if (residents.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: kPrimaryGreen),
                    SizedBox(width: 12),
                    Text('All maintenance accounts clear!'),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: residents.length,
                itemBuilder: (context, index) {
                  final r = residents[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(r.unitInfo, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${r.amountOwed}', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.redAccent)),
                            const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
                },
              ),
            );
          },
          loading: () => const ShimmerSkeleton(height: 130, width: double.infinity),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildRecentLedger() {
    final txAsync = ref.watch(fundsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT LEDGER',
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        txAsync.when(
          data: (txs) {
            if (txs.isEmpty) return const Center(child: Text('No transactions recorded'));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length > 10 ? 10 : txs.length,
              itemBuilder: (context, index) {
                final tx = txs[index];
                final isCredit = tx.isCredit;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(tx.category, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? "+" : "-"}₹${tx.amount}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Column(
            children: [
              ShimmerSkeleton(height: 70, width: double.infinity),
              SizedBox(height: 12),
              ShimmerSkeleton(height: 70, width: double.infinity),
            ],
          ),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  void _showScanReceiptDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Receipt Scanning: Please select a receipt image from gallery.')),
    );
    // Integration with ImagePicker and ApiService.post('/ai/extract-receipt') would go here
  }

  void _showSettingsDialog(BuildContext context) {
     // Implementation for updating target and maintenance fee
  }

  void _showAddTransactionDialog(BuildContext context) {
     // Implementation for adding manual transactions (e.g. expenses)
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ShimmerSkeleton(height: 200, width: double.infinity),
          SizedBox(height: 24),
          ShimmerSkeleton(height: 130, width: double.infinity),
        ],
      ),
    );
  }
}
