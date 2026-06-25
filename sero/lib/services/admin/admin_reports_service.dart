import 'package:sero/services/api_service.dart';

/// Service for Reports module (admin).
///
/// CUTOVER: backed by Postgres `/reports/*` routes (raw JSON).
class AdminReportsService {
  /// GET /reports/jobs — generated/scheduled report jobs.
  static Future<List<dynamic>> getJobs() async {
    final res = await ApiService.get('/reports/jobs');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['jobs'] is List) return data['jobs'] as List;
    return const [];
  }

  /// GET /reports/templates — available report templates.
  static Future<List<dynamic>> getTemplates() async {
    final res = await ApiService.get('/reports/templates');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['templates'] is List) return data['templates'] as List;
    return const [];
  }
}
