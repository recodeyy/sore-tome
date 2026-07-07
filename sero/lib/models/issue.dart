class Issue {
  final String id;
  final String title;
  final String description;
  final String postedBy;
  final DateTime createdAt;
  final String status; // 'open', 'in_progress', 'resolved'
  final String priority; // 'high', 'medium', 'low'

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.postedBy,
    required this.createdAt,
    this.status = 'open',
    this.priority = 'medium',
  });

  factory Issue.fromMap(Map<String, dynamic> map) {
    // Parses both the v2 `/complaints` Postgres shape (snake_case:
    // created_by, created_at) and the legacy/cached camelCase shape.
    return Issue(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      postedBy: map['created_by'] ?? map['postedBy'] ?? '',
      createdAt: DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    // Persisted to the local cache; re-read by fromMap which accepts both
    // snake_case (v2) and camelCase, so the camelCase keys here round-trip.
    return {
      'id': id,
      'title': title,
      'description': description,
      'postedBy': postedBy,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'priority': priority,
    };
  }
}


