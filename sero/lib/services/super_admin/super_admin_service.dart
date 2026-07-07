import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/services/api_service.dart';

class SuperAdminApiException implements Exception {
  final String message;
  final int statusCode;
  final String? requestId;

  const SuperAdminApiException(
    this.message,
    this.statusCode, {
    this.requestId,
  });

  @override
  String toString() {
    final suffix = requestId == null ? '' : ' ($requestId)';
    return 'SuperAdminApiException: $message [$statusCode]$suffix';
  }
}

class SuperAdminService {
  static const String _basePath = '/super-admin';

  Future<SuperAdminDashboard> getDashboard() async {
    final data = await _getMap('$_basePath/dashboard');
    return SuperAdminDashboard.fromJson(data);
  }

  Future<SuperAdminSocietiesPage> getSocieties({
    SuperAdminSocietyFilters filters = const SuperAdminSocietyFilters(),
    String? cursor,
  }) async {
    final data = await _getMap(
      _endpoint('$_basePath/societies', filters.toQuery(cursor: cursor)),
    );
    return SuperAdminSocietiesPage.fromJson(data);
  }

  Future<SuperAdminSociety> getSociety(String societyId) async {
    final data = await _getMap('$_basePath/societies/$societyId');
    return SuperAdminSociety.fromJson(data);
  }

  Future<List<SuperAdminActivity>> getSocietyActivity(String societyId) async {
    final data = await _getMap('$_basePath/societies/$societyId/activity');
    return _listFrom(data, ['activity', 'items', 'data'])
        .map(SuperAdminActivity.fromJson)
        .toList();
  }

  Future<void> approveSociety(String societyId, {required String reason}) {
    return _postAction(
      '$_basePath/societies/$societyId/approve',
      {'reason': reason},
    );
  }

  Future<void> rejectSociety(
    String societyId, {
    required String reason,
  }) {
    return _postAction(
      '$_basePath/societies/$societyId/reject',
      {'reason': reason},
    );
  }

  Future<void> requestSocietyInformation(
    String societyId, {
    required String reason,
    List<String> requestedFields = const [],
  }) {
    return _postAction(
      '$_basePath/societies/$societyId/request-information',
      {'reason': reason, 'requestedFields': requestedFields},
    );
  }

  Future<void> suspendSociety(String societyId, {required String reason}) {
    return _postAction(
      '$_basePath/societies/$societyId/suspend',
      {'reason': reason},
    );
  }

  Future<void> reactivateSociety(String societyId, {required String reason}) {
    return _postAction(
      '$_basePath/societies/$societyId/reactivate',
      {'reason': reason},
    );
  }

  Future<SuperAdminRevenueSnapshot> getRevenueAnalytics({
    DateTime? from,
    DateTime? to,
    String? currency,
    String? plan,
  }) async {
    final data = await _getMap(
      _endpoint('$_basePath/analytics/revenue', {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        if (currency != null) 'currency': currency,
        if (plan != null && plan != 'all') 'plan': plan,
      }),
    );
    return SuperAdminRevenueSnapshot.fromJson(data);
  }

  Future<SuperAdminSupportDashboard> getSupportDashboard({
    String status = 'open',
    String priority = 'all',
  }) async {
    final analytics = await _getMap('$_basePath/support/analytics');
    final tickets = await getSupportTickets(status: status, priority: priority);
    return SuperAdminSupportDashboard(
      summary: SuperAdminSupportSummary.fromJson(analytics),
      tickets: tickets,
    );
  }

  Future<List<SuperAdminSupportTicket>> getSupportTickets({
    String status = 'open',
    String priority = 'all',
    String? cursor,
  }) async {
    final data = await _getMap(
      _endpoint('$_basePath/support/tickets', {
        if (status != 'all') 'status': status,
        if (priority != 'all') 'priority': priority,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      }),
    );
    return _listFrom(data, ['tickets', 'items', 'data'])
        .map(SuperAdminSupportTicket.fromJson)
        .toList();
  }

  Future<void> assignTicket(
    String ticketId, {
    required String assigneeId,
    required String reason,
  }) {
    return _postAction(
      '$_basePath/support/tickets/$ticketId/assign',
      {'assigneeId': assigneeId, 'reason': reason},
    );
  }

  Future<void> addInternalNote(
    String ticketId, {
    required String note,
  }) {
    return _postAction(
      '$_basePath/support/tickets/$ticketId/internal-note',
      {'note': note},
    );
  }

