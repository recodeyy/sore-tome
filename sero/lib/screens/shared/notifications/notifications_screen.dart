import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import 'package:intl/intl.dart';

/// Modern notification inbox (§16): category icon chip, title, time-ago and an
/// unread dot per item, with mark-all-read and pull-to-refresh.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text(
                'Mark all as read',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryGreen,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? RefreshIndicator(
              onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
              color: kPrimaryGreen,
              child: ListView(
                children: const [
                  SizedBox(height: 100),
                  EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    message:
                        "You're all caught up! Society updates, bills and visitor alerts will land here.",
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
              color: kPrimaryGreen,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationTile(item: item);
                },
              ),
            ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final dynamic item;
  const _NotificationTile({required this.item});

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(time);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool unread = !(item.isRead as bool);
    return GestureDetector(
      onTap: () => ref.read(notificationProvider.notifier).markAsRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread ? kLightMint : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? kAccentGreen.withValues(alpha: 0.25) : kSlateBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon chip
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (item.color as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(item.createdAt as DateTime),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: kTextSecondary,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: const BoxDecoration(
                            color: kAccentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
