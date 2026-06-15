import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rules_service.dart';

class RulesState {
  final List<Map<String, dynamic>> allRules;
  final List<Map<String, dynamic>> filteredRules;
  final bool isLoading;
  final String searchQuery;

  RulesState({
    this.allRules = const [],
    this.filteredRules = const [],
    this.isLoading = false,
    this.searchQuery = "",
  });

  RulesState copyWith({
    List<Map<String, dynamic>>? allRules,
    List<Map<String, dynamic>>? filteredRules,
    bool? isLoading,
    String? searchQuery,
  }) {
    return RulesState(
      allRules: allRules ?? this.allRules,
      filteredRules: filteredRules ?? this.filteredRules,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, List<Map<String, dynamic>>> get groupedRules {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var rule in filteredRules) {
      final source = rule['source'] ?? "General Rules";
      if (!groups.containsKey(source)) groups[source] = [];
      groups[source]!.add(rule);
    }
    return groups;
  }
}

class RulesNotifier extends StateNotifier<RulesState> {
  RulesNotifier() : super(RulesState());

  Future<void> fetchRules() async {
    state = state.copyWith(isLoading: true);
    try {
      final rules = await RulesService.getRules();
      state = state.copyWith(
        allRules: rules,
        filteredRules: _applyFilterInternal(rules, state.searchQuery),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredRules: _applyFilterInternal(state.allRules, query),
    );
  }

  List<Map<String, dynamic>> _applyFilterInternal(List<Map<String, dynamic>> rules, String query) {
    if (query.isEmpty) return rules;
    
    return rules.where((rule) {
      final text = (rule['rule'] ?? "").toString().toLowerCase();
      final source = (rule['source'] ?? "").toString().toLowerCase();
      return text.contains(query.toLowerCase()) || 
             source.contains(query.toLowerCase());
    }).toList();
  }
}

final rulesProvider = StateNotifierProvider<RulesNotifier, RulesState>((ref) {
  return RulesNotifier();
});
