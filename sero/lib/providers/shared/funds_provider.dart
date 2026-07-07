import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/fund.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/local_database_service.dart';

final fundsProvider = StateNotifierProvider.autoDispose<FundsNotifier, AsyncValue<List<FundTransaction>>>((ref) {
  return FundsNotifier(ref);
});

final fundSummaryProvider = FutureProvider.autoDispose<FundSummary>((ref) async {
  try {
    final res = await ApiService.get('/funds/summary');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return FundSummary(
        totalCollected: (data['totalCollected'] ?? 0).toDouble(),
        totalSpent: (data['totalSpent'] ?? 0).toDouble(),
        outstandingDues: (data['outstandingDues'] ?? 0).toDouble(),
        overdueCount: (data['overdueCount'] ?? 0).toInt(),
        categoryBreakdown: (data['categoryBreakdown'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        topExpenseCategories: data['topCategories'] ?? 'None',
      );
    }
  } catch (e) {
    // Return empty summary on error to prevent UI crash
  }
  return FundSummary(totalCollected: 0, totalSpent: 0);
});

final overdueResidentsProvider = FutureProvider.autoDispose<List<OverdueResident>>((ref) async {
  final res = await ApiService.get('/funds/maintenance-status');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['unpaid'] as List).map((x) => OverdueResident.fromMap(x)).toList();
  }
  return [];
});

final residentBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return 0.0;
  
  try {
    final res = await ApiService.get('/funds/maintenance-status');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data['unpaid'] as List;
      final myEntry = list.firstWhere(
        (x) => x['name'] == user.name, // Simplified matching by name
        orElse: () => null,
      );
      return myEntry != null ? (myEntry['amount'] as num).toDouble() : 0.0;
    }
  } catch (e) {
    // Silent fail
  }
  return 0.0;
});

class FundsNotifier extends StateNotifier<AsyncValue<List<FundTransaction>>> {
  final Ref ref;
  final _localDb = LocalDatabaseService();

  FundsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    // 1. Load from Cache
    final user = ref.read(authProvider).value;
    if (user != null) {
      final cached = await _localDb.getItems('transactions', societyId: user.societyId);
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached.map((x) => FundTransaction.fromMap(x)).toList());
      }
    }

    try {
      final res = await ApiService.get('/funds/transactions');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['transactions'] as List).map((x) {
           return FundTransaction.fromMap(x);
        }).toList();
        
        state = AsyncValue.data(list);

        // 2. Save to Cache
        if (user != null) {
          await _localDb.saveItems('transactions', list.map((x) => x.toMap()).toList());
        }
      } else {
        if (state.hasValue) return;
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch funds';
      }
    } catch (e, st) {
      if (state.hasValue) {
        // Silent fail if we have cache
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addTransaction(FundTransaction tx) async {
    try {
      final res = await ApiService.post('/funds/transactions', tx.toMap());
      if (res.statusCode == 201) {
        fetchTransactions();
        ref.invalidate(fundSummaryProvider);
        ref.invalidate(overdueResidentsProvider);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to add transaction';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSettings({double? target, String? currency}) async {
    try {
      final res = await ApiService.post('/funds/settings', {
        if (target != null) 'target': target,
        if (currency != null) 'currency': currency,
      });

      if (res.statusCode == 200) {
        // Refresh summary after update
        ref.invalidate(fundSummaryProvider);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to update settings';
      }
    } catch (e) {
      rethrow;
    }
  }
}




