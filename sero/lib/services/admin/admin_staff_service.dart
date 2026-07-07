import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sero/services/api_service.dart';
import 'package:sero/services/api_client.dart';
import 'package:sero/services/auth_service.dart';

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

  /// POST /staff-v2 — register a new staff member. Returns the created record.
  /// [role] maps to backend `role`, [phone]/[department]/[monthlyWageMinor]
  /// are optional. Throws on non-2xx so the caller can surface the error.
  static Future<Map<String, dynamic>> createStaff({
    required String name,
    String? role,
    String? department,
    String? phone,
    int? monthlyWageMinor,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (role != null && role.isNotEmpty) 'role': role,
      if (department != null && department.isNotEmpty) 'department': department,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (monthlyWageMinor != null) 'monthlyWageMinor': monthlyWageMinor,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    };
    final res = await ApiService.post('/staff-v2', body);
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// POST /users/upload-image — uploads [filePath] and returns the public URL.
  /// Used to persist a staff member's captured/selected photo. Throws on failure.
  static Future<String> uploadImage(String filePath) async {
    final token = await AuthService.getToken();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/users/upload-image'),
    );
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('image', filePath));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['url'] ?? '').toString();
    }
    throw Exception('Image upload failed (${res.statusCode})');
  }

  /// PATCH /staff-v2/:id/status — change a staff member's employment status.
  /// [status] must be one of `active`, `suspended`, `terminated` (the backend
  /// enum). Use `active` to approve/reinstate, `suspended` to hold, and
  /// `terminated` to off-board. Throws on non-2xx.
  static Future<bool> setStatus(String staffId, String status,
      {String? leavingDate}) async {
    final res = await ApiService.patch(
      '/staff-v2/$staffId/status',
      {'status': status, if (leavingDate != null) 'leavingDate': leavingDate},
    );
    ApiService.unwrap(res); // throws on failure
    return true;
  }

  /// POST /staff-v2/attendance/check-in — mark a staff member present for
  /// [workDate] (YYYY-MM-DD). Returns true on success.
  static Future<bool> checkIn(String staffId, String workDate) async {
    final res = await ApiService.post(
      '/staff-v2/attendance/check-in',
      {'staffId': staffId, 'workDate': workDate, 'source': 'manual'},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// POST /staff-v2/attendance/check-out — mark a staff member checked out for
  /// [workDate] (YYYY-MM-DD). Returns true on success.
  static Future<bool> checkOut(String staffId, String workDate) async {
    final res = await ApiService.post(
      '/staff-v2/attendance/check-out',
      {'staffId': staffId, 'workDate': workDate, 'source': 'manual'},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// GET /staff-v2/leave/requests — admin leave-approval queue. Optional
  /// [status] filter ("pending" | "approved" | "rejected").
  static Future<List<dynamic>> getLeaveRequests({String? status}) async {
    final q = status != null ? '?status=$status' : '';
    final res = await ApiService.get('/staff-v2/leave/requests$q');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['requests'] is List) return data['requests'] as List;
    return const [];
  }

  /// POST /staff-v2/leave/requests/:id/decision — approve or reject a leave
  /// request. [decision] is "approved" or "rejected".
  static Future<bool> decideLeave(String requestId, String decision,
      {String? comment}) async {
    final res = await ApiService.post(
      '/staff-v2/leave/requests/$requestId/decision',
      {'decision': decision, if (comment != null) 'comment': comment},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// GET /staff-v2/roster — duty roster (today onward, or a specific [date]).
  static Future<List<dynamic>> getRoster({String? date}) async {
    final q = date != null ? '?date=$date' : '';
    final res = await ApiService.get('/staff-v2/roster$q');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['roster'] is List) return data['roster'] as List;
    return const [];
  }

  /// GET /staff-v2/payroll — payroll run summary rows (newest period first).
  static Future<List<dynamic>> getPayrollRuns() async {
    final res = await ApiService.get('/staff-v2/payroll');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['runs'] is List) return data['runs'] as List;
    return const [];
  }

  /// POST /staff-v2/payroll/generate — generate a draft payroll run for
  /// [period] (YYYY-MM). Returns true on success.
  static Future<bool> generatePayroll(String period) async {
    final res =
        await ApiService.post('/staff-v2/payroll/generate', {'period': period});
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
