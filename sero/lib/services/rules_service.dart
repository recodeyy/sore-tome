import 'dart:convert';
import 'api_client.dart';

class RulesService {
  static Future<List<Map<String, dynamic>>> getRules() async {
    try {
      final res = await ApiClient.request('GET', '/ai/rules');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['rules'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch rules: $e');
    }
  }
}
