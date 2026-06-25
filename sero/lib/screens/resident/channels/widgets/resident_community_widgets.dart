import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/community.dart';
import 'package:sero/models/event.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/providers/shared/events_provider.dart';

// --- 1. AI Daily Pulse (Briefing) ---
class DailyPulseWidget extends ConsumerWidget {
  const DailyPulseWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesStreamProvider);
    final pollsAsync = ref.watch(pollsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final directPulseAsync = ref.watch(directPulseProvider);

    String briefing = 'Sero AI is analyzing community activity...';
    bool isDirect = false;

    // DIRECT PULSE PRECEDENCE
    if (directPulseAsync.hasValue && directPulseAsync.value != null) {
      final pulse = directPulseAsync.value!;
      final isRecent = DateTime.now().difference(pulse.createdAt).inHours < 4;
      if (isRecent || pulse.isHighPriority) {
        briefing = pulse.content;
        isDirect = true;
      }
    }
    
    // AI AGGREGATION LOGIC (if no direct pulse or pulse is old)
    if (!isDirect && noticesAsync.hasValue && pollsAsync.hasValue && eventsAsync.hasValue) {
      final notices = noticesAsync.value!;
      final polls = pollsAsync.value!;
      final events = eventsAsync.value!;

      if (notices.isEmpty && polls.isEmpty && events.isEmpty) {
        briefing = 'All quiet in the society today. Use the hub to connect with neighbors!';
      } else {
        final messages = <String>[];
        
        // 1. Latest Notice
        if (notices.isNotEmpty) {
          final latest = notices.first;
          final isRecent = DateTime.now().difference(latest.createdAt).inHours < 24;
          if (isRecent) {
            messages.add('New bulletin: "${latest.title}"');
          }
        }

        // 2. Polls
        if (polls.isNotEmpty) {
          messages.add('${polls.length} community ${polls.length == 1 ? 'poll' : 'polls'} active');
        }

        // 3. Events
        if (events.isNotEmpty) {
          final next = events.first;
          messages.add('Next event: ${next.title}');
        }

        if (messages.isEmpty) {
          briefing = 'Society pulse is steady. Check the channels for active discussions.';
        } else {
          briefing = '${messages.join('. ')}.';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B), // Deep Navy
                    const Color(0xFF334155), // Slate
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kAccentGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: kAccentGreen, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SERO PULSE',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      _buildLiveIndicator(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    briefing,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Shimmer / Shine Effect
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kAccentGreen.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(key: ValueKey(briefing)).fade(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kAccentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAccentGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: kAccentGreen, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).scale(
                duration: 1.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
              ).fadeOut(),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: GoogleFonts.outfit(
              color: kAccentGreen,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. Management / Committee Bar ---
class CommitteeBar extends ConsumerWidget {
  const CommitteeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final committeeAsync = ref.watch(committeeProvider);

    return committeeAsync.when(
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'SOCIETY COUNCIL',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [kPrimaryGreen.withValues(alpha: 0.1), kPrimaryGreen.withValues(alpha: 0.05)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m.name[0],
                            style: GoogleFonts.outfit(color: kPrimaryGreen, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            Text(m.role.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.1);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// --- 3. Poll Card Widget ---
class CommunityPollWidget extends ConsumerWidget {
  final Poll poll;
  const CommunityPollWidget({super.key, required this.poll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curUser = ref.watch(authProvider).value;
    final hasVoted = poll.votedUsers.contains(curUser?.id ?? 'resident-001');
    final totalVotes = poll.votes.values.fold(0, (sum, v) => sum + v);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Icon(Icons.poll_rounded, color: kPrimaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'COLLECTIVE CHOICE',
                style: GoogleFonts.outfit(
                  color: kPrimaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poll.question,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (hasVoted) ...[
            ...List.generate(poll.options.length, (i) {
              final voteCount = poll.votes[i.toString()] ?? 0;
              final percent = totalVotes == 0 ? 0.0 : voteCount / totalVotes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(poll.options[i], style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('${(percent * 100).round()}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(percent > 0.4 ? kPrimaryGreen : kPrimaryBlue),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            ...List.generate(poll.options.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => CommunityActions.voteInPoll(poll.id, i, curUser?.id ?? 'resident-001'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Text(
                    poll.options[i],
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// --- 4. Society Event Card ---
class ResidentEventCard extends StatelessWidget {
  final SocietyEvent event;
  const ResidentEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Color(0xFF8B5CF6), size: 18),
              const SizedBox(width: 8),
              Text(
                'SOCIETY EVENT',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(event.location, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'RSVP Now',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
