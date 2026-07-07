import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/shared/events_provider.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident Events — upcoming society events from the canonical Postgres
/// `/events-v2` endpoint (e.g. Diwali Celebration). Read-only for residents.
class ResidentEventsScreen extends ConsumerWidget {
  const ResidentEventsScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Events',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventsProvider.notifier).fetchEvents(),
        child: async.when(
          loading: () => const LiveLoadingView(label: 'Loading events…'),
          error: (e, _) => LiveErrorView(
              error: e,
              onRetry: () => ref.read(eventsProvider.notifier).fetchEvents()),
          data: (events) {
            if (events.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                LiveEmptyView(
                  icon: Icons.celebration_outlined,
                  message: 'No upcoming events.',
                ),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final e = events[i];
                final d = e.eventDate;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Column(
                          children: [
                            Text('${d.day}',
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF059669))),
                            Text(_months[(d.month - 1).clamp(0, 11)],
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B))),
                            if (e.location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(e.location,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B))),
                                ),
                              ]),
                            ],
                            if (e.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(e.description,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
