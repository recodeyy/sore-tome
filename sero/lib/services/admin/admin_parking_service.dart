import 'package:sero/services/api_service.dart';

/// Service for Parking management.
class AdminParkingService {
  // TODO: Connect to backend for parking allocation
  
  /// Fetches parking slots and their status.
  static Future<List<dynamic>> getParkingSlots() async {
    // TODO: GET /admin/parking/slots
    return [];
  }

  /// Allocates a parking slot to a resident.
  static Future<bool> allocateSlot(String slotId, String residentId) async {
    // TODO: POST /admin/parking/allocate
    return false;
  }
}
