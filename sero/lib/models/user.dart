class UserModel {
  final String id;
  final String name;
  final String phone;
  final String flatNumber;
  final String block;
  final String role;
  final String status;
  final String residentType;
  final bool maintenanceExempt;
  final String societyId;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatNumber,
    required this.block,
    required this.role,
    required this.status,
    required this.societyId,
    this.residentType = 'owner',
    this.maintenanceExempt = false,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      block: map['blockName'] ?? map['block'] ?? '',
      role: map['role'] ?? 'resident',
      status: map['status'] ?? 'pending',
      societyId: map['society_id'] ?? '',
      residentType: map['residentType'] ?? 'owner',
      maintenanceExempt: map['maintenanceExempt'] ?? false,
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'phone': phone,
      'flatNumber': flatNumber,
      'blockName': block,
      'role': role,
      'status': status,
      'society_id': societyId,
      'residentType': residentType,
      'maintenanceExempt': maintenanceExempt,
      'photoUrl': photoUrl,
    };
  }
}


