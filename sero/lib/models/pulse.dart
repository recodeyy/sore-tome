import 'package:cloud_firestore/cloud_firestore.dart';

class Pulse {
  final String id;
  final String content;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final bool isHighPriority;

  Pulse({
    required this.id,
    required this.content,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.isHighPriority = false,
  });

  factory Pulse.fromMap(Map<String, dynamic> map, String id) {
    return Pulse(
      id: id,
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? 'Admin',
      authorRole: map['authorRole'] ?? 'Secretary',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHighPriority: map['isHighPriority'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': FieldValue.serverTimestamp(),
      'isHighPriority': isHighPriority,
    };
  }
}
