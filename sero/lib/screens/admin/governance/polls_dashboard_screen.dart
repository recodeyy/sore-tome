import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/community.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/common/async_state_views.dart';

class PollsDashboardScreen extends ConsumerWidget {
  const PollsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societyId = ref.watch(authProvider).value?.societyId ?? '';
    final pollsAsync = ref.watch(allPollsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Polls',
          style: GoogleFonts.outfit(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePoll(context, societyId),
        backgroundColor: kPrimaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Poll',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: pollsAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading polls...'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(allPollsProvider),
        ),
        data: (polls) {
          final active = polls.where((p) => p.isActive).length;
          final closed = polls.length - active;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      value: active.toString(),
                      label: 'Open Polls',
                      icon: Icons.how_to_vote_outlined,
                      iconColor: const Color(0xFF059669),
                      iconBgColor: const Color(0xFFD1FAE5),
                    ),
                    StatCard(
                      value: closed.toString(),
                      label: 'Closed Polls',
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFF64748B),
                      iconBgColor: const Color(0xFFF1F5F9),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: SectionHeader(title: 'All Polls (${polls.length})'),
              ),
              if (polls.isEmpty)
                SliverToBoxAdapter(child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PollCard(poll: polls[i]),
                      childCount: polls.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.poll_outlined, color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text('No polls yet. Create one to gather opinions.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            ],
          ),
        ),
      );

  void _showCreatePoll(BuildContext context, String societyId) {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Community Poll',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(hintText: 'Ask a question...'),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                optionControllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: optionControllers[i],
                    decoration: InputDecoration(hintText: 'Option ${i + 1}'),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setModalState(() => optionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final options = optionControllers
                      .map((c) => c.text)
                      .where((t) => t.isNotEmpty)
                      .toList();
                  if (questionController.text.isNotEmpty && options.length >= 2) {
                    CommunityActions.createPoll(
                        questionController.text, options, societyId);
                    Navigator.pop(context);
                  }
                },
                child: const Center(child: Text('Launch Poll')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context) {
    final totalVotes =
        poll.votes.values.fold<int>(0, (sum, v) => sum + v);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              poll.isActive
                  ? StatusBadge.active()
                  : const StatusBadge(
                      label: 'Closed',
                      bgColor: Color(0xFFF1F5F9),
                      textColor: Color(0xFF64748B),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$totalVotes votes cast',
              style: GoogleFonts.outfit(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          ...List.generate(poll.options.length, (i) {
            final count = poll.votes[i.toString()] ?? 0;
            final pct = totalVotes == 0 ? 0.0 : count / totalVotes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(poll.options[i],
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155))),
                      ),
                      Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor:
                          const AlwaysStoppedAnimation(kAccentGreen),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  CommunityActions.setPollActive(poll.id, !poll.isActive),
              icon: Icon(
                  poll.isActive ? Icons.lock_outline : Icons.lock_open_outlined,
                  size: 16),
              label: Text(poll.isActive ? 'Close Poll' : 'Reopen Poll',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
