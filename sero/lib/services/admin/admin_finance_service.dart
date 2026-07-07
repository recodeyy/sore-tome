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

  /// GET /finance/invoices — list of invoices. Optional [status] filter
  /// (e.g. `draft`, `published`, `paid`) is passed through to the backend.
  static Future<List<dynamic>> getInvoices({String? status, int? limit}) async {
    final qp = <String, String>{};
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (limit != null) qp['limit'] = '$limit';
    final query = qp.isEmpty
        ? ''
        : '?${qp.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final res = await ApiService.get('/finance/invoices$query');
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

  /// POST /finance/invoices — create a draft invoice with [lines]. Returns the
  /// created invoice row (`{ id, number, status: 'draft', total_minor, ... }`).
  /// Backend requires `number` and at least one line with `unitPriceMinor`.
  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> body) async {
    final res = await ApiService.post('/finance/invoices', body);
    final data = ApiService.unwrap(res);
    if (data is Map && data['invoice'] is Map) {
      return (data['invoice'] as Map).cast<String, dynamic>();
    }
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// POST /finance/invoices/:id/publish — publish a draft invoice and post it
  /// to the ledger. Throws on non-2xx (e.g. 409 if not in draft state).
  static Future<Map<String, dynamic>> publishInvoice(String id) async {
    final res = await ApiService.post('/finance/invoices/$id/publish', const {});
    final data = ApiService.unwrap(res);
    if (data is Map && data['invoice'] is Map) {
      return (data['invoice'] as Map).cast<String, dynamic>();
    }
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// POST /finance/payments — record a (manual) payment against an invoice.
  /// [amountMinor] is in paise. Idempotent on [idempotencyKey].
  static Future<Map<String, dynamic>> recordPayment({
    required String invoiceId,
    required int amountMinor,
    String? idempotencyKey,
  }) async {
    final res = await ApiService.post('/finance/payments', {
      'idempotencyKey':
          idempotencyKey ?? 'app-${DateTime.now().millisecondsSinceEpoch}-$invoiceId',
      'invoiceId': invoiceId,
      'amountMinor': amountMinor,
      'provider': 'manual',
    });
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
