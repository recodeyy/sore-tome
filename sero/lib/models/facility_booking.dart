class Facility {
  final String id;
  final String name;
  final String description;
  final String icon; // Icon name or category
  final double hourlyRate;
  final String availabilityHours; // e.g. "06:00 - 22:00"

  Facility({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.hourlyRate = 0,
    required this.availabilityHours,
  });

  factory Facility.fromMap(Map<String, dynamic> map, String id) {
    return Facility(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'event',
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      availabilityHours: map['availabilityHours'] ?? '09:00 - 21:00',
    );
  }
}

class Booking {
  final String id;
  final String facilityId;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'pending', 'confirmed', 'cancelled'

  Booking({
    required this.id,
    required this.facilityId,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      facilityId: map['facilityId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Resident',
      startTime: DateTime.tryParse(map['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(map['endTime'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'userId': userId,
      'userName': userName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
    };
  }
}
