import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'rules_cards.dart';
import 'package:sero/providers/shared/ai_provider.dart';
import 'package:sero/providers/shared/rules_provider.dart';
import 'package:sero/app/theme.dart';

class GovernanceRulesListView extends ConsumerWidget {
  final String selectedCategory;
  const GovernanceRulesListView({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiRulesAsync = ref.watch(aiRulesProvider);
    final manualRulesAsync = ref.watch(rulesProvider);

    return aiRulesAsync.when(
      data: (aiRules) {
        return manualRulesAsync.when(
          data: (manualRules) {
            // V3.12: Intelligent Unified Filtering Logic
            final allRules = [
              ...aiRules.map((r) => {
                'id': 'ai_${r['source']}',
                'title': 'Society Protocol',
                'content': r['rule'],
                'date': r['date'],
                'section': 'AI ASSISTED',
              }),
              ...manualRules.map((r) => {
                'id': r.id,
                'title': r.title,
                'content': r.content,
                'date': null,
                'section': 'ADMIN DRAFT',
              }),
            ];

            final filtered = allRules.where((r) {
              final combinedContent = '${r['title'] ?? ''} ${r['content'] ?? ''}'.toLowerCase();
              
              if (selectedCategory == 'General Conduct') return true;

              bool matchesCategory = false;
              if (selectedCategory == 'Parking & Transit') {
                matchesCategory = combinedContent.contains('parking') || combinedContent.contains('vehicle') || 
                                  combinedContent.contains('car') || combinedContent.contains('bike') || 
                                  combinedContent.contains('slot') || combinedContent.contains('garage') || 
                                  combinedContent.contains('driveway');
              }
              else if (selectedCategory == 'Pet Policy') {
                matchesCategory = combinedContent.contains('pet') || combinedContent.contains('animal') || 
                                  combinedContent.contains('dog') || combinedContent.contains('cat') || 
                                  combinedContent.contains('leash');
              }
              else if (selectedCategory == 'Facility Usage') {
                matchesCategory = combinedContent.contains('clubhouse') || combinedContent.contains('gym') || 
                                  combinedContent.contains('pool') || combinedContent.contains('hall') || 
                                  combinedContent.contains('garden') || combinedContent.contains('amenity') || 
                                  combinedContent.contains('usage');
              }
              else if (selectedCategory == 'Waste & Eco') {
                matchesCategory = combinedContent.contains('waste') || combinedContent.contains('garbage') || 
                                  combinedContent.contains('trash') || combinedContent.contains('recycle') || 
                                  combinedContent.contains('litter');
              }
              
              return matchesCategory;
            }).toList();

            if (filtered.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No protocols indexed for $selectedCategory.',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try checking another category or sync bylaws.',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final rule = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RuleSheetCard(
                      title: rule['title'] ?? 'Society Protocol',
                      section: rule['section'] ?? 'AI V3.12 CLS',
                      lastUpdated: rule['date'] != null 
                        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(rule['date']))
                        : 'Admin Verified Knowledge',
                      content: rule['content'],
                      penalty: 'Subject to committee sanctions as per standard bylaws.',
                    ),
                  );
                }, childCount: filtered.length),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: SizedBox()), 
          error: (e, stack) => SliverToBoxAdapter(child: Center(child: Text('Manual data unavailable: $e'))),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: const Center(
            child: CircularProgressIndicator(color: kPrimaryGreen, strokeWidth: 2),
          ),
        ),
      ),
      error: (e, stack) => SliverToBoxAdapter(child: Center(child: Text('AI extraction failure: $e'))),
    );
  }
}







