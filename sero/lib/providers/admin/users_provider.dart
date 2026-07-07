import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/user.dart';

final pendingUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final res = await ApiService.get('/auth/pending');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['pending'] as List).map((x) => UserModel.fromMap(x)).toList();
  }
  return [];
});

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final res = await ApiService.get('/users');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['users'] as List).map((x) => UserModel.fromMap(x)).toList();
  }
  return [];
});

final userOperationsProvider = Provider((ref) => UserOperations(ref));

class UserOperations {
  final Ref ref;
  UserOperations(this.ref);

  Future<void> approveUser(String uid) async {
    final res = await ApiService.post('/auth/approve/$uid', {});
    if (res.statusCode != 200) throw Exception('Failed to approve');
    ref.invalidate(pendingUsersProvider);
    ref.invalidate(allUsersProvider);
  }

  Future<void> rejectUser(String uid, String reason) async {
    final res = await ApiService.post('/auth/reject/$uid', {'reason': reason});
    if (res.statusCode != 200) throw Exception('Failed to reject');
    ref.invalidate(pendingUsersProvider);
    ref.invalidate(allUsersProvider);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final res = await ApiService.patch('/users/$uid', data);
    if (res.statusCode != 200) throw Exception('Failed to update user');
    ref.invalidate(allUsersProvider);
  }
}



