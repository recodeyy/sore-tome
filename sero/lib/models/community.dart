import 'package:cloud_firestore/cloud_firestore.dart';

/// A single poll option in the v2 (Postgres) shape: UUID id + label + tally.
/// The legacy Firestore polls keyed votes by option index, so for those the
/// id is just the stringified index and [count] comes from the votes map.
class PollOption {
  final String id; // v2: option UUID; legacy: option index as string
  final String label; // option text
  final int count; // votes for this option

  const PollOption({required this.id, required this.label, this.count = 0});
}

class Poll {
  final String id;
  final String question;
  final List<String> options; // option labels (kept for legacy widgets)
  final Map<String, int> votes; // legacy: optionIndex -> count
  final List<String> votedUsers;
  final DateTime createdAt;
  final bool isActive;

  /// v2 options carrying the real option UUIDs needed to cast a vote against
  /// `/polls-v2/:id/vote` ({ optionId }). Empty for legacy Firestore polls.
  final List<PollOption> pollOptions;

  /// Whether the current requester has already voted (v2 detail provides this).
  final bool hasVoted;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.votedUsers,
    required this.createdAt,
    this.isActive = true,
    this.pollOptions = const [],
    this.hasVoted = false,
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

  /// Builds a Poll from the canonical Postgres `/polls-v2` shape.
  ///
  /// [poll] is a `polls` row (snake_case: title, status, created_at, ...).
  /// [options] is the merged option list — labels from `/polls-v2/:id` and
  /// per-option `count` from `/polls-v2/:id/results` (each has id + label).
  factory Poll.fromV2(
    Map<String, dynamic> poll, {
    List<PollOption> options = const [],
    bool hasVoted = false,
  }) {
    // Map option-id -> count so the legacy `votes[index]` lookups still resolve
    // (existing widgets index votes by option position).
    final votes = <String, int>{};
    for (var i = 0; i < options.length; i++) {
      votes[i.toString()] = options[i].count;
    }
    return Poll(
      id: poll['id']?.toString() ?? '',
      question: (poll['title'] ?? poll['question'] ?? '').toString(),
      options: options.map((o) => o.label).toList(),
      votes: votes,
      votedUsers: const [],
      createdAt: DateTime.tryParse(
            (poll['created_at'] ?? poll['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      // v2 lifecycle: draft | open | closed. Only `open` accepts votes.
      isActive: (poll['status']?.toString() ?? '') == 'open',
      pollOptions: options,
      hasVoted: hasVoted,
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
