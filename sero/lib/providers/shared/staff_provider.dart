import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/staff.dart';

final staffProvider = FutureProvider.autoDispose<List<Staff>>((ref) async {
  final res = await ApiService.get('/staff');
  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    final List list = body['staff'] ?? [];
    return list.map((e) => Staff.fromJson(e)).toList();
  }
  throw Exception('Failed to load staff');
});
