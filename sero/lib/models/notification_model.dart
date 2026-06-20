import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'alert', 'info', 'success', 'warning'
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? map['body'] ?? '').toString(),
      type: (map['type'] ?? 'info').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      isRead: map['is_read'] == true || map['isRead'] == true,
    );
  }

  IconData get icon {
    switch (type) {
      case 'alert':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case 'alert':
        return const Color(0xFFEF4444);
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
