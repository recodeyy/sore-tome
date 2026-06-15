import 'issue.dart';

class DashboardStats {
  final int pendingApprovalsCount;
  final List<Issue> topIssues;
  final List<RecentUpdate> recentUpdates;
  final Financials financials;
  final int activeResidentsCount;
  final String updatedAt;

  DashboardStats({
    required this.pendingApprovalsCount,
    required this.topIssues,
    required this.recentUpdates,
    required this.financials,
    required this.activeResidentsCount,
    required this.updatedAt,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingApprovalsCount: json['pendingApprovalsCount'] ?? 0,
      topIssues: (json['topIssues'] as List?)
              ?.map((e) => Issue.fromMap(e))
              .toList() ??
          [],
      recentUpdates: (json['recentUpdates'] as List?)
              ?.map((e) => RecentUpdate.fromJson(e))
              .toList() ??
          [],
      financials: Financials.fromJson(json['financials'] ?? {}),
      activeResidentsCount: json['activeResidentsCount'] ?? 0,
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class RecentUpdate {
  final String id;
  final String type; // 'notice' | 'event'
  final String title;
  final String? body;
  final String? description;
  final DateTime? createdAt;
  final String? category;

  RecentUpdate({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.description,
    this.createdAt,
    this.category,
  });

  factory RecentUpdate.fromJson(Map<String, dynamic> json) {
    return RecentUpdate(
      id: json['id'] ?? '',
      type: json['type'] ?? 'notice',
      title: json['title'] ?? '',
      body: json['body'],
      description: json['description'],
      category: json['type'] == 'event' ? 'ESTATE EVENT' : (json['category'] ?? json['type']).toString().toUpperCase(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']['_seconds'] != null ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']['_seconds'] * 1000).toIso8601String() : json['createdAt'].toString()) : null,
    );
  }
}

class Financials {
  final double totalCollected;
  final double totalSpent;
  final double balance;
  final double target;
  final String currency;
  final int percentage;

  Financials({
    required this.totalCollected,
    required this.totalSpent,
    required this.balance,
    required this.target,
    required this.currency,
    required this.percentage,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      totalCollected: (json['totalCollected'] ?? 0).toDouble(),
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      target: (json['target'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'Rs',
      percentage: json['percentage'] ?? 0,
    );
  }
}


