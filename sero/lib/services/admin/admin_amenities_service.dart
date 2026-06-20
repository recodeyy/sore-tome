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
}
