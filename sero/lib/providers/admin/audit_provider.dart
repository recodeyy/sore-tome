import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/audit_log.dart';

final auditLogsProvider = AsyncNotifierProvider.family<AuditLogsNotifier, List<AuditLogEntry>, AuditLogType>(() {
  return AuditLogsNotifier();
});

class AuditLogsNotifier extends FamilyAsyncNotifier<List<AuditLogEntry>, AuditLogType> {
  @override
  Future<List<AuditLogEntry>> build(AuditLogType arg) async {
    return _fetchLogs(arg);
  }

  Future<List<AuditLogEntry>> _fetchLogs(AuditLogType type) async {
    final typeStr = type == AuditLogType.all ? 'all' : type.name;
    
    final response = await ApiService.get('/admin/access-logs?type=$typeStr');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List logsJson = data['logs'];
      return logsJson.map((j) => AuditLogEntry.fromJson(j)).toList();
    } else {
      throw Exception('Failed to load audit logs');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLogs(arg));
  }

  Future<void> logVisitor({
    required String name,
    required String purpose,
    String? phone,
  }) async {
    final response = await ApiService.post('/admin/access-logs/visitor', {
      'visitorName': name,
      'purpose': purpose,
      'phone': phone,
    });

    if (response.statusCode == 201) {
      ref.invalidateSelf();
    } else {
      throw Exception('Failed to log visitor');
    }
  }
}



