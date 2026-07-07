import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';

class InvoicesState {
  final List<Invoice> invoices;
  final bool isLoading;
  final String errorMessage;

  InvoicesState({
    this.invoices = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  InvoicesState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class InvoicesNotifier extends StateNotifier<InvoicesState> {
  InvoicesNotifier() : super(InvoicesState());

  Future<void> fetch({String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final query = status != null ? '?status=$status' : '';
      final res = await ApiClient.request('GET', '/finance/invoices$query');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final invoices = (data['invoices'] as List)
            .map((j) => Invoice.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(invoices: invoices, isLoading: false);
      } else {
        state = state.copyWith(errorMessage: 'Failed to load invoices', isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(errorMessage: 'Connection error', isLoading: false);
    }
  }

  /// Creates a draft invoice. `lines` use minor units (paise). Returns the new id, or null on failure.
  Future<String?> createInvoice({
    required String number,
    required List<Map<String, dynamic>> lines,
    String? memberId,
    String? unitId,
    String? period,
    String? dueDate,
  }) async {
    final res = await ApiClient.request('POST', '/finance/invoices', body: {
      'number': number,
      'lines': lines,
      if (memberId != null) 'memberId': memberId,
      if (unitId != null) 'unitId': unitId,
      if (period != null) 'period': period,
      if (dueDate != null) 'dueDate': dueDate,
    });
    if (res.statusCode == 201) {
      await fetch();
      return (jsonDecode(res.body)['invoice']?['id']) as String?;
    }
    return null;
  }

  Future<bool> publish(String invoiceId) async {
    final res = await ApiClient.request('POST', '/finance/invoices/$invoiceId/publish');
    if (res.statusCode == 200) {
      await fetch();
      return true;
    }
    return false;
  }

  /// Records a payment against an invoice. `idempotencyKey` makes retries safe.
  Future<bool> recordPayment({
    required String invoiceId,
    required int amountMinor,
    required String idempotencyKey,
    String provider = 'manual',
  }) async {
    final res = await ApiClient.request('POST', '/finance/payments', body: {
      'invoiceId': invoiceId,
      'amountMinor': amountMinor,
      'idempotencyKey': idempotencyKey,
      'provider': provider,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }
}

final invoicesProvider =
    StateNotifierProvider<InvoicesNotifier, InvoicesState>((ref) {
  return InvoicesNotifier();
});
