class Notice {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String tag; // 'new', 'today', 'info'

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.tag = 'info',
  });

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      tag: map['tag'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'tag': tag,
    };
  }
}


