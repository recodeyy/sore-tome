import 'dart:convert';
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
      final res = await ApiService.get('/notices');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notices'] as List).map((x) => Notice.fromMap(x)).toList();
        
        state = AsyncValue.data(list);

        // 2. Save to Cache
        if (societyId != null) {
          await _localDb.saveItems('notices', list.map((x) => x.toMap()).toList());
        }
      } else {
        // If API fails but we have cache, keep cache. If no cache, show error.
        if (state.hasValue) return;
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch notices';
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
      final res = await ApiService.post('/notices', {
        'title': title,
        'body': body,
        'type': type,
      });
      if (res.statusCode == 201) {
        fetchNotices();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to post notice';
      }
    } catch (e) {
      rethrow;
    }
  }
}



