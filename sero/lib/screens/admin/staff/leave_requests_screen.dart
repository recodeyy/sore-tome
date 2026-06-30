import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_staff_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Leave Requests — admin approval queue backed by GET /staff-v2/leave/requests.
/// Approving decrements the staff member's leave balance on the backend (under a
/// row lock), so the admin decision here is the single source of truth.
class LeaveRequestsScreen extends ConsumerWidget {
  const LeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqAsync = ref.watch(leaveRequestsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Leave Requests',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: reqAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading leave requests…'),
        error: (e, _) => LiveErrorView(
            error: e, onRetry: () => ref.invalidate(leaveRequestsProvider)),
        data: (reqs) {
          if (reqs.isEmpty) {
            return const LiveEmptyView(
              icon: Icons.event_available_outlined,
              message: 'No pending leave requests.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = reqs[i] is Map
                  ? (reqs[i] as Map).cast<String, dynamic>()
                  : <String, dynamic>{};
              return _LeaveCard(req: m);
            },
          );
        },
      ),
    );
  }
}

class _LeaveCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> req;
  const _LeaveCard({required this.req});

  @override
  ConsumerState<_LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends ConsumerState<_LeaveCard> {
  bool _busy = false;

  String get _id => (widget.req['id'] ?? '').toString();
  String get _name => (widget.req['staff_name'] ?? 'Staff').toString();
  String get _type => (widget.req['leave_type_name'] ?? 'Leave').toString();
  String get _from => (widget.req['from_date'] ?? '').toString().split('T').first;
  String get _to => (widget.req['to_date'] ?? '').toString().split('T').first;
  String get _days => (widget.req['days'] ?? '').toString();
  String get _reason => (widget.req['reason'] ?? '').toString();

  Future<void> _decide(String decision) async {
    if (_id.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final ok = await AdminStaffService.decideLeave(_id, decision);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(leaveRequestsProvider);
        ref.invalidate(staffDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave $decision'),
            backgroundColor: decision == 'approved'
                ? const Color(0xFF059669)
                : const Color(0xFFEA580C),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update request'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(_type,
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$_from → $_to  •  $_days day(s)',
              style: GoogleFonts.outfit(
                  color: const Color(0xFF475569), fontSize: 13)),
          if (_reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_reason,
                style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8), fontSize: 12)),
          ],
          const SizedBox(height: 14),
          if (_busy)
            const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFF1F5F9)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decide('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
