import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/local_database_service.dart';
import 'package:flutter/foundation.dart';

final issuesStreamProvider = StreamProvider.autoDispose<List<Issue>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return const Stream.empty();
  return FirestoreService().getIssuesStream(user.id, user.societyId); 
});

final issuesProvider = StateNotifierProvider.autoDispose<IssuesNotifier, AsyncValue<List<Issue>>>((ref) {
  final user = ref.watch(authProvider).value;
  return IssuesNotifier(user?.societyId);
});

class IssuesNotifier extends StateNotifier<AsyncValue<List<Issue>>> {
  final String? societyId;
  final _localDb = LocalDatabaseService();

  IssuesNotifier(this.societyId) : super(const AsyncValue.loading()) {
    fetchIssues();
  }

  Future<void> fetchIssues() async {
    // 1. Initial Load from Cache for "WOW" speed (Optimistic UI)
    if (societyId != null) {
      final cached = await _localDb.getItems('issues', societyId: societyId);
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached.map((x) => Issue.fromMap(x)).toList());
      }
    }

    try {
      final res = await ApiService.get('/issues');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['issues'] as List).map((x) => Issue.fromMap(x)).toList();
        
        state = AsyncValue.data(list);

        // 2. Save to Cache
        if (societyId != null) {
          await _localDb.saveItems('issues', list.map((x) => x.toMap()).toList());
        }
      } else {
        if (state.hasValue) return;
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch issues';
      }
    } catch (e, st) {
      if (state.hasValue) {
        debugPrint('Offline: Using cached issues');
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => fetchIssues();

  Future<void> addIssue(String title, String description, String category) async {
    try {
      final res = await ApiService.post('/issues', {
        'title': title,
        'description': description,
        'category': category,
      });
      if (res.statusCode == 201) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to report issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resolveIssue(String id) async {
    try {
      final res = await ApiService.patch('/issues/$id', {'status': 'resolved'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to resolve issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignIssue(String id, String assignee) async {
    try {
      final res = await ApiService.patch('/issues/$id', {'assignedTo': assignee, 'status': 'in_progress'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to assign issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteIssue(String id) async {
    try {
      final res = await ApiService.delete('/issues/$id');
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to delete issue';
      }
    } catch (e) {
      rethrow;
    }
  }
}



