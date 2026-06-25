import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/providers/shared/issues_provider.dart';

class IssueCard extends ConsumerStatefulWidget {
  final Issue issue;
  final bool showResolveButton;
  final VoidCallback? onResolve;

  const IssueCard({
    super.key,
    required this.issue,
    this.showResolveButton = false,
    this.onResolve,
  });

  @override
  ConsumerState<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends ConsumerState<IssueCard> {
  bool _pressed = false;

  // ── Icon & color per issue type ─────────────────────────────────────────────
  IconData get _icon {
    final t = widget.issue.title.toLowerCase();
    if (t.contains('pipe') || t.contains('water') || t.contains('leak')) {
      return Icons.plumbing_rounded;
    } else if (t.contains('light') ||
        t.contains('electric') ||
        t.contains('power') ||
        t.contains('bulb')) {
      return Icons.bolt_rounded;
    } else if (t.contains('lift') || t.contains('elevator')) {
      return Icons.elevator_rounded;
    } else if (t.contains('key') ||
        t.contains('lock') ||
        t.contains('card') ||
        t.contains('access')) {
      return Icons.key_rounded;
    } else if (t.contains('internet') ||
        t.contains('wifi') ||
        t.contains('network')) {
      return Icons.wifi_off_rounded;
    } else if (t.contains('gate') || t.contains('door')) {
      return Icons.door_front_door_rounded;
    } else if (t.contains('parking') || t.contains('car')) {
      return Icons.local_parking_rounded;
    } else if (t.contains('noise') || t.contains('sound')) {
      return Icons.volume_off_rounded;
    }
    return Icons.report_problem_rounded;
  }

  Color get _iconBg {
    final t = widget.issue.title.toLowerCase();
    if (t.contains('pipe') || t.contains('water') || t.contains('leak')) {
      return const Color(0xFFE0F2FE);
    } else if (t.contains('light') ||
        t.contains('electric') ||
        t.contains('power')) {
      return const Color(0xFFFEF3C7);
    } else if (t.contains('internet') || t.contains('wifi')) {
      return const Color(0xFFEDE9FE);
    } else if (t.contains('key') || t.contains('lock') || t.contains('card')) {
      return const Color(0xFFD1FAE5);
    }
    return const Color(0xFFFFE4E6);
  }

  Color get _iconColor {
    final t = widget.issue.title.toLowerCase();
    if (t.contains('pipe') || t.contains('water') || t.contains('leak')) {
      return const Color(0xFF0284C7);
    } else if (t.contains('light') ||
        t.contains('electric') ||
        t.contains('power')) {
      return const Color(0xFFF59E0B);
    } else if (t.contains('internet') || t.contains('wifi')) {
      return const Color(0xFF7C3AED);
    } else if (t.contains('key') || t.contains('lock') || t.contains('card')) {
      return const Color(0xFF059669);
    }
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon circle ───────────────────────────────────────────
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _iconColor, size: 20),
                ),
                const SizedBox(width: 14),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Priority Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.issue.title.startsWith('Chat Sync:') 
                                  ? widget.issue.description 
                                  : widget.issue.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriorityBadge(status: widget.issue.status),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Reporter + time + Source
                      Text(
                        '${widget.issue.title.startsWith('Chat Sync:') ? 'Synced from Chat · ' : ''}Reported by ${widget.issue.postedBy} · ${_timeAgo(widget.issue.createdAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // STATUS + ASSIGNED TO two-column footer
                      Row(
                        children: [
                          _FooterColumn(
                            label: 'STATUS',
                            child: _StatusDot(status: widget.issue.status),
                          ),
                          if (widget.issue.status != 'open') ...[
                            const SizedBox(width: 24),
                            _FooterColumn(
                              label: 'ASSIGNED TO',
                              child: _AssignedTo(status: widget.issue.status),
                            ),
                          ],
                          const Spacer(),
                          // Admin Menu (3 Dots)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: Color(0xFFCBD5E1),
                            ),
                            onSelected: (val) async {
                              final notifier = ref.read(issuesProvider.notifier);
                              if (val == 'resolve') await notifier.resolveIssue(widget.issue.id);
                              if (val == 'assign') await notifier.assignIssue(widget.issue.id, 'Management');
                              if (val == 'delete') await notifier.deleteIssue(widget.issue.id);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'resolve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Resolve'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'assign',
                                child: Row(
                                  children: [
                                    Icon(Icons.assignment_ind_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Assign to Me'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (widget.showResolveButton) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onResolve,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryGreen,
                              side: const BorderSide(
                                  color: kPrimaryGreen, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Mark as Resolved'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ─── Priority badge (CRITICAL / MEDIUM / LOW) ──────────────────────────────────
class _PriorityBadge extends StatelessWidget {
  final String status;
  const _PriorityBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'resolved':
        bg = kBadgeGreenBg;
        fg = kBadgeGreenText;
        label = 'RESOLVED';
        break;
      case 'in_progress':
        bg = kBadgeAmberBg;
        fg = kBadgeAmberText;
        label = 'IN PROGRESS';
        break;
      default:
        bg = kBadgeRedBg;
        fg = kBadgeRedText;
        label = 'OPEN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Status dot + label ────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;

    switch (status) {
      case 'resolved':
        dotColor = kAccentGreen;
        label = 'Resolved';
        break;
      case 'in_progress':
        dotColor = const Color(0xFF3B82F6);
        label = 'In Progress';
        break;
      default:
        dotColor = const Color(0xFFEF4444);
        label = 'Open';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

// ─── Assigned To ──────────────────────────────────────────────────────────────
class _AssignedTo extends StatelessWidget {
  final String status;
  const _AssignedTo({required this.status});

  @override
  Widget build(BuildContext context) {
    final isUnassigned =
        status == 'open' || status == 'unassigned';

    if (isUnassigned) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Unassigned',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: kPrimaryGreen,
          child: Text(
            'M',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Mgmt.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

// ─── Footer column (label + child) ────────────────────────────────────────────
class _FooterColumn extends StatelessWidget {
  final String label;
  final Widget child;
  const _FooterColumn({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCBD5E1),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}



