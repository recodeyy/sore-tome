import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/status_badge.dart';

class MeetingsDashboardScreen extends ConsumerWidget {
  const MeetingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societyId = ref.watch(authProvider).value?.societyId ?? '';
    final meetingsAsync = ref.watch(meetingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kPremiumGradient),
        ),
        title: Text(
          'Meetings & AGM',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMeeting(context, societyId),
        backgroundColor: kPrimaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Meeting',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.outfit())),
        data: (meetings) {
          final scheduled =
              meetings.where((m) => m.status == 'scheduled').length;
          final completed =
              meetings.where((m) => m.status == 'completed').length;
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
                      value: scheduled.toString(),
                      label: 'Scheduled',
                      icon: Icons.groups_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      iconBgColor: const Color(0xFFF3E8FF),
                    ),
                    StatCard(
                      value: completed.toString(),
                      label: 'Completed',
                      icon: Icons.task_alt,
                      iconColor: const Color(0xFF059669),
                      iconBgColor: const Color(0xFFD1FAE5),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: SectionHeader(title: 'All Meetings (${meetings.length})'),
              ),
              if (meetings.isEmpty)
                SliverToBoxAdapter(child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _MeetingCard(meeting: meetings[i]),
                      childCount: meetings.length,
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
              const Icon(Icons.groups_2_outlined,
                  color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text('No meetings scheduled. Plan an AGM or committee meeting.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            ],
          ),
        ),
      );

  void _showCreateMeeting(BuildContext context, String societyId) {
    final titleController = TextEditingController();
    final agendaController = TextEditingController();
    String type = 'Committee';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

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
              Text('Schedule Meeting',
                  style:
                      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(hintText: 'Meeting Title')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Committee', 'AGM', 'Emergency'].map((t) {
                  final selected = type == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) => setModalState(() => type = t),
                    selectedColor: kPrimaryGreen.withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.outfit(
                      color: selected ? kPrimaryGreen : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: agendaController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Agenda...')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                    'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: GoogleFonts.outfit()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await CommunityActions.createMeeting(
                      title: titleController.text,
                      type: type,
                      agenda: agendaController.text,
                      date: selectedDate,
                      societyId: societyId,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Center(child: Text('Schedule Meeting')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(meeting.type.toUpperCase(),
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED))),
                ),
                const Spacer(),
                _statusBadge(meeting.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(meeting.title,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                    '${meeting.date.day}/${meeting.date.month}/${meeting.date.year}',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: const Color(0xFF94A3B8))),
              ],
            ),
            if (meeting.agenda.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(meeting.agenda,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _statusBadge(String status) {
    switch (status) {
      case 'completed':
        return StatusBadge(
            label: 'Completed',
            bgColor: const Color(0xFFD1FAE5),
            textColor: const Color(0xFF059669));
      case 'cancelled':
        return const StatusBadge(
            label: 'Cancelled',
            bgColor: Color(0xFFFEE2E2),
            textColor: Color(0xFFDC2626));
      default:
        return const StatusBadge(
            label: 'Scheduled',
            bgColor: Color(0xFFEFF6FF),
            textColor: Color(0xFF2563EB));
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(meeting.title,
                      style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                _statusBadge(meeting.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${meeting.type} • ${meeting.date.day}/${meeting.date.month}/${meeting.date.year}',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF64748B))),
            const SizedBox(height: 16),
            Text('Agenda',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(meeting.agenda.isEmpty ? 'No agenda provided.' : meeting.agenda,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF334155))),
            const SizedBox(height: 24),
            if (meeting.status == 'scheduled')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await CommunityActions.setMeetingStatus(
                            meeting.id, 'completed');
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Center(child: Text('Mark Completed')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await CommunityActions.setMeetingStatus(
                            meeting.id, 'cancelled');
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626)),
                      child: const Center(child: Text('Cancel')),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
