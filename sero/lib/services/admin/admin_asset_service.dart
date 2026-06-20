import 'package:sero/services/api_service.dart';

/// Service for Asset management and tracking.
///
/// CUTOVER: backed by Postgres `/assets/*` routes (raw JSON).
class AdminAssetService {
  /// GET /assets — list of society assets.
  static Future<List<dynamic>> getAssets() async {
    final res = await ApiService.get('/assets');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['assets'] is List) return data['assets'] as List;
    return const [];
  }

  /// GET /assets/dashboard — aggregated counts, categories, upcoming
  /// maintenance and recent activity (all computed in Postgres).
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiService.get('/assets/dashboard');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /assets/:id — single asset detail.
  static Future<Map<String, dynamic>> getAsset(String id) async {
    final res = await ApiService.get('/assets/$id');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
