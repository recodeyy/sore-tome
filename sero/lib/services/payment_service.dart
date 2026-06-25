import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sero/services/api_service.dart';

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
