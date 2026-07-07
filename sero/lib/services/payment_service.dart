import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sero/services/api_client.dart';
import 'package:sero/services/api_service.dart';

/// §7.2 invoice checkout against the LIVE finance API (Razorpay TEST mode).
///
/// Flow:
///  1. POST /finance/payments/create-order {invoiceId}
///     -> {orderId, amountMinor, amount, currency, keyId, invoiceId,
///         invoiceNumber, status:"processing", testMode}
///     (the amount is derived server-side from the invoice's outstanding
///      balance — the client never supplies it).
///  2. Razorpay checkout opens with keyId/orderId/amountMinor.
///  3. On the client success callback we call [onProcessing] — the checkout
///     callback is NOT success. Only the backend's idempotent
///     POST /finance/payments/verify {razorpay_order_id, razorpay_payment_id,
///     razorpay_signature, invoiceId} decides the outcome.
class InvoiceCheckout {
  InvoiceCheckout({
    required this.onProcessing,
    required this.onSuccess,
    required this.onFailure,
  });

  /// Checkout callback received; backend verification in flight.
  final void Function() onProcessing;

  /// Backend verify returned 200 {success:true, status:"captured", ...}.
  final void Function(Map<String, dynamic> result) onSuccess;

  final void Function(String message) onFailure;

  Razorpay? _razorpay;
  String? _invoiceId;

  /// Creates the order and opens Razorpay checkout. Throws nothing; failures
  /// are routed to [onFailure].
  Future<void> start({
    required String invoiceId,
    String? invoiceNumber,
    String? contact,
    String? email,
  }) async {
    _invoiceId = invoiceId;
    try {
      final res = await ApiClient.request(
        'POST',
        '/finance/payments/create-order',
        body: {'invoiceId': invoiceId},
      );
      if (res.statusCode != 201) {
        String message = 'Could not start the payment (${res.statusCode}).';
        try {
          final err = jsonDecode(res.body)['error'];
          if (err is String && err.isNotEmpty) message = err;
        } catch (_) {}
        onFailure(message);
        return;
      }

      final order = jsonDecode(res.body) as Map<String, dynamic>;
      _razorpay ??= (Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet));

      _razorpay!.open({
        'key': order['keyId'],
        'amount': order['amountMinor'],
        'currency': order['currency'] ?? 'INR',
        'order_id': order['orderId'],
        'name': 'SERO Society',
        'description':
            'Invoice ${order['invoiceNumber'] ?? invoiceNumber ?? ''} (TEST)',
        'prefill': {'contact': contact ?? '', 'email': email ?? ''},
      });
    } catch (e) {
      onFailure('Could not start the payment: $e');
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    onProcessing();
    try {
      final res = await ApiClient.request(
        'POST',
        '/finance/payments/verify',
        body: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          if (_invoiceId != null) 'invoiceId': _invoiceId,
        },
      );
      Map<String, dynamic> body = const {};
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      if (res.statusCode == 200 && body['success'] == true) {
        onSuccess(body);
      } else {
        onFailure(
            (body['error'] as String?) ?? 'Payment verification failed');
      }
    } catch (e) {
      onFailure('Verification error: $e');
    }
  }

  void _handleError(PaymentFailureResponse response) {
    onFailure(response.message ?? 'Payment was cancelled or failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onFailure(
        'External wallet (${response.walletName ?? 'unknown'}) is not supported in test mode');
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late Razorpay _razorpay;
  Function(String)? _onSuccess;
  Function(String)? _onFailure;

  void init({
    required Function(String) onSuccess,
    required Function(String) onFailure,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> startPayment({
    required double amount,
    required String title,
    String? description,
    String? email,
    String? contact,
  }) async {
    try {
      // 1. Create Order on Backend
      final res = await ApiService.post('/funds/payments/create-order', {
        'amount': amount,
        'currency': 'INR',
      });

      if (res.statusCode != 200) {
        throw 'Failed to create payment order: ${jsonDecode(res.body)['error']}';
      }

      final orderData = jsonDecode(res.body);
      final orderId = orderData['id'];
      final key = orderData['metadata']['key'];

      // 2. Open Razorpay Checkout
      var options = {
        'key': key,
        'amount': (amount * 100).toInt(), // in paise
        'name': 'The Sero',
        'order_id': orderId,
        'description': description ?? title,
        'prefill': {
          'contact': contact ?? '',
          'email': email ?? '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      _onFailure?.call(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // 3. Verify Payment on Backend
      final verifyRes = await ApiService.post('/funds/payments/verify', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyRes.statusCode == 200) {
        _onSuccess?.call(response.paymentId ?? 'Success');
      } else {
        _onFailure?.call(jsonDecode(verifyRes.body)['error'] ?? 'Verification failed');
      }
    } catch (e) {
      _onFailure?.call('Verification Error: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onFailure?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onFailure?.call('External wallet selected: ${response.walletName}');
  }
}
