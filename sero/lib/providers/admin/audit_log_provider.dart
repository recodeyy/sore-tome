import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../services/api_client.dart';

class AuditLog {
  final String actionId;
  final String toolId;
  final String userId;
  final String action;
  final String status;
  final String createdAt;
  final String? errorMessage;
  final num? latencyMs;

  AuditLog({
    required this.actionId,
    required this.toolId,
    required this.userId,
    required this.action,
    required this.status,
    required this.createdAt,
    this.errorMessage,
    this.latencyMs,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      actionId: map['action_id'] ?? '',
      toolId: map['tool_id'] ?? '',
      userId: map['user_id'] ?? '',
      action: map['action'] ?? '',
      status: map['status'] ?? 'unknown',
      createdAt: map['created_at'] ?? '',
      errorMessage: map['error_message'],
      latencyMs: map['latency_ms'],
    );
  }
}

class AuditLogState {
  final List<AuditLog> logs;
  final bool isLoading;
  final bool hasAnomaly;
  final String? anomalyMessage;
  final String? error;

  AuditLogState({
    this.logs = const [],
    this.isLoading = false,
    this.hasAnomaly = false,
    this.anomalyMessage,
    this.error,
  });

  AuditLogState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    bool? hasAnomaly,
    String? anomalyMessage,
    String? error,
  }) {
    return AuditLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      hasAnomaly: hasAnomaly ?? this.hasAnomaly,
      anomalyMessage: anomalyMessage ?? this.anomalyMessage,
      error: error ?? this.error,
    );
  }
}

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  AuditLogNotifier() : super(AuditLogState());

  Future<void> fetchLogs({int offset = 0, int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await ApiClient.request('GET', '/ai/logs?limit=$limit&offset=$offset');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newLogs = (data['logs'] as List).map((l) => AuditLog.fromMap(l)).toList();
        
        state = state.copyWith(
          logs: offset == 0 ? newLogs : [...state.logs, ...newLogs],
          hasAnomaly: data['hasAnomaly'] ?? false,
          anomalyMessage: data['anomalyMessage'],
          isLoading: false,
        );
      } else {
        final errorData = jsonDecode(res.body);
        state = state.copyWith(
          error: errorData['error'] ?? 'Failed to fetch logs',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Network error fetching audit logs',
        isLoading: false,
      );
    }
  }

  Future<void> exportCsv() async {
    // Legacy stub
  }
}

final auditLogProvider = StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  return AuditLogNotifier();
});
