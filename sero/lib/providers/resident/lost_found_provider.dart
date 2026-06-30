import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// A lost or found item posted by a resident (GET /community/lost-found).
class LostFoundItem {
  final String id;
  final String kind; // 'lost' | 'found'
  final String title;
  final String description;
  final String location;
  final String status;
  final String posterName;
  final String createdAt;

  LostFoundItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.posterName,
    required this.createdAt,
  });

  factory LostFoundItem.fromMap(Map<String, dynamic> m) => LostFoundItem(
        id: (m['id'] ?? '').toString(),
        kind: (m['kind'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        location: (m['location'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
        posterName: (m['poster_name'] ?? '').toString(),
        createdAt: (m['created_at'] ?? '').toString(),
      );
}

/// Lost & found items for the resident's society.
final lostFoundProvider =
    FutureProvider.autoDispose<List<LostFoundItem>>((ref) async {
  final res = await ApiService.get('/community/lost-found');
  if (res.statusCode != 200) {
    throw Exception(
        jsonDecode(res.body)['error'] ?? 'Failed to load lost & found');
  }
  final rows = (jsonDecode(res.body)['items'] as List? ?? const []);
  return rows
      .map((r) => LostFoundItem.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
