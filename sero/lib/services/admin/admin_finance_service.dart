import 'package:sero/services/api_service.dart';

/// Service for Finance module API calls.
///
/// CUTOVER: backed by Postgres `/finance/*` routes. These endpoints return
/// raw JSON (not the `{success,data}` envelope); `ApiService.unwrap` returns
/// the decoded body as-is in that case.
class AdminFinanceService {
  /// GET /finance/reports/summary — totals (income/expense/collection/balance).
  static Future<Map<String, dynamic>> getSummary() async {
    final res = await ApiService.get('/finance/reports/summary');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /finance/reports/dues — outstanding invoices with ageing buckets.
  static Future<Map<String, dynamic>> getDues() async {
    final res = await ApiService.get('/finance/reports/dues');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /finance/reports/trial-balance — per-account debit/credit totals.
  static Future<Map<String, dynamic>> getTrialBalance() async {
    final res = await ApiService.get('/finance/reports/trial-balance');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /finance/invoices — list of invoices.
  static Future<List<dynamic>> getInvoices() async {
    final res = await ApiService.get('/finance/invoices');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['invoices'] is List) return data['invoices'] as List;
    return const [];
  }

  /// GET /finance/invoices/:id — single invoice detail.
  static Future<Map<String, dynamic>> getInvoice(String id) async {
    final res = await ApiService.get('/finance/invoices/$id');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /finance/expenses — list of expenses.
  static Future<List<dynamic>> getExpenses() async {
    final res = await ApiService.get('/finance/expenses');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['expenses'] is List) return data['expenses'] as List;
    return const [];
  }

  /// POST /finance/invoices — create/generate an invoice (bill).
  static Future<bool> generateBills(Map<String, dynamic> params) async {
    final res = await ApiService.post('/finance/invoices', params);
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
