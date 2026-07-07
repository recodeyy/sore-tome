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

  /// Schedule a recurring report. Creates a template (carrying the [config],
  /// e.g. recipients) then a schedule with the given [cron] expression.
  ///
  /// POST /reports/templates  → { template }
  /// POST /reports/schedules  → { schedule }
  /// [kind] ∈ finance|complaints|staff|occupancy|custom,
  /// [format] ∈ pdf|excel|csv. Throws on failure so the caller can surface it.
  static Future<void> scheduleReport({
    required String name,
    required String kind,
    required String format,
    required String cron,
    String? nextRunAt,
    Map<String, dynamic>? config,
  }) async {
    final tplRes = await ApiService.post('/reports/templates', {
      'name': name,
      'kind': kind,
      'format': format,
      if (config != null && config.isNotEmpty) 'config': config,
    });
    final tplData = ApiService.unwrap(tplRes);
    final tpl = (tplData is Map && tplData['template'] is Map)
        ? (tplData['template'] as Map)
        : ((tplData as Map?) ?? const {});
    final templateId = (tpl['id'] ?? '').toString();
    if (templateId.isEmpty) {
      throw Exception('Failed to create report template');
    }
    await ApiService.post('/reports/schedules', {
      'templateId': templateId,
      'cron': cron,
      if (nextRunAt != null) 'nextRunAt': nextRunAt,
    });
  }

  /// Generate a report and return its CSV artifact body.
  ///
  /// Runs the full pipeline: enqueue a job → generate it → download the
  /// artifact. [kind] selects the dataset (finance|complaints|staff|...).
  /// Throws on any failure so the caller can show an error.
  static Future<String> exportReportCsv({String kind = 'finance'}) async {
    // 1. Enqueue the job.
    final jobRes = await ApiService.post('/reports/jobs', {'kind': kind});
    final jobData = ApiService.unwrap(jobRes);
    final job = (jobData is Map && jobData['job'] is Map)
        ? (jobData['job'] as Map)
        : ((jobData as Map?) ?? const {});
    final jobId = (job['id'] ?? '').toString();
    if (jobId.isEmpty) throw Exception('Failed to create report job');

    // 2. Generate the artifact (CSV, formula-injection safe on the server).
    await ApiService.post('/reports/jobs/$jobId/generate', const {});

    // 3. Download the raw CSV (not the JSON envelope).
    final artRes = await ApiService.get('/reports/jobs/$jobId/artifact');
    if (artRes.statusCode < 200 || artRes.statusCode >= 300) {
      throw Exception('Failed to download report (${artRes.statusCode})');
    }
    return artRes.body;
  }
}
