import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_staff_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Mark Attendance — lists every staff member and lets an admin check them in
/// or out for today via POST /staff-v2/attendance/check-in|check-out.
///
/// This is the admin counterpart to the guard's staff check-in on GuardHome:
/// admins reconcile attendance from the office, guards do it at the gate. Both
/// hit the same backend, so the staff dashboard's "Present Today" stays in sync.
class MarkAttendanceScreen extends ConsumerWidget {
  const MarkAttendanceScreen({super.key});

  static String _today() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Mark Attendance',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: staffAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading staff…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(staffListProvider),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return const LiveEmptyView(
              icon: Icons.badge_outlined,
              message: 'No staff registered yet. Add staff first.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = staff[i] is Map
                  ? (staff[i] as Map).cast<String, dynamic>()
                  : <String, dynamic>{};
              return _AttendanceTile(staff: m, workDate: _today());
            },
          );
        },
      ),
    );
  }
}

class _AttendanceTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> staff;
  final String workDate;
  const _AttendanceTile({required this.staff, required this.workDate});

  @override
  ConsumerState<_AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends ConsumerState<_AttendanceTile> {
  bool _busy = false;
  // null = unknown/not marked, true = checked in, false = checked out.
  bool? _present;

  String get _id =>
      (widget.staff['id'] ?? widget.staff['staffId'] ?? '').toString();
  String get _name => (widget.staff['name'] ?? 'Staff').toString();
  String get _role =>
      (widget.staff['role'] ?? widget.staff['type'] ?? '').toString();

  Future<void> _mark(bool checkIn) async {
    if (_id.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final ok = checkIn
          ? await AdminStaffService.checkIn(_id, widget.workDate)
          : await AdminStaffService.checkOut(_id, widget.workDate);
      if (!mounted) return;
      if (ok) {
        setState(() => _present = checkIn);
        ref.invalidate(staffDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_name marked ${checkIn ? 'present' : 'checked out'}'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update attendance'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _present;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF064E3B).withValues(alpha: 0.1),
            child: const Icon(Icons.person_outline, color: Color(0xFF064E3B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (_role.isNotEmpty)
                  Text(_role.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (present == true)
            _pill('Present', const Color(0xFF059669), () => _mark(false),
                actionLabel: 'Check out')
          else
            ElevatedButton(
              onPressed: () => _mark(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Check in',
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, VoidCallback onTap,
      {required String actionLabel}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text(text,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEA580C),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(actionLabel,
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
