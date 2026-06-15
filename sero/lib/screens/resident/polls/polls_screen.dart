import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/community.dart';

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Community Polls',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_vote_outlined,
                      size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  Text('No active polls',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8), fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: polls.length,
            itemBuilder: (context, index) =>
                _PollCard(poll: polls[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PollCard extends ConsumerStatefulWidget {
  final Poll poll;
  const _PollCard({required this.poll});

  @override
  ConsumerState<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<_PollCard> {
  String? selectedOption;
  bool isVoting = false;
  bool hasVoted = false;

  Future<void> _castVote() async {
    if (selectedOption == null || isVoting) return;
    setState(() => isVoting = true);

    try {
      final res = await ApiService.post(
        '/polls/${widget.poll.id}/vote',
        {'option': selectedOption},
      );
      if (res.statusCode == 200) {
        setState(() => hasVoted = true);
        ref.invalidate(pollsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Vote cast successfully!'),
              backgroundColor: kPrimaryGreen,
            ),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Voting failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes =
        widget.poll.votes.values.fold<int>(0, (sum, count) => sum + count);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.poll.isActive
                      ? kPrimaryGreen.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.poll.isActive ? 'ACTIVE' : 'CLOSED',
                  style: GoogleFonts.outfit(
                    color: widget.poll.isActive ? kPrimaryGreen : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
                style:
                    GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.poll.question,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Options from List<String> using votes Map
          ...widget.poll.options.map((option) {
            final voteCount = widget.poll.votes[option] ?? 0;
            final percent =
                totalVotes > 0 ? voteCount / totalVotes : 0.0;
            final isSelected = selectedOption == option;

            return GestureDetector(
              onTap: hasVoted || !widget.poll.isActive
                  ? null
                  : () => setState(() => selectedOption = option),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kPrimaryGreen.withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? kPrimaryGreen
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? kPrimaryGreen
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (hasVoted)
                          Text(
                            '${(percent * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                fontSize: 12),
                          ),
                      ],
                    ),
                    if (hasVoted) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor:
                            Colors.grey.withValues(alpha: 0.15),
                        color: kPrimaryGreen,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          if (!hasVoted && widget.poll.isActive) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedOption == null || isVoting ? null : _castVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isVoting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('CAST VOTE',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
