import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/auth_service.dart';

/// Live SMS OTP verification backed by Firebase Phone Authentication.
///
/// Pass the destination phone in E.164 form (e.g. `+919876543210`) via the
/// route arguments. On successful verification the screen returns the Firebase
/// ID token to the caller (`Navigator.pop(context, idToken)`) so the caller can
/// exchange it with the backend or continue the session.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone});

  /// E.164 phone number. If null, read from route arguments.
  final String? phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  String _phone = '';
  String? _verificationId;
  int? _resendToken;

  bool _sending = false;
  bool _verifying = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _resendTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _phone = widget.phone ??
        (ModalRoute.of(context)?.settings.arguments as String? ?? '');
    if (_phone.isNotEmpty) {
      _sendOtp();
    } else {
      setState(() => _error = 'No phone number provided');
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.sendPhoneOtp(
        e164Phone: _phone,
        resendToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _sending = false;
          });
          _startResendCountdown();
        },
        onAutoVerified: (credential) async {
          // Android instant verification — complete sign-in without manual code.
          try {
            final idToken =
                await AuthService.signInWithPhoneCredential(credential);
            if (!mounted) return;
            Navigator.pop(context, idToken);
          } catch (_) {
            // Fall back to manual entry.
          }
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = message;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e is FirebaseAuthException
            ? (e.message ?? 'Failed to send OTP')
            : 'Failed to send OTP';
      });
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 6 || _verificationId == null) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final idToken = await AuthService.verifyPhoneOtp(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (!mounted) return;
      Navigator.pop(context, idToken);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.code == 'invalid-verification-code'
            ? 'Incorrect code. Please try again.'
            : (e.message ?? 'Verification failed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Verification failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sending ? 'Sending code to $_phone…' : 'Sent to $_phone',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_sending,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '· · · · · ·',
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD92D20), fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_verifying || _sending || _verificationId == null)
                        ? null
                        : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: (_secondsLeft > 0 || _sending) ? null : _sendOtp,
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend OTP in ${_secondsLeft}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: _secondsLeft > 0
                        ? const Color(0xFF94A3B8)
                        : kPrimaryGreen,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
