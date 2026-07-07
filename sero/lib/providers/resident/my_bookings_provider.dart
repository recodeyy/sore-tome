import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// An amenity booking belonging to the logged-in resident
/// (GET /amenities/bookings/mine).
class MyBooking {
  final String id;
  final String amenityId;
  final String amenityName;
  final String startAt;
  final String endAt;
  final String status;
  final String createdAt;

  MyBooking({
    required this.id,
    required this.amenityId,
    required this.amenityName,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.createdAt,
  });

  factory MyBooking.fromMap(Map<String, dynamic> m) => MyBooking(
        id: (m['id'] ?? '').toString(),
        amenityId: (m['amenity_id'] ?? '').toString(),
        amenityName: (m['amenity_name'] ?? '').toString(),
        startAt: (m['start_at'] ?? '').toString(),
        endAt: (m['end_at'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
        createdAt: (m['created_at'] ?? '').toString(),
      );
}

/// The resident's amenity bookings.
final myBookingsProvider =
    FutureProvider.autoDispose<List<MyBooking>>((ref) async {
  final res = await ApiService.get('/amenities/bookings/mine');
  if (res.statusCode != 200) {
    throw Exception(
        jsonDecode(res.body)['error'] ?? 'Failed to load your bookings');
  }
  final rows = (jsonDecode(res.body)['bookings'] as List? ?? const []);
  return rows
      .map((r) => MyBooking.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
