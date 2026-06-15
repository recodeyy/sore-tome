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
      content: map['content'] ?? '',
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

  Future<void> fetchRules() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.get('/rules');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['rules'] as List).map((x) => Rule.fromMap(x)).toList();
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
      final res = await ApiService.post('/rules', {
        'title': title,
        'content': content,
        'category': category,
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



