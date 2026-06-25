import 'package:sero/services/api_service.dart';

/// Service for Complaint Management API calls.
///
/// CUTOVER: backed by Postgres `/complaints/*` routes (raw JSON).
class AdminComplaintService {
  /// GET /complaints — list complaints (optionally by status).
  static Future<List<dynamic>> getComplaints({String? status}) async {
    final q = status != null ? '?status=$status' : '';
    final res = await ApiService.get('/complaints$q');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['complaints'] is List) return data['complaints'] as List;
    return const [];
  }

  /// GET /complaints/analytics — SLA/resolution analytics.
  static Future<Map<String, dynamic>> getAnalytics() async {
    final res = await ApiService.get('/complaints/analytics');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /complaints/:id — single complaint detail.
  static Future<Map<String, dynamic>> getComplaint(String id) async {
    final res = await ApiService.get('/complaints/$id');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// PATCH /complaints/:id/status — update complaint status.
  static Future<bool> updateComplaintStatus(String id, String status) async {
    final res = await ApiService.patch('/complaints/$id/status', {'status': status});
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
