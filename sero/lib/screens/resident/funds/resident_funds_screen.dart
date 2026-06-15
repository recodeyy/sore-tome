import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/fund.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/widgets/shared/funds/financial_card.dart';
import 'package:sero/widgets/shared/funds/funds_sections.dart';
import 'package:sero/widgets/shared/funds/funds_metrics.dart';
import 'package:sero/widgets/shared/branding_header.dart';
import 'package:sero/widgets/shared/hero_header.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class ResidentFundsScreen extends ConsumerStatefulWidget {
  const ResidentFundsScreen({super.key});

  @override
  ConsumerState<ResidentFundsScreen> createState() => _ResidentFundsScreenState();
}

class _ResidentFundsScreenState extends ConsumerState<ResidentFundsScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(residentBalanceProvider);
    final summaryAsync = ref.watch(fundSummaryProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const BrandingHeader(),
          HeroHeader(
            title: 'Society Treasury',
            label: 'FINANCIAL TRANSPARENCY',
            description: 'Real-time visibility into society funds and your contributions. Trust is built through accountability.',
            onRefresh: () {
              ref.invalidate(residentBalanceProvider);
              ref.invalidate(fundSummaryProvider);
            },
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(residentBalanceProvider);
            ref.invalidate(fundSummaryProvider);
          },
          color: kPrimaryGreen,
          child: CustomScrollView(
            slivers: [
              // --- PERSONAL STATUS SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Your Contribution'),
                      const SizedBox(height: 12),
                      balanceAsync.when(
                        data: (balance) => FinancialCard(
                          title: 'Payment Status',
                          amount: balance > 0 ? '₹${balance.toStringAsFixed(0)} Due' : 'All Clear',
                          trend: balance > 0 ? 'Pending Maintenance' : 'Fees Paid for April',
                          icon: balance > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          isHero: true,
                          isPositive: balance <= 0,
                          isNeutral: balance > 0,
                        ),
                        loading: () => const _CardPlaceholder(),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SOCIETY WELLNESS SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Society Financial Health'),
                      const SizedBox(height: 12),
                      summaryAsync.when(
                        data: (summary) => Row(
                          children: [
                            Expanded(
                              child: FinancialCard(
                                title: 'Total Collected',
                                amount: '₹${summary.totalCollected.toStringAsFixed(0)}',
                                trend: 'Society Revenue',
                                icon: Icons.account_balance_rounded,
                                isPositive: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FinancialCard(
                                title: 'Remaining',
                                amount: '₹${summary.remaining.toStringAsFixed(0)}',
                                trend: '${summary.percentRemaining.toStringAsFixed(1)}% Reserve',
                                icon: Icons.savings_rounded,
                                isPositive: true,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Row(children: [Expanded(child: _CardPlaceholder()), SizedBox(width: 16), Expanded(child: _CardPlaceholder())]),
                        error: (e, _) => const SizedBox.shrink(),
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      summaryAsync.when(
                        data: (summary) => SpendingBreakdownCard(
                          breakdown: summary.categoryBreakdown,
                          totalSpent: summary.totalSpent,
                        ),
                        loading: () => const _CardPlaceholder(height: 180),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // --- TRANSPARENCY LEDGER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _sectionLabel('Transparency Ledger'),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FundTransaction>>(
                        stream: _service.getTransactionsStream(ref.watch(authProvider).value?.societyId ?? ''),
                        builder: (context, snapshot) {
                          return DisbursementsSection(
                            transactions: snapshot.data ?? [],
                            isResidentView: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  final double height;
  const _CardPlaceholder({this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen)),
    );
  }
}
