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

  /// Fetches recent activities for the dashboard.
  static Future<List<dynamic>> getRecentActivities() async {
    final res = await ApiService.get('/admin/dashboard/summary');
    final data = ApiService.unwrap(res);
    if (data is Map && data['recentUpdates'] is List) {
      return data['recentUpdates'] as List;
    }
    return const [];
  }
}
