import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/event.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/local_database_service.dart';

final eventsProvider = StateNotifierProvider.autoDispose<EventsNotifier, AsyncValue<List<SocietyEvent>>>((ref) {
  final user = ref.watch(authProvider).value;
  return EventsNotifier(user?.societyId);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<SocietyEvent>>> {
  final String? societyId;
  final _localDb = LocalDatabaseService();

  EventsNotifier(this.societyId) : super(const AsyncValue.loading()) {
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    // 1. Initial Load from Cache (Offline-First)
    if (societyId != null) {
      final cached = await _localDb.getItems('events', societyId: societyId);
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached.map((x) => SocietyEvent.fromMap(x)).toList());
      }
    }

    try {
      final res = await ApiService.get('/events');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['events'] as List).map((x) => SocietyEvent.fromMap(x)).toList();
        
        // Sort by date ascending
        list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        
        state = AsyncValue.data(list);

        // 2. Save to Cache
        if (societyId != null) {
          await _localDb.saveItems('events', list.map((x) => x.toMap()).toList());
        }
      } else {
        if (state.hasValue) return; // Keep cached data if API fails
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch events';
      }
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      } else {
        debugPrint('Offline Mode: Serving events from cache');
      }
    }
  }

  Future<void> addEvent(String title, String description, DateTime date, String location) async {
    try {
      final res = await ApiService.post('/events', {
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'location': location,
      });
      if (res.statusCode == 201) {
        fetchEvents();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to create event';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final res = await ApiService.delete('/events/$id');
      if (res.statusCode == 200) {
        fetchEvents();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to delete event';
      }
    } catch (e) {
      rethrow;
    }
  }
}
