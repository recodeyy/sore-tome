import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/event.dart';
import 'package:sero/providers/shared/events_provider.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/section_header.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/common/async_state_views.dart';

class EventsDashboardScreen extends ConsumerWidget {
  const EventsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kPremiumGradient),
        ),
        title: Text(
          'Events',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEvent(context, ref),
        backgroundColor: kPrimaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Event',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: eventsAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading events...'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(eventsProvider),
        ),
        data: (events) {
          final now = DateTime.now();
          final upcoming = events.where((e) => e.eventDate.isAfter(now)).length;
          final past = events.length - upcoming;
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
                      value: upcoming.toString(),
                      label: 'Upcoming Events',
                      icon: Icons.event_available_outlined,
                      iconColor: const Color(0xFF2563EB),
                      iconBgColor: const Color(0xFFEFF6FF),
                    ),
                    StatCard(
                      value: past.toString(),
                      label: 'Past Events',
                      icon: Icons.history,
                      iconColor: const Color(0xFF64748B),
                      iconBgColor: const Color(0xFFF1F5F9),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: SectionHeader(title: 'All Events (${events.length})'),
              ),
              if (events.isEmpty)
                SliverToBoxAdapter(child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) =>
                          _EventCard(event: events[i], ref: ref),
                      childCount: events.length,
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
              const Icon(Icons.event_busy_outlined,
                  color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text('No events scheduled yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            ],
          ),
        ),
      );

  void _showCreateEvent(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

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
              Text('Create Event',
                  style:
                      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Event Title')),
              const SizedBox(height: 12),
              TextField(
                  controller: locController,
                  decoration: const InputDecoration(hintText: 'Location')),
              const SizedBox(height: 12),
              TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(hintText: 'Brief description...')),
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
                    try {
                      await ref.read(eventsProvider.notifier).addEvent(
                            titleController.text,
                            descController.text,
                            selectedDate,
                            locController.text,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: const Center(child: Text('Post Event')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SocietyEvent event;
  final WidgetRef ref;
  const _EventCard({required this.event, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = event.eventDate.isAfter(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(
                  '${event.location.isEmpty ? 'TBA' : event.location} • ${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              isUpcoming
                  ? StatusBadge(
                      label: 'Upcoming',
                      bgColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF2563EB))
                  : const StatusBadge(
                      label: 'Past',
                      bgColor: Color(0xFFF1F5F9),
                      textColor: Color(0xFF64748B)),
              IconButton(
                onPressed: () => _confirmCancel(context),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFDC2626)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Event',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Remove "${event.title}"? This cannot be undone.',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(eventsProvider.notifier).deleteEvent(event.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Cancel Event',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
