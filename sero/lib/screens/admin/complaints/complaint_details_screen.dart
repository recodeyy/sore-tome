import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_complaint_service.dart';

/// Complaint Details Screen — Complaints Module (2/2).
/// Live, backed by GET /complaints/:id (Postgres, tenant-scoped). Expects the
/// complaint id as the route argument.
class ComplaintDetailsScreen extends ConsumerWidget {
  const ComplaintDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context)),
        title: Text('Complaint Details',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ),
      body: id == null
          ? const LiveEmptyView(
              icon: Icons.assignment_outlined,
              message: 'Select a complaint to view its details.',
            )
          : ref.watch(complaintDetailProvider(id)).when(
                loading: () => const LiveLoadingView(label: 'Loading complaint…'),
                error: (e, _) => LiveErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(complaintDetailProvider(id)),
                ),
                data: (payload) {
                  final complaint =
                      (payload['complaint'] as Map?)?.cast<String, dynamic>() ?? const {};
                  if (complaint.isEmpty) {
                    return const LiveEmptyView(
                      icon: Icons.assignment_outlined,
                      message: 'Complaint not found.',
                    );
                  }
                  final assignments = (payload['assignments'] as List?) ?? const [];
                  final history = (payload['statusHistory'] as List?) ?? const [];
                  return _buildBody(context, ref, id, complaint, assignments, history);
                },
              ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    String id,
    Map<String, dynamic> c,
    List<dynamic> assignments,
    List<dynamic> history,
  ) {
    final status = (c['status'] ?? '').toString();
    final priority = (c['priority'] ?? '').toString();
    final assignment =
        assignments.isNotEmpty ? (assignments.last as Map).cast<String, dynamic>() : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((c['code'] ?? c['id'] ?? '').toString(),
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)),
                child: Text(status,
                    style: GoogleFonts.outfit(
                        fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text((c['title'] ?? '').toString(),
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text((c['location'] ?? c['category'] ?? '').toString(),
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              const Spacer(),
              if (priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(4)),
                  child: Text(priority,
                      style: GoogleFonts.outfit(
                          fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Description',
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text((c['description'] ?? '').toString(),
              style:
                  GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.6)),
          if (assignment != null) ...[
            const SizedBox(height: 24),
            Text('Assigned To',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(Icons.person, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      (assignment['assignee_name'] ?? assignment['assignee_id'] ?? 'Assigned')
                          .toString(),
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Timeline',
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Text('No status updates yet.',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B)))
          else
            Column(
              children: history.asMap().entries.map<Widget>((entry) {
                final tl = (entry.value as Map).cast<String, dynamic>();
                return _TimelineItem(
                  title: (tl['to_status'] ?? tl['status'] ?? '').toString(),
                  desc: (tl['note'] ?? '').toString(),
                  time: (tl['created_at'] ?? '').toString(),
                  isLast: entry.key == history.length - 1,
                  isActive: entry.key == history.length - 1,
                );
              }).toList(),
            ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status == 'resolved' || status == 'closed'
                      ? null
                      : () async {
                          final ok = await AdminComplaintService.updateComplaintStatus(
                              id, 'resolved');
                          if (ok) ref.invalidate(complaintDetailProvider(id));
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Marked as resolved')));
                          }
                        },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text('Mark as Resolved',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final bool isLast;
  final bool isActive;

  const _TimelineItem({
    required this.title,
    required this.desc,
    required this.time,
    required this.isLast,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF7C3AED) : const Color(0xFF059669);
    final icon = isActive ? Icons.hourglass_empty : Icons.check;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: color, size: 14)),
            ),
            if (!isLast) Container(width: 2, height: 40, color: const Color(0xFFF1F5F9)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              if (desc.isNotEmpty)
                Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              Text(time, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E1))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
