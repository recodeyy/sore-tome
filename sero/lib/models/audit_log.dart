import 'package:intl/intl.dart';

enum AuditLogType {
  administrative,
  security,
  system,
  all;

  String get label {
    switch (this) {
      case AuditLogType.administrative: return 'Admin';
      case AuditLogType.security: return 'Security';
      case AuditLogType.system: return 'System';
      case AuditLogType.all: return 'All';
    }
  }
}

class AuditLogEntry {
  final String id;
  final AuditLogType type;
  final String action;
  final String actorName;
  final String details;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AuditLogEntry({
    required this.id,
    required this.type,
    required this.action,
    required this.actorName,
    required this.details,
    required this.createdAt,
    this.metadata,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      action: json['action'] as String? ?? 'Action',
      actorName: json['actorName'] as String? ?? 'System',
      details: json['details'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static AuditLogType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'administrative': return AuditLogType.administrative;
      case 'security': return AuditLogType.security;
      case 'system': return AuditLogType.system;
      default: return AuditLogType.system;
    }
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM dd').format(createdAt);
  }
}


