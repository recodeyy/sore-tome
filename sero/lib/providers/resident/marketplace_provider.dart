import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// A marketplace listing posted by a resident (GET /community/marketplace).
class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final int priceMinor;
  final String category;
  final String status;
  final String posterName;
  final String createdAt;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceMinor,
    required this.category,
    required this.status,
    required this.posterName,
    required this.createdAt,
  });

  factory MarketplaceItem.fromMap(Map<String, dynamic> m) => MarketplaceItem(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        priceMinor: int.tryParse((m['price_minor'] ?? 0).toString()) ?? 0,
        category: (m['category'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
        posterName: (m['poster_name'] ?? '').toString(),
        createdAt: (m['created_at'] ?? '').toString(),
      );
}

/// Marketplace listings for the resident's society.
final marketplaceProvider =
    FutureProvider.autoDispose<List<MarketplaceItem>>((ref) async {
  final res = await ApiService.get('/community/marketplace');
  if (res.statusCode != 200) {
    throw Exception(
        jsonDecode(res.body)['error'] ?? 'Failed to load marketplace');
  }
  final rows = (jsonDecode(res.body)['items'] as List? ?? const []);
  return rows
      .map((r) => MarketplaceItem.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
