import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Staff Tasks tab (MR-007): complaints assigned to/visible to the staff
/// member from GET /complaints (backend scopes by role), with the canonical
/// status transitions open → in_progress → resolved.
class StaffTasksScreen extends ConsumerWidget {
  const StaffTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'My Tasks',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Complaints and work orders assigned to you',
                style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: issuesAsync.when(
                loading: () => const SkeletonList(itemCount: 5),
                error: (e, _) => ErrorRetryView(
                  message: 'Could not load your tasks.',
                  onRetry: () => ref.read(issuesProvider.notifier).refresh(),
                ),
                data: (issues) {
                  final open = issues.where((i) => i.status != 'closed').toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  if (open.isEmpty) {
                    return const EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'No tasks right now',
                      message: 'New complaints assigned to you will appear here.',
                    );
                  }
                  return RefreshIndicator(
                    color: kPrimaryGreen,
                    onRefresh: () => ref.read(issuesProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: open.length,
                      itemBuilder: (context, i) => _TaskCard(issue: open[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  final Issue issue;
  const _TaskCard({required this.issue});

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _busy = false;

  ChipSemantic get _semantic {
    switch (widget.issue.status) {
      case 'resolved':
        return ChipSemantic.success;
      case 'in_progress':
        return ChipSemantic.info;
      default:
        return ChipSemantic.warning; // open
    }
  }

  String get _statusLabel {
    switch (widget.issue.status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'resolved':
        return 'RESOLVED';
      default:
        return widget.issue.status.toUpperCase();
    }
  }

  Future<void> _update(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: kPrimaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final notifier = ref.read(issuesProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
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
              Expanded(
                child: Text(
                  issue.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
              StatusChip(label: _statusLabel, semantic: _semantic),
            ],
          ),
          if (issue.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              issue.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: kTextSecondary.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                issue.priority.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
              const Spacer(),
              if (_busy)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else if (issue.status == 'open')
                _actionButton('Start', Icons.play_arrow_rounded,
                    () => _update(() => notifier.assignIssue(issue.id, ''), 'Task started'))
              else if (issue.status == 'in_progress')
                _actionButton('Mark Resolved', Icons.check_rounded,
                    () => _update(() => notifier.resolveIssue(issue.id), 'Task resolved')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
