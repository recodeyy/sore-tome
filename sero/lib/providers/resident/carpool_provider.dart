import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// A carpool ride offer posted by a resident (GET /community/carpool).
class CarpoolRide {
  final String id;
  final String fromLocation;
  final String toLocation;
  final String rideTime;
  final int seats;
  final String notes;
  final String status;
  final String posterName;
  final String createdAt;

  CarpoolRide({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.rideTime,
    required this.seats,
    required this.notes,
    required this.status,
    required this.posterName,
    required this.createdAt,
  });

  factory CarpoolRide.fromMap(Map<String, dynamic> m) => CarpoolRide(
        id: (m['id'] ?? '').toString(),
        fromLocation: (m['from_location'] ?? '').toString(),
        toLocation: (m['to_location'] ?? '').toString(),
        rideTime: (m['ride_time'] ?? '').toString(),
        seats: int.tryParse((m['seats'] ?? 0).toString()) ?? 0,
        notes: (m['notes'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
        posterName: (m['poster_name'] ?? '').toString(),
        createdAt: (m['created_at'] ?? '').toString(),
      );
}

/// Carpool rides for the resident's society.
final carpoolProvider =
    FutureProvider.autoDispose<List<CarpoolRide>>((ref) async {
  final res = await ApiService.get('/community/carpool');
  if (res.statusCode != 200) {
    throw Exception(jsonDecode(res.body)['error'] ?? 'Failed to load carpool');
  }
  final rows = (jsonDecode(res.body)['rides'] as List? ?? const []);
  return rows
      .map((r) => CarpoolRide.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
