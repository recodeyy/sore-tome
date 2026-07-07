import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// A society document (read-only list, GET /rules-v2/documents).
class SocietyDocument {
  final String id;
  final String title;
  final String docType;
  final String createdAt;

  SocietyDocument({
    required this.id,
    required this.title,
    required this.docType,
    required this.createdAt,
  });

  factory SocietyDocument.fromMap(Map<String, dynamic> m) => SocietyDocument(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        docType: (m['doc_type'] ?? '').toString(),
        createdAt: (m['created_at'] ?? '').toString(),
      );
}

/// Society documents (read-only).
final documentsProvider =
    FutureProvider.autoDispose<List<SocietyDocument>>((ref) async {
  final res = await ApiService.get('/rules-v2/documents');
  if (res.statusCode != 200) {
    throw Exception(
        jsonDecode(res.body)['error'] ?? 'Failed to load documents');
  }
  final rows = (jsonDecode(res.body)['documents'] as List? ?? const []);
  return rows
      .map((r) => SocietyDocument.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
