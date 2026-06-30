import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/staff.dart';

final staffProvider = FutureProvider.autoDispose<List<Staff>>((ref) async {
  // CUTOVER: canonical Postgres `/staff-v2`. The legacy `/staff` route returns
  // an empty list under the Postgres backend, which left the guard home's staff
  // section permanently blank. Same `{ staff: [...] }` envelope; Staff.fromJson
  // maps the shared fields (id, name, role, phone).
  final res = await ApiService.get('/staff-v2');
  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    final List list = body['staff'] ?? [];
    return list.map((e) => Staff.fromJson(e)).toList();
  }
  throw Exception('Failed to load staff');
});
