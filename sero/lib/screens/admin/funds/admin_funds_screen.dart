import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/branding_header.dart';
import 'package:sero/widgets/shared/hero_header.dart';
import 'package:sero/widgets/shared/funds/funds_metrics.dart';
import 'package:sero/widgets/shared/funds/funds_sections.dart';
import 'package:sero/widgets/shared/funds/financial_card.dart';
import 'package:sero/screens/shared/ai_chat/ai_chat_screen.dart';
import 'package:sero/screens/admin/funds/widgets/extraction_form.dart';

class AdminFundsScreen extends ConsumerStatefulWidget {
  const AdminFundsScreen({super.key});

  @override
  ConsumerState<AdminFundsScreen> createState() => _AdminFundsScreenState();
}

class _AdminFundsScreenState extends ConsumerState<AdminFundsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _smartScan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (image != null) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        builder: (context) => Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kPrimaryGreen),
              const SizedBox(height: 24),
              Text('Analyzing Receipt...', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Sero is extracting financial data', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      try {
        final bytes = await image.readAsBytes();
        final res = await ApiService.post('/ai/extract-receipt', {
          'image': base64Encode(bytes), 
        });

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (res.statusCode == 200) {
          _showExtractionResult(jsonDecode(res.body));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Extraction failed: ${res.body}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showExtractionResult(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => ExtractionForm(
        data: data, 
        onConfirm: (tx) async {
          await ref.read(fundsProvider.notifier).addTransaction(tx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(fundSummaryProvider);
    final transactionsAsync = ref.watch(fundsProvider);
    final overdueAsync = ref.watch(overdueResidentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const BrandingHeader(),
          HeroHeader(
            title: 'Estate Treasury',
            label: 'FINANCIAL CONSOLE',
            description: 'Real-time liquidity and arrears tracking. Professional ledger for society fund management.',
            onRefresh: () {
              ref.invalidate(fundSummaryProvider);
              ref.invalidate(fundsProvider);
              ref.invalidate(overdueResidentsProvider);
            },
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: kPrimaryGreen,
                labelColor: kPrimaryGreen,
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'VAULT'),
                  Tab(text: 'LEDGER'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Analytics/Vault
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(fundSummaryProvider);
                ref.invalidate(overdueResidentsProvider);
              },
              color: kPrimaryGreen,
              child: CustomScrollView(
                slivers: [
                  summaryAsync.when(
                    data: (summary) => SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FinancialCard(
                            title: 'Total Collections',
                            amount: '₹${summary.totalCollected.toStringAsFixed(0)}',
                            trend: 'Society Revenue',
                            icon: Icons.account_balance_wallet_rounded,
                            isPositive: true,
                            isHero: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FinancialCard(
                                  title: 'Overdue',
                                  amount: '₹${summary.outstandingDues.toStringAsFixed(0)}',
                                  trend: '${summary.overdueCount} residents',
                                  icon: Icons.assignment_late_rounded,
                                  isNeutral: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FinancialCard(
                                  title: 'Expenses',
                                  amount: '₹${summary.totalSpent.toStringAsFixed(0)}',
                                  trend: 'Last 30 days',
                                  icon: Icons.receipt_long_rounded,
                                  isNeutral: true,
                                ),
                              ),
                            ],
                          ).animate().fade().slideY(begin: 0.2, delay: 200.ms),
                          const SizedBox(height: 24),
                          SpendingBreakdownCard(
                            breakdown: summary.categoryBreakdown,
                            totalSpent: summary.totalSpent,
                          ),
                        ]),
                      ),
                    ),
                    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPrimaryGreen))),
                    error: (e, _) => SliverFillRemaining(child: Center(child: Text('Sync failed: $e'))),
                  ),

                  overdueAsync.when(
                    data: (overdueList) => SliverToBoxAdapter(
                      child: OverdueSection(overdueList: overdueList),
                    ),
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Tab 2: Ledger/Transactions
            RefreshIndicator(
              onRefresh: () async => ref.read(fundsProvider.notifier).fetchTransactions(),
              color: kPrimaryGreen,
              child: CustomScrollView(
                slivers: [
                  transactionsAsync.when(
                    data: (transactions) => SliverPadding(
                      padding: const EdgeInsets.only(top: 10),
                      sliver: SliverToBoxAdapter(
                        child: DisbursementsSection(
                          transactions: transactions,
                          onSmartScan: _smartScan,
                          onManualLog: () => _showExtractionResult({}),
                        ),
                      ),
                    ),
                    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPrimaryGreen))),
                    error: (e, _) => SliverFillRemaining(child: Center(child: Text('Ledger sync failed: $e'))),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatScreen(
                    initialMessage: 'Analyze my expenses and detect anomalies',
                    initialContext: {'screen': 'funds'},
                    userRole: 'admin',
                  ),
                ),
              );
            },
            backgroundColor: kPrimaryGreen,
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'scan_fab',
            onPressed: _smartScan,
            backgroundColor: kDeepNavy,
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
