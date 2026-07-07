import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

// AI Rules Provider
// ✅ BUG-13 FIX: Throws on non-200 so FutureProvider enters error state.
// UI can use .error() handler to show a retry widget instead of silent empty list.
final aiRulesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiService.get('/ai/rules');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['rules'] as List<dynamic>;
  }
  throw Exception('Failed to load AI rules (HTTP ${response.statusCode})');
});

// AI Stats Provider
// ✅ BUG-13 FIX: Throws on non-200 — admin home handles .error() with a graceful fallback text.
final aiStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiService.get('/ai/stats');
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception('Failed to load AI stats (HTTP ${response.statusCode})');
});

// Finance Analysis Provider
// ✅ BUG-13 FIX: Throws on non-200 — admin home hides the widget on error (.error => SizedBox.shrink).
final financeAnalysisProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiService.get('/ai/finance-analysis');
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception('Failed to load finance analysis (HTTP ${response.statusCode})');
});

final aiJobsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // V3.12: Fetch active background indexing jobs
  final res = await ApiService.get('/ai/digest'); // Reuse digest which includes activeIndexing
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['activeIndexing'] ?? []);
  }
  return [];
});



