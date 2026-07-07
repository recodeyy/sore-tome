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

  /// Maps a Postgres `/amenities` row (the canonical source) to a [Facility].
  /// Fields: name, capacity, open_minutes/close_minutes (minutes from midnight),
  /// price_minor (paise), requires_approval.
  factory Facility.fromAmenity(Map<String, dynamic> map) {
    String hhmm(dynamic minutes) {
      final m = (minutes is num) ? minutes.toInt() : int.tryParse('$minutes') ?? 0;
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      return '$h:$mm';
    }

    final open = map['open_minutes'];
    final close = map['close_minutes'];
    final priceMinor = (map['price_minor'] is num)
        ? (map['price_minor'] as num).toDouble()
        : double.tryParse('${map['price_minor']}') ?? 0;
    final cap = map['capacity'];
    return Facility(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: [
        if (cap != null) 'Capacity $cap',
        if (map['requires_approval'] == true) 'Approval required',
      ].join(' • '),
      icon: 'event',
      hourlyRate: priceMinor / 100.0,
      availabilityHours: (open != null && close != null)
          ? '${hhmm(open)} - ${hhmm(close)}'
          : '09:00 - 21:00',
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
