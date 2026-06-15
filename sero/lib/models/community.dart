import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // optionIndex -> count
  final List<String> votedUsers;
  final DateTime createdAt;
  final bool isActive;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.votedUsers,
    required this.createdAt,
    this.isActive = true,
  });

  factory Poll.fromMap(Map<String, dynamic> map, String id) {
    return Poll(
      id: id,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      votes: Map<String, int>.from(map['votes'] ?? {}),
      votedUsers: List<String>.from(map['votedUsers'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'votedUsers': votedUsers,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}

class CommitteeMember {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;
  final String? phoneNumber;

  CommitteeMember({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phoneNumber,
  });

  factory CommitteeMember.fromMap(Map<String, dynamic> map, String id) {
    return CommitteeMember(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      avatarUrl: map['avatarUrl'],
      phoneNumber: map['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
    };
  }
}
