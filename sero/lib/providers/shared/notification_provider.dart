import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/notification_model.dart';
import 'package:sero/services/api_service.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]) {
    refresh();
  }

  /// Live fetch from GET /notifications (tenant + user scoped on the backend).
  /// Never falls back to fake data: on error the list is left as-is.
  Future<void> refresh() async {
    try {
      final res = await ApiService.get('/notifications');
      final data = ApiService.unwrap(res);
      final rawList = data is List
          ? data
          : (data is Map ? (data['notifications'] as List? ?? const []) : const []);
      state = rawList
          .map((x) => NotificationModel.fromMap((x as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('Notifications fetch failed: $e');
    }
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
