import 'package:sero/services/api_service.dart';

/// Service for Staff Management module.
///
/// CUTOVER: backed by Postgres `/staff-v2/*` routes (raw JSON).
class AdminStaffService {
  /// GET /staff-v2 — list of all staff members.
  static Future<List<dynamic>> getAllStaff() async {
    final res = await ApiService.get('/staff-v2');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['staff'] is List) return data['staff'] as List;
    return const [];
  }

  /// GET /staff-v2/reports/attendance — attendance report (present/leave totals).
  static Future<Map<String, dynamic>> getAttendanceReport() async {
    final res = await ApiService.get('/staff-v2/reports/attendance');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
