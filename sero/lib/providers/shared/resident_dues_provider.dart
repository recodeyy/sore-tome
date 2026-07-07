import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/models/fund.dart';

/// The signed-in resident's own outstanding maintenance dues.
///
/// LIVE DATA: GET /funds/maintenance-status -> `unpaid[]` entries
/// (computed server-side from `users` + `transactions` in Firestore).
/// We match the current user by uid (falling back to name) and read the
/// server's `amountOwed` / `monthsOverdue` fields.
class ResidentDues {
  final double amountOwed;
  final int monthsOverdue;
  final String unitInfo;

  const ResidentDues({
    this.amountOwed = 0,
    this.monthsOverdue = 0,
    this.unitInfo = '',
  });

  bool get hasDues => amountOwed > 0;
}

final residentDuesProvider = FutureProvider.autoDispose<ResidentDues>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const ResidentDues();

  // PRIMARY source: /funds/summary -> `outstandingDues` is THIS resident's own
  // authoritative due (server-computed). Robust regardless of the list-matching
  // quirks in /funds/maintenance-status.
  double amountOwed = 0;
  try {
    final sres = await ApiService.get('/funds/summary');
    if (sres.statusCode == 200) {
      final sdata = jsonDecode(sres.body) as Map<String, dynamic>;
      amountOwed = (sdata['outstandingDues'] ?? 0).toDouble();
    }
  } catch (_) {/* fall through to maintenance-status */}

  // ENRICH (months overdue / unit label) from the per-resident list, and use it
  // as a fallback if /funds/summary did not yield a due.
  int monthsOverdue = 0;
  String unitInfo = '';
  try {
    final res = await ApiService.get('/funds/maintenance-status');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final unpaid = (data['unpaid'] as List?) ?? const [];
      final mine = unpaid.cast<Map<String, dynamic>>().where((x) {
        return x['uid'] == user.id ||
            (x['name'] != null && x['name'] == user.name) ||
            (x['flatNumber'] != null && x['flatNumber'] == user.flatNumber);
      }).toList();
      if (mine.isNotEmpty) {
        final entry = mine.first;
        monthsOverdue = (entry['monthsOverdue'] ?? 0).toInt();
        unitInfo = (entry['unitInfo'] ?? '').toString();
        if (amountOwed == 0) {
          amountOwed = (entry['amountOwed'] ?? entry['amount'] ?? 0).toDouble();
        }
      }
    }
  } catch (_) {/* summary value (if any) still stands */}

  return ResidentDues(amountOwed: amountOwed, monthsOverdue: monthsOverdue, unitInfo: unitInfo);
});

/// The resident's own ledger of recorded payments (credits attributed to them).
///
/// LIVE DATA: GET /funds/transactions -> `transactions[]`, filtered client-side
/// to credits added by this user (their maintenance payments / receipts).
final residentPaymentsProvider =
    FutureProvider.autoDispose<List<FundTransaction>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const [];

  final res = await ApiService.get('/funds/transactions');
  if (res.statusCode != 200) return const [];

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final list = (data['transactions'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .map(FundTransaction.fromMap)
      .where((t) => t.createdBy == user.id && t.amount > 0)
      .toList();
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});
