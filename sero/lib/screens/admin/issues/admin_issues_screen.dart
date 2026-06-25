import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/widgets/admin/issue_card.dart';
import '../../shared/ai_chat/ai_chat_screen.dart';

import 'package:sero/widgets/shared/branding_header.dart';
// Modularized Widgets
import 'widgets/issues_widgets.dart';

class AdminIssuesScreen extends ConsumerStatefulWidget {
  const AdminIssuesScreen({super.key});

  @override
  ConsumerState<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends ConsumerState<AdminIssuesScreen> {
  int _selectedFilter = 0; // 0=All, 1=Open, 2=Resolved
  final _filters = ['All', 'Open', 'Resolved'];
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Maintenance',
    'Security',
    'Parking',
    'Cleanliness',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () => ref.read(issuesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            const BrandingHeader(),
            IssuesHero(
              onNewTicketTap: () => Navigator.pushNamed(context, '/post-issue'),
            ),

            issuesAsync.when(
              data: (all) {
                final open = all.where((i) => i.status == 'open').toList();
                final inProgress = all.where((i) => i.status == 'in_progress').toList();
                final resolved = all.where((i) => i.status == 'resolved').toList();

                List<Issue> filtered;
                switch (_selectedFilter) {
                  case 1:
                    filtered = open;
                    break;
                  case 2:
                    filtered = resolved;
                    break;
                  default:
                    filtered = all;
                }

                final filteredByCategory = filtered.where((issue) {
                  if (_selectedCategory == 'All') return true;
                  
                  final content = '${issue.title} ${issue.description}'.toLowerCase();
                  
                  if (_selectedCategory == 'Maintenance') {
                    return content.contains('plumb') || content.contains('leak') || 
                           content.contains('repair') || content.contains('fix') || 
                           content.contains('electric') || content.contains('water') || 
                           content.contains('lift') || content.contains('maintenance');
                  }
                  if (_selectedCategory == 'Security') {
                    return content.contains('gate') || content.contains('guard') || 
                           content.contains('security') || content.contains('cctv') || 
                           content.contains('thief') || content.contains('entry');
                  }
                  if (_selectedCategory == 'Parking') {
                    return content.contains('parking') || content.contains('vehicle') || 
                           content.contains('car') || content.contains('bike') || 
                           content.contains('slot');
                  }
                  if (_selectedCategory == 'Cleanliness') {
                    return content.contains('clean') || content.contains('garbage') || 
                           content.contains('waste') || content.contains('smell') || 
                           content.contains('litter');
                  }
                  if (_selectedCategory == 'Others') {
                    // Not matching major keywords
                    final isMajor = content.contains('plumb') || content.contains('gate') || 
                                    content.contains('parking') || content.contains('clean') ;
                    return !isMajor;
                  }
                  return true;
                }).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // 1: Stats Row
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Column(
                            children: [
                              StatRow(
                                label: 'UNASSIGNED',
                                value: open.length.toString().padLeft(2, '0'),
                                underlineColor: const Color(0xFFEF4444),
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              StatRow(
                                label: 'IN PROGRESS',
                                value: inProgress.length.toString().padLeft(2, '0'),
                                underlineColor: const Color(0xFF3B82F6),
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              StatRow(
                                label: 'RESOLVED (TODAY)',
                                value: resolved.length.toString().padLeft(2, '0'),
                                underlineColor: kAccentGreen,
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              StatRow(
                                label: 'TOTAL TICKETS',
                                value: all.length.toString().padLeft(2, '0'),
                                underlineColor: const Color(0xFF8B5CF6),
                                subtitle: 'Across all statuses',
                              ),
                            ],
                          ).animate().fade(delay: 150.ms),
                        );
                      }

                      // 2: Categories Scroller
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORIES',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _categories.map((cat) {
                                    final isSelected = _selectedCategory == cat;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedCategory = cat),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? kPrimaryGreen
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: isSelected 
                                                ? kPrimaryGreen 
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 180.ms);
                      }

                      // 3: Filter Labels
                      if (index == 2) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ACTIVE TICKETS',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: List.generate(_filters.length, (i) {
                                  final selected = _selectedFilter == i;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedFilter = i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? kPrimaryGreen
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _filters[i],
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 200.ms);
                      }

                      if (filteredByCategory.isEmpty) {
                        return const IssuesEmptyState();
                      }

                      final issueIndex = index - 3; // Shifted by 3 (Stats, Categories, Filters)
                      if (issueIndex < filteredByCategory.length) {
                        final i = issueIndex;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 1),
                          child: IssueCard(issue: filteredByCategory[i])
                              .animate()
                              .fade(delay: (i * 40).ms, duration: 250.ms)
                              .slideY(begin: 0.05, end: 0),
                        );
                      }

                      // Bottom Spacer
                      if (issueIndex == filteredByCategory.length) {
                         return const SizedBox(height: 100);
                      }

                      return null;
                    },
                    childCount: 3 + (filteredByCategory.isEmpty ? 1 : filteredByCategory.length + 1),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: kPrimaryGreen, strokeWidth: 2),
                ),
              ),
              error: (err, st) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Sync Error: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref.read(issuesProvider.notifier).refresh(),
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
                          child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: kPillNavbarFabLocation,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatScreen(
                initialMessage: 'Summarize current complaints and suggest actions',
                initialContext: {'screen': 'issues'},
                userRole: 'admin',
              ),
            ),
          );
        },
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }
}









