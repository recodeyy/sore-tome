import 'package:sero/services/api_service.dart';

/// Service for Admin Dashboard related API calls.
///
/// CUTOVER: now backed by the Postgres `/api/v1` backend
/// (`GET /admin/dashboard/summary`, `{ success, data, meta }` envelope).
class AdminDashboardService {
  /// Fetches summary statistics for the admin dashboard.
  /// Returns the unwrapped `data` map from the envelope.
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final res = await ApiService.get('/admin/dashboard/summary');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// Fetches tenant-scoped live society vitals.
  /// Returns the unwrapped `data` map from the envelope.
  static Future<Map<String, dynamic>> getVitals() async {
    final res = await ApiService.get('/admin/dashboard/vitals');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// Fetches recent activities for the dashboard.
  static Future<List<dynamic>> getRecentActivities() async {
    final res = await ApiService.get('/admin/dashboard/summary');
    final data = ApiService.unwrap(res);
    if (data is Map && data['recentUpdates'] is List) {
      return data['recentUpdates'] as List;
    }
    return const [];
  }

  /// Creates a draft society event.
  ///
  /// POST /events-v2 → { event }. [startsAt]/[endsAt] are ISO-8601 UTC strings
  /// (e.g. `2026-06-27T08:00:00.000Z`). Throws on non-2xx so the caller can
  /// surface the error. Returns the created event record.
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    String? location,
    required String startsAt,
    String? endsAt,
  }) async {
    final res = await ApiService.post('/events-v2', {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'startsAt': startsAt,
      if (endsAt != null) 'endsAt': endsAt,
    });
    final data = ApiService.unwrap(res);
    if (data is Map && data['event'] is Map) {
      return (data['event'] as Map).cast<String, dynamic>();
    }
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// Reads the admin's saved dashboard preferences (capability 8).
  ///
  /// GET /admin/dashboard/preferences → { widgets, savedFilters }.
  /// `widgets` is an opaque ordered JSON array we use to persist the enabled
  /// quick-action ids. Returns `{}` on any failure (caller falls back to
  /// defaults).
  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      final res = await ApiService.get('/admin/dashboard/preferences');
      final data = ApiService.unwrap(res);
      return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Persists the ordered list of enabled quick-action ids into the dashboard
  /// preferences `widgets` array.
  ///
  /// PUT /admin/dashboard/preferences. Returns true on success.
  static Future<bool> saveQuickActions(List<String> actionIds) async {
    final res = await ApiService.put(
      '/admin/dashboard/preferences',
      {'widgets': actionIds},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
