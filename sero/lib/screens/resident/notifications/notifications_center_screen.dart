import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/models/notification_model.dart';

/// Notifications Center (design: home.png screen 3).
///
/// LIVE DATA: notificationProvider. The backend has no `/notifications` route
/// yet (the notifier loads an empty list pending that endpoint), so this screen
/// renders a truthful empty state until notifications are wired server-side —
/// no fabricated rows.
class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unread = notifications.where((n) => !n.isRead).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kSlateBg,
        appBar: AppBar(
          flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: kPremiumGradient)),
          title: Text('Notifications',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            TextButton(
              onPressed: notifications.isEmpty
                  ? null
                  : () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text('Mark all read',
                  style: GoogleFonts.outfit(
                      color: notifications.isEmpty ? Colors.white38 : Colors.white, fontSize: 12)),
            ),
          ],
          bottom: TabBar(
            indicatorColor: kAccentGreen,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'All'), Tab(text: 'Unread'), Tab(text: 'Important')],
          ),
        ),
        body: TabBarView(
          children: [
            _list(notifications, ref),
            _list(unread, ref),
            _list(notifications.where((n) => n.type == 'alert' || n.type == 'warning').toList(), ref),
          ],
        ),
      ),
    );
  }

  Widget _list(List<NotificationModel> items, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text("You're all caught up",
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('No notifications to show',
                style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1), fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final n = items[i];
        return GestureDetector(
          onTap: () => ref.read(notificationProvider.notifier).markAsRead(n.id),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isRead ? Colors.white : kAccentGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: n.isRead ? kSlateBorder : kAccentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: n.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(n.icon, color: n.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(n.message, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: kAccentGreen, shape: BoxShape.circle)),
              ],
            ),
          ),
        );
      },
    );
  }
}
