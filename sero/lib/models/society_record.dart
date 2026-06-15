import 'package:cloud_firestore/cloud_firestore.dart';

class SocietyRecord {
  final String id;
  final String title;
  final String description; // e.g. "PDF • 4.2 MB" or date
  final String fileUrl;
  final String category; // e.g. "Governance", "MOM", "Guidelines"
  final DateTime createdAt;
  final bool isAiSummarized;

  SocietyRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.category,
    required this.createdAt,
    this.isAiSummarized = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAiSummarized': isAiSummarized,
    };
  }

  factory SocietyRecord.fromMap(Map<String, dynamic> map, String id) {
    return SocietyRecord(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      category: map['category'] ?? 'General',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAiSummarized: map['isAiSummarized'] ?? false,
    );
  }
}
