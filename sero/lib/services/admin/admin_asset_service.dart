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

  /// Allowed asset [type] values accepted by the backend enum.
  static const assetTypes = ['lift', 'generator', 'pump', 'cctv', 'fire', 'other'];

  /// POST /assets — register a tracked asset. [tag] is the society's asset code
  /// (e.g. "LIFT-A1"), [name] a human label. [type] must be one of
  /// [assetTypes]. Throws on non-2xx so the caller can surface the error.
  static Future<Map<String, dynamic>> createAsset({
    required String tag,
    required String name,
    String? type,
    String? location,
  }) async {
    final res = await ApiService.post('/assets', {
      'tag': tag,
      'name': name,
      if (type != null && type.isNotEmpty) 'type': type,
      if (location != null && location.isNotEmpty) 'location': location,
    });
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
