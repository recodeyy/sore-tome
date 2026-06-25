class Visitor {
  final String id;
  final String name;
  final String type; // delivery, guest, cab, maid
  final String targetFlat;
  final String vehicleNumber;
  final String phone;
  final String status; // pending, approved, denied, checked_out
  final DateTime entryTime;
  final DateTime? exitTime;

  Visitor({
    required this.id,
    required this.name,
    required this.type,
    required this.targetFlat,
    required this.vehicleNumber,
    required this.phone,
    required this.status,
    required this.entryTime,
    this.exitTime,
  });

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'guest',
      targetFlat: map['targetFlat'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      phone: map['phone'] ?? '',
      status: map['status'] ?? 'pending',
      entryTime: map['entryTime'] != null
          ? DateTime.tryParse(map['entryTime']) ?? DateTime.now()
          : DateTime.now(),
      exitTime: map['exitTime'] != null ? DateTime.tryParse(map['exitTime']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'targetFlat': targetFlat,
      'vehicleNumber': vehicleNumber,
      'phone': phone,
    };
  }
}
