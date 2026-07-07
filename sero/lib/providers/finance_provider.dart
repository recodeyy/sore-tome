import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class FinanceState {
  final Map<String, dynamic>? analysis;
  final bool isLoading;
  final String errorMessage;
  final DateTime? lastFetchTime;

  FinanceState({
    this.analysis,
    this.isLoading = false,
    this.errorMessage = "",
    this.lastFetchTime,
  });

  FinanceState copyWith({
    Map<String, dynamic>? analysis,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastFetchTime,
  }) {
    return FinanceState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(FinanceState());

  static const int _cacheTtlMinutes = 10; 

  Future<void> fetchFinanceAnalysis({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid()) return;

    state = state.copyWith(isLoading: true, errorMessage: "");

    try {
      final res = await ApiClient.request('GET', '/ai/finance-analysis');
      if (res.statusCode == 200) {
        state = state.copyWith(
          analysis: jsonDecode(res.body),
          lastFetchTime: DateTime.now(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(errorMessage: "Failed to load insights", isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Connection error", isLoading: false);
    }
  }

  bool _isCacheValid() {
    if (state.analysis == null || state.lastFetchTime == null) return false;
    final diff = DateTime.now().difference(state.lastFetchTime!);
    return diff.inMinutes < _cacheTtlMinutes;
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
