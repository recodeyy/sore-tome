import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/notification_model.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Fetch notifications from backend API
    // final response = await ApiService.get('/notifications');
    state = [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAllAsRead() {
    state = state.map((n) {
      n.isRead = true;
      return n;
    }).toList();
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
  }

  void clearAll() {
    state = [];
  }
}
