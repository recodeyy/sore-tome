import 'package:sero/services/api_service.dart';

/// Service for Amenities / facility bookings (admin).
///
/// CUTOVER: backed by Postgres `/amenities` routes (raw JSON).
class AdminAmenitiesService {
  /// GET /amenities — list of amenities (and embedded booking summary if any).
  static Future<Map<String, dynamic>> getAmenities() async {
    final res = await ApiService.get('/amenities');
    final data = ApiService.unwrap(res);
    if (data is Map) return data.cast<String, dynamic>();
    if (data is List) return {'amenities': data};
    return <String, dynamic>{};
  }

  /// POST /amenities — create a bookable amenity (admin only). [capacity]
  /// defaults to 1 on the backend. Throws on non-2xx so the caller can surface
  /// the error to the user.
  static Future<Map<String, dynamic>> createAmenity(
    String name, {
    int? capacity,
  }) async {
    final res = await ApiService.post('/amenities', {
      'name': name,
      if (capacity != null) 'capacity': capacity,
    });
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
