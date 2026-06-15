import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/visitor.dart';

final visitorsProvider = StateNotifierProvider.autoDispose<VisitorsNotifier, AsyncValue<List<Visitor>>>((ref) {
  return VisitorsNotifier();
});

class VisitorsNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  VisitorsNotifier() : super(const AsyncValue.loading()) {
    fetchVisitors();
  }

  Future<void> fetchVisitors() async {
    try {
      final res = await ApiService.get('/visitors');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['visitors'] as List).map((x) => Visitor.fromMap(x)).toList();
        state = AsyncValue.data(list);
      } else {
        throw Exception('Failed to fetch visitors');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logVisitor(Visitor visitor) async {
    try {
      final res = await ApiService.post('/visitors/checkin', visitor.toMap());
      if (res.statusCode == 201) {
        fetchVisitors(); // Refresh list
      } else {
        throw Exception('Failed to log visitor');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> actionVisitor(String id, String action) async {
    try {
      final res = await ApiService.patch('/visitors/$id/action', {'action': action});
      if (res.statusCode == 200) {
        fetchVisitors(); // Refresh list
      } else {
        throw Exception('Failed to $action visitor');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkoutVisitor(String id) async {
    try {
      final res = await ApiService.patch('/visitors/$id/checkout', {});
      if (res.statusCode == 200) {
        fetchVisitors(); // Refresh list
      } else {
        throw Exception('Failed to checkout visitor');
      }
    } catch (e) {
      rethrow;
    }
  }
}
