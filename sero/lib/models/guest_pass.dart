import 'package:cloud_firestore/cloud_firestore.dart';

enum GuestPassStatus { pending, approved, arrived, expired, cancelled }
enum GuestPassCategory { delivery, guest, service, other }

class GuestPass {
  final String id;
  final String visitorName;
  final GuestPassCategory category;
  final GuestPassStatus status;
  final String residentId;
  final String residentName;
  final String flatNumber;
  final DateTime createdAt;
  final DateTime? arrivalTime;
  final String? phone;

  GuestPass({
    required this.id,
    required this.visitorName,
    required this.category,
    required this.status,
    required this.residentId,
    required this.residentName,
    required this.flatNumber,
    required this.createdAt,
    this.arrivalTime,
    this.phone,
  });

  factory GuestPass.fromMap(Map<String, dynamic> map, String id) {
    return GuestPass(
      id: id,
      visitorName: map['visitorName'] ?? '',
      category: GuestPassCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (map['category'] ?? 'guest'),
        orElse: () => GuestPassCategory.other,
      ),
      status: GuestPassStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => GuestPassStatus.pending,
      ),
      residentId: map['residentId'] ?? '',
      residentName: map['residentName'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      arrivalTime: (map['arrivalTime'] as Timestamp?)?.toDate(),
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorName': visitorName,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'residentId': residentId,
      'residentName': residentName,
      'flatNumber': flatNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'phone': phone,
    };
  }
}
