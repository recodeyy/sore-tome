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
      // CUTOVER: canonical Postgres endpoint /complaints → { complaints: [...] }.
      final res = await ApiService.get('/complaints');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = ((data['complaints'] ?? data['issues'] ?? const []) as List)
            .map((x) => Issue.fromMap(x))
            .toList();
        
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

  // `category` is the legacy free-text label. The v2 create schema is strict and
  // only accepts a `categoryId` UUID (or none), so the label is dropped here.
  Future<void> addIssue(String title, String description, String category) async {
    try {
      final res = await ApiService.post('/complaints', {
        'title': title,
        'description': description,
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
      // v2 state machine: PATCH /complaints/:id/status { status, note? }.
      final res = await ApiService.patch('/complaints/$id/status', {'status': 'resolved'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to resolve issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  // v2 has a dedicated POST /complaints/:id/assign (assigneeId/assigneeType),
  // but the admin UI just wants to acknowledge the ticket. Map "assign to me"
  // onto the canonical status transition open → in_progress.
  Future<void> assignIssue(String id, String assignee) async {
    try {
      final res = await ApiService.patch('/complaints/$id/status', {'status': 'in_progress'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to assign issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  // NOTE: v2 /complaints has no hard-delete (complaints are an auditable
  // record). Closing is the terminal transition, so "delete" maps to
  // PATCH status → closed.
  Future<void> deleteIssue(String id) async {
    try {
      final res = await ApiService.patch('/complaints/$id/status', {'status': 'closed'});
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



