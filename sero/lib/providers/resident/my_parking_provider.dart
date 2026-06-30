import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';

/// A single active parking allocation belonging to the logged-in resident.
/// Backed by the Postgres cross-role flow: admin allocates a slot
/// (POST /parking/allocations) → it surfaces here via GET /parking/my.
class MyParkingAllocation {
  final String id;
  final String slotCode;
  final String slotType;
  final String slotLocation;
  final String vehiclePlate;
  final String vehicleType;
  final String makeModel;
  final String status;

  MyParkingAllocation({
    required this.id,
    required this.slotCode,
    required this.slotType,
    required this.slotLocation,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.makeModel,
    required this.status,
  });

  factory MyParkingAllocation.fromMap(Map<String, dynamic> m) =>
      MyParkingAllocation(
        id: (m['id'] ?? '').toString(),
        slotCode: (m['slot_code'] ?? '').toString(),
        slotType: (m['slot_type'] ?? '').toString(),
        slotLocation: (m['slot_location'] ?? '').toString(),
        vehiclePlate: (m['vehicle_plate'] ?? '').toString(),
        vehicleType: (m['vehicle_type'] ?? '').toString(),
        makeModel: (m['make_model'] ?? '').toString(),
        status: (m['status'] ?? '').toString(),
      );
}

/// The resident's active parking allocations (GET /parking/my).
final myParkingProvider =
    FutureProvider.autoDispose<List<MyParkingAllocation>>((ref) async {
  final res = await ApiService.get('/parking/my');
  if (res.statusCode != 200) {
    throw Exception(
        jsonDecode(res.body)['error'] ?? 'Failed to load your parking');
  }
  final rows = (jsonDecode(res.body)['allocations'] as List? ?? const []);
  return rows
      .map((r) => MyParkingAllocation.fromMap((r as Map).cast<String, dynamic>()))
      .toList();
});
