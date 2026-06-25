import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

class Rule {
  final String id;
  final String title;
  final String content;

  Rule({required this.id, required this.title, required this.content});

  factory Rule.fromMap(Map<String, dynamic> map) {
    return Rule(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      // /rules-v2 (Postgres) returns the text in `body`; legacy used `content`.
      content: map['body'] ?? map['content'] ?? '',
    );
  }
}

final rulesProvider = StateNotifierProvider<RulesNotifier, AsyncValue<List<Rule>>>((ref) {
  return RulesNotifier();
});

class RulesNotifier extends StateNotifier<AsyncValue<List<Rule>>> {
  RulesNotifier() : super(const AsyncValue.loading()) {
    fetchRules();
  }

  // /rules-v2 validates category against this enum; map anything else to "rule".
  static const _v2Categories = {'bylaw', 'rule', 'noc', 'policy', 'other'};

  Future<void> fetchRules() async {
    state = const AsyncValue.loading();
    try {
      // CUTOVER: canonical Postgres endpoint (/rules-v2 → {rules:[{...,body}]}).
      final res = await ApiService.get('/rules-v2');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['rules'] as List? ?? const [])
            .map((x) => Rule.fromMap(x))
            .toList();
        state = AsyncValue.data(list);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch rules';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRule(String title, String content, String category) async {
    try {
      // /rules-v2 expects `body` (not legacy `content`) and an enum category.
      final res = await ApiService.post('/rules-v2', {
        'title': title,
        'body': content,
        'category': _v2Categories.contains(category) ? category : 'rule',
      });
      if (res.statusCode == 201) {
        await fetchRules();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to add rule';
      }
    } catch (e) {
      rethrow;
    }
  }
}



