import 'package:sero/services/api_service.dart';

/// Service for Parking management.
///
/// CUTOVER: backed by Postgres `/parking/*` routes (raw JSON).
class AdminParkingService {
  /// GET /parking/slots — parking slots with status.
  static Future<List<dynamic>> getSlots() async {
    final res = await ApiService.get('/parking/slots');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['slots'] is List) return data['slots'] as List;
    return const [];
  }

  /// GET /parking/violations — parking violations.
  static Future<List<dynamic>> getViolations() async {
    final res = await ApiService.get('/parking/violations');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['violations'] is List) return data['violations'] as List;
    return const [];
  }

  /// GET /parking/requests — pending parking allocation requests.
  static Future<List<dynamic>> getRequests() async {
    final res = await ApiService.get('/parking/requests');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['requests'] is List) return data['requests'] as List;
    return const [];
  }

  /// POST /parking/allocations — allocate a slot.
  static Future<bool> allocateSlot(Map<String, dynamic> body) async {
    final res = await ApiService.post('/parking/allocations', body);
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