  Future<void> resolveTicket(String ticketId, {required String resolution}) {
    return _postAction(
      '$_basePath/support/tickets/$ticketId/resolve',
      {'resolution': resolution},
    );
  }

  Future<List<SuperAdminHealthSignal>> getSystemHealth() async {
    final data = await _getMap('$_basePath/system-health');
    return _listFrom(data, ['services', 'health', 'items', 'data'])
        .map(SuperAdminHealthSignal.fromJson)
        .toList();
  }

  Future<List<SuperAdminActivity>> getAuditLogs({String? cursor}) async {
    final data = await _getMap(
      _endpoint('$_basePath/audit-logs', {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      }),
    );
    return _listFrom(data, ['logs', 'items', 'data'])
        .map(SuperAdminActivity.fromJson)
        .toList();
  }

  Future<List<JsonMap>> getPlatformUsers({String? q, String? role}) async {
    final data = await _getMap(
      _endpoint('$_basePath/users', {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (role != null && role != 'all') 'role': role,
      }),
    );
    return _listFrom(data, ['users', 'items', 'data']);
  }

  Future<List<JsonMap>> getPlans() async {
    final data = await _getMap('$_basePath/plans');
    return _listFrom(data, ['plans', 'items', 'data']);
  }

  Future<List<JsonMap>> getFeatures() async {
    final data = await _getMap('$_basePath/features');
    return _listFrom(data, ['features', 'items', 'data']);
  }

  Future<List<JsonMap>> getAnnouncements() async {
    final data = await _getMap('$_basePath/announcements');
    return _listFrom(data, ['announcements', 'items', 'data']);
  }

  Future<void> createAnnouncement(JsonMap payload) {
    return _postAction('$_basePath/announcements', payload);
  }

  Future<List<JsonMap>> getReports() async {
    final data = await _getMap('$_basePath/reports');
    return _listFrom(data, ['reports', 'items', 'data']);
  }

  Future<void> requestReport(JsonMap payload) {
    return _postAction('$_basePath/reports', payload);
  }

  Future<void> createPlan(JsonMap payload) =>
      _postAction('$_basePath/plans', payload);

  Future<JsonMap> createImpersonationSession({
    required String societyId,
    required String userId,
    required String reason,
    required int durationMinutes,
  }) {
    return _postMap('$_basePath/impersonation/sessions', {
      'societyId': societyId,
      'userId': userId,
      'reason': reason,
      'durationMinutes': durationMinutes,
    });
  }

  Future<void> stopImpersonationSession() {
    return _postAction('$_basePath/impersonation/sessions/current/stop', {});
  }

  Future<void> setFeatureOverride(
    String societyId,
    String featureKey,
    bool enabled,
  ) async {
    final response = await ApiService.patch(
      '$_basePath/societies/$societyId/features/$featureKey',
      {'enabled': enabled},
    );
    _decodeMap(response);
  }

  Future<JsonMap> _getMap(String endpoint) async {
    final response = await ApiService.get(endpoint);
    return _decodeMap(response);
  }

  Future<JsonMap> _postMap(String endpoint, JsonMap body) async {
    final response = await ApiService.post(endpoint, body);
    return _decodeMap(response);
  }

  Future<void> _postAction(String endpoint, JsonMap body) async {
    await _postMap(endpoint, body);
  }

  JsonMap _decodeMap(http.Response response) {
    final requestId = response.headers['x-request-id'] ??
        response.headers['x-correlation-id'];
    final dynamic decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMap = decoded is Map ? JsonMap.from(decoded) : const {};
      throw SuperAdminApiException(
        errorMap['message']?.toString() ??
            errorMap['error']?.toString() ??
            'Super Admin request failed',
        response.statusCode,
        requestId: requestId,
      );
    }

    if (decoded is List) return {'data': decoded};
    if (decoded is Map) {
      final map = JsonMap.from(decoded);
      final data = map['data'];
      if (data is Map) return JsonMap.from(data);
      if (data is List) return {'data': data};
      return map;
    }
    return const {};
  }

  String _endpoint(String path, Map<String, String> query) {
    if (query.isEmpty) return path;
    return Uri(path: path, queryParameters: query).toString();
  }

  List<JsonMap> _listFrom(JsonMap json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => JsonMap.from(item))
            .toList();
      }
    }
    return const [];
  }
}
