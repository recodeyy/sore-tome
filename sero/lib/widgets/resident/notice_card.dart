import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/notice.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NoticeCard extends StatelessWidget {
  final Notice notice;

  const NoticeCard({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: _getThemeColor(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NoticeBadge(tag: notice.tag),
                        Text(
                          _formatDate(notice.createdAt),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notice.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notice.body,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Color _getThemeColor() {
    switch (notice.tag) {
      case 'new':
        return kAccentGreen;
      case 'today':
        return Colors.amber;
      case 'urgent':
        return Colors.redAccent;
      default:
        return kPrimaryBlue;
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day} ${_getMonth(dt.month)}";
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}

class _NoticeBadge extends StatelessWidget {
  final String tag;
  const _NoticeBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (tag) {
      case 'new':
        bg = kBadgeGreenBg;
        fg = kBadgeGreenText;
        label = 'NEW';
        break;
      case 'today':
        bg = kBadgeAmberBg;
        fg = kBadgeAmberText;
        label = 'TODAY';
        break;
      case 'urgent':
        bg = kBadgeRedBg;
        fg = kBadgeRedText;
        label = 'URGENT';
        break;
      default:
        bg = kBadgeBlueBg;
        fg = kBadgeBlueText;
        label = 'INFO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9, 
          fontWeight: FontWeight.w800, 
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}



