class FundTransaction {
  final String id;
  final String title;
  final String description;
  final double amount; // positive = credit, negative = debit
  final DateTime date;
  final String category; // Added for V3.9
  final String createdBy; // Added for V3.9
  final String? transactionId; // Added for V3.9 Action IDs

  FundTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'Other',
    this.createdBy = '',
    this.transactionId,
  });

  bool get isCredit => amount > 0;

  factory FundTransaction.fromMap(Map<String, dynamic> map) {
    return FundTransaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['note'] ?? map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.tryParse(map['createdAt'] ?? map['date'] ?? '') ?? DateTime.now(),
      category: map['category'] ?? 'Other',
      createdBy: map['addedBy'] ?? map['createdBy'] ?? '',
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': description,
      'amount': amount.abs(),
      'type': amount >= 0 ? 'credit' : 'debit',
      'date': date.toIso8601String(),
      'category': category,
      'addedBy': createdBy,
      'transactionId': transactionId,
    };
  }
}

class FundSummary {
  final double totalCollected;
  final double totalSpent;
  final Map<String, double> categoryBreakdown;
  final double outstandingDues;
  final int overdueCount;
  final String topExpenseCategories;

  FundSummary({
    required this.totalCollected,
    required this.totalSpent,
    this.categoryBreakdown = const {},
    this.outstandingDues = 0,
    this.overdueCount = 0,
    this.topExpenseCategories = 'None',
  });

  double get remaining => totalCollected - totalSpent;
  double get percentRemaining =>
      totalCollected > 0 ? remaining / totalCollected : 0;
}

class OverdueResident {
  final String uid;
  final String name;
  final String unitInfo;
  final double amountOwed;
  final int monthsOverdue;

  OverdueResident({
    required this.uid,
    required this.name,
    required this.unitInfo,
    required this.amountOwed,
    required this.monthsOverdue,
  });

  factory OverdueResident.fromMap(Map<String, dynamic> map) {
    return OverdueResident(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      unitInfo: map['unitInfo'] ?? '',
      amountOwed: (map['amountOwed'] ?? 0).toDouble(),
      monthsOverdue: (map['monthsOverdue'] ?? 0).toInt(),
    );
  }
}


