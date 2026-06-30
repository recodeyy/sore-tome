import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/widgets/resident/issue_card.dart';

/// My Complaints (design: complain.png screen 2).
///
/// Clean complaints list wired to LIVE data (issuesStreamProvider).
/// Green header, status filter chips with live counts, complaint cards,
/// and a "Raise New Complaint" CTA. Truthful empty/loading/error states —
/// no fabricated rows.
class ResidentIssuesScreen extends ConsumerStatefulWidget {
  const ResidentIssuesScreen({super.key});

  @override
  ConsumerState<ResidentIssuesScreen> createState() => _ResidentIssuesScreenState();
}

class _ResidentIssuesScreenState extends ConsumerState<ResidentIssuesScreen> {
  // 0=All, 1=In Progress, 2=Resolved, 3=Closed
  int _filter = 0;
  static const _filters = ['All', 'In Progress', 'Resolved', 'Closed'];

  bool _matchesFilter(Issue i) {
    switch (_filter) {
      case 1:
        return i.status == 'in_progress' || i.status == 'open';
      case 2:
        return i.status == 'resolved';
      case 3:
        return i.status == 'closed';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: () async => ref.refresh(issuesProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.zero,
          children: [
            _header(context),
            issuesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
              ),
              error: (e, _) => _stateBox(
                Icons.cloud_off_rounded,
                'Could not load complaints',
                '$e'.split('\n').first,
              ),
              data: (all) {
                final filtered = all.where(_matchesFilter).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  children: [
                    _filterChips(all),
                    if (filtered.isEmpty)
                      _stateBox(Icons.inbox_outlined, 'No complaints here',
                          'Complaints you raise will appear in this list.')
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Column(
                          children: filtered
                              .map((i) => IssueCard(issue: i))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 90),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32,
          child: FloatingActionButton.extended(
            heroTag: 'raiseComplaint',
            onPressed: () => Navigator.pushNamed(context, '/post-issue'),
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add_rounded),
            label: Text('Raise New Complaint',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Green header ───────────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryGreen, Color(0xFF0B7A5A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 22),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          Expanded(
            child: Text('My Complaints',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.report_problem_outlined, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Filter chips with live counts ──────────────────────────────────────────
  Widget _filterChips(List<Issue> all) {
    int countFor(int f) {
      switch (f) {
        case 1:
          return all.where((i) => i.status == 'in_progress' || i.status == 'open').length;
        case 2:
          return all.where((i) => i.status == 'resolved').length;
        case 3:
          return all.where((i) => i.status == 'closed').length;
        default:
          return all.length;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final selected = _filter == i;
          return GestureDetector(
            onTap: () => setState(() => _filter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i == _filters.length - 1 ? 0 : 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? kPrimaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: selected ? kPrimaryGreen : kSlateBorder),
              ),
              child: Text(
                '${_filters[i]} (${countFor(i)})',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stateBox(IconData icon, String title, String sub) => Container(
        margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kDeepNavy)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8))),
          ],
        ),
      );
}
