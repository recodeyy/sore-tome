import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/resident/issue_card.dart';
import '../../shared/ai_chat/ai_chat_screen.dart';

import 'package:sero/widgets/shared/branding_header.dart';
// Modularized Widgets
import 'widgets/issues_widgets.dart';
import 'widgets/support_specialized_widgets.dart';

class ResidentIssuesScreen extends ConsumerStatefulWidget {
  const ResidentIssuesScreen({super.key});

  @override
  ConsumerState<ResidentIssuesScreen> createState() => _ResidentIssuesScreenState();
}

class _ResidentIssuesScreenState extends ConsumerState<ResidentIssuesScreen> {
  int _selectedFilter = 0; // 0=All, 1=Open, 2=Resolved
  final _filters = ['All', 'Open', 'Resolved'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showMyIssuesOnly = false;
  
  // SUPPORT HUB STATE
  int _activeService = 0; // 0=Maintenance, 1=Reservations, 2=Governance
  final List<Map<String, dynamic>> _services = [
    {'label': 'Repairs', 'icon': Icons.handyman_rounded, 'color': kPrimaryGreen},
    {'label': 'Booking', 'icon': Icons.event_available_rounded, 'color': kPrimaryBlue},
    {'label': 'Records', 'icon': Icons.history_edu_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

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
    final issuesAsync = ref.watch(issuesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async => ref.refresh(issuesStreamProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const BrandingHeader(),
            ResidentIssuesHero(
              onNewTicketTap: () => Navigator.pushNamed(context, '/post-issue'),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
            ),

            // --- SUPPORT HUB TRIAGE ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: List.generate(_services.length, (i) {
                    final isSelected = _activeService == i;
                    final service = _services[i];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeService = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? service['color'].withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? service['color'] : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                service['icon'],
                                color: isSelected ? service['color'] : const Color(0xFF94A3B8),
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service['label'],
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? service['color'] : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            if (_activeService == 0) ...[
              issuesAsync.when(
                data: (all) {
                  final open = all.where((i) => i.status == 'open').toList();
                  final inProgress = all.where((i) => i.status == 'in_progress').toList();

                  return SocietyHealthMonitor(
                    openCount: open.length,
                    inProgressCount: inProgress.length,
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              issuesAsync.when(
                data: (all) {
                  final filteredByCategory = all.where((issue) {
                    // 1. Filter by User (My Issues)
                    if (_showMyIssuesOnly) {
                      final isPersonal = issue.postedBy.toLowerCase().contains('you') || 
                                       issue.postedBy.toLowerCase().contains('self') ||
                                       issue.postedBy.toLowerCase() == 'resident-001'; 
                      if (!isPersonal) return false;
                    }

                    // 2. Filter by Status
                    if (_selectedFilter == 1 && issue.status != 'open') return false;
                    if (_selectedFilter == 2 && issue.status != 'resolved') return false;

                    // 3. Filter by Search Query
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      if (!issue.title.toLowerCase().contains(query) && 
                          !issue.description.toLowerCase().contains(query)) {
                        return false;
                      }
                    }

                    // 4. Filter by Category
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
                      final isMajor = content.contains('plumb') || content.contains('gate') || 
                                      content.contains('parking') || content.contains('clean') ;
                      return !isMajor;
                    }
                    return true;
                  }).toList();

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
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
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(30),
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

                        if (index == 1) {
                           return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _showMyIssuesOnly = !_showMyIssuesOnly),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _showMyIssuesOnly ? kPrimaryGreen.withValues(alpha: 0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _showMyIssuesOnly ? kPrimaryGreen : const Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _showMyIssuesOnly ? Icons.person_rounded : Icons.person_outline_rounded,
                                          size: 16,
                                          color: _showMyIssuesOnly ? kPrimaryGreen : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'My Reports',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _showMyIssuesOnly ? kPrimaryGreen : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: selected ? const Color(0xFF0F172A) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _filters[i],
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: selected ? Colors.white : const Color(0xFF94A3B8),
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

                        // Items logic (Index 2 onwards)
                        final itemsCount = filteredByCategory.isEmpty ? 1 : filteredByCategory.length;
                        final itemsIndex = index - 2;

                        // Check if we are at the spacer (the absolute last item)
                        if (itemsIndex == itemsCount) {
                          return const SizedBox(height: 160); // Permanent safe-zone
                        }

                        // Content (Empty State OR Cards)
                        if (filteredByCategory.isEmpty) {
                          return const IssuesEmptyState();
                        }

                        if (itemsIndex < filteredByCategory.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 1),
                            child: IssueCard(issue: filteredByCategory[itemsIndex])
                                .animate()
                                .fade(delay: (itemsIndex * 40).ms)
                                .slideY(begin: 0.05, end: 0),
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
                      // 2 headers + (1 empty state OR N cards) + 1 bottom spacer
                      childCount: 2 + (filteredByCategory.isEmpty ? 1 : filteredByCategory.length) + 1,
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
                            onPressed: () => ref.refresh(issuesStreamProvider),
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

            if (_activeService == 1) ...[
              const ReservationView(),
            ],

            if (_activeService == 2) ...[
              const RecordsView(),
            ],
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
                userRole: 'resident',
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









