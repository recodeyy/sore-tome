import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/notice.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';

import 'package:sero/services/local_database_service.dart';

final noticesStreamProvider = StreamProvider.autoDispose<List<Notice>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  return FirestoreService().getNoticesStream(user.societyId);
});

final noticesProvider = StateNotifierProvider.autoDispose<NoticesNotifier, AsyncValue<List<Notice>>>((ref) {
  final user = ref.watch(authProvider).value;
  return NoticesNotifier(user?.societyId);
});

class NoticesNotifier extends StateNotifier<AsyncValue<List<Notice>>> {
  final String? societyId;
  final _localDb = LocalDatabaseService();

  NoticesNotifier(this.societyId) : super(const AsyncValue.loading()) {
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    // 1. Initial Load from Cache for "WOW" speed (Optimistic UI)
    if (societyId != null) {
      final cached = await _localDb.getItems('notices', societyId: societyId);
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached.map((x) => Notice.fromMap(x)).toList());
      }
    }

    try {
      // CUTOVER: real Postgres backend — GET /notices-v2 ({success,data} envelope).
      final res = await ApiService.get('/notices-v2');
      final data = ApiService.unwrap(res);
      final rawList = data is List
          ? data
          : (data is Map ? (data['notices'] as List? ?? const []) : const []);
      final list = rawList.map((x) => Notice.fromMap(x)).toList();

      state = AsyncValue.data(list);

      // 2. Save to Cache
      if (societyId != null) {
        await _localDb.saveItems('notices', list.map((x) => x.toMap()).toList());
      }
    } catch (e, st) {
      if (state.hasValue) {
        debugPrint('Offline: Using cached notices');
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addNotice(String title, String body, String type) async {
    try {
      final res = await ApiService.post('/notices-v2', {
        'title': title,
        'body': body,
        'type': type,
      });
      // unwrap validates success/status; throws on failure.
      ApiService.unwrap(res);
      fetchNotices();
    } catch (e) {
      rethrow;
    }
  }
}



