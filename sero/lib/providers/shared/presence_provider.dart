import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPresence {
  final String userId;
  final String name;
  final String role;
  final bool isOnline;
  final bool isTyping;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.name,
    this.role = 'resident',
    this.isOnline = false,
    this.isTyping = false,
    required this.lastSeen,
  });

  factory UserPresence.fromMap(Map<String, dynamic> map, String id) {
    return UserPresence(
      userId: id,
      name: map['name'] ?? 'Resident',
      role: map['role'] ?? 'resident',
      isOnline: map['isOnline'] ?? false,
      isTyping: map['isTyping'] ?? false,
      lastSeen: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final presenceProvider = StreamProvider.family<List<UserPresence>, String>((ref, channelId) {
  return FirebaseFirestore.instance
      .collection('channels')
      .doc(channelId)
      .collection('presence')
      .snapshots()
      .map((snap) {
        final now = DateTime.now();
        return snap.docs.map((doc) => UserPresence.fromMap(doc.data(), doc.id))
            .where((p) => now.difference(p.lastSeen).inSeconds < 45) // Basic "Offline" filter
            .toList();
      });
});




