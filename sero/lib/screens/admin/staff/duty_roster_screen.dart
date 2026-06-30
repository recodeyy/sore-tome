import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Duty Roster — upcoming staff duties grouped by date, backed by
/// GET /staff-v2/roster. Read-only view for now (assigning a duty is a
/// separate admin flow against POST /staff-v2/roster).
class DutyRosterScreen extends ConsumerWidget {
  const DutyRosterScreen({super.key});

  static String _fmtShift(Map<String, dynamic> r) {
    final start = r['start_minutes'];
    final end = r['end_minutes'];
    if (start is num && end is num) {
      String hhmm(num m) =>
          '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toInt().toString().padLeft(2, '0')}';
      return '${hhmm(start)}–${hhmm(end)}';
    }
    return (r['shift_name'] ?? 'Shift').toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(dutyRosterProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Duty Roster',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: rosterAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading roster…'),
        error: (e, _) => LiveErrorView(
            error: e, onRetry: () => ref.invalidate(dutyRosterProvider)),
        data: (rows) {
          if (rows.isEmpty) {
            return const LiveEmptyView(
              icon: Icons.calendar_view_day_outlined,
              message: 'No upcoming duties scheduled.',
            );
          }
          // Group by duty_date for readable day headers.
          final byDate = <String, List<Map<String, dynamic>>>{};
          for (final r in rows) {
            final m = r is Map
                ? r.cast<String, dynamic>()
                : <String, dynamic>{};
            final d = (m['duty_date'] ?? '').toString().split('T').first;
            byDate.putIfAbsent(d, () => []).add(m);
          }
          final dates = byDate.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in dates) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(d,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A))),
                ),
                ...byDate[d]!.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: Color(0xFF7C3AED)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((r['staff_name'] ?? 'Staff').toString(),
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700)),
                                if ((r['area'] ?? '').toString().isNotEmpty)
                                  Text(r['area'].toString(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Text(_fmtShift(r),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569))),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
