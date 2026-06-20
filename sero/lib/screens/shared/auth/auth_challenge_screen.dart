import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';

enum AuthChallengeType { otp, mfa, stepUp }

class AuthChallengeScreen extends StatefulWidget {
  final AuthChallengeType type;
  final String? destination; // masked phone/email hint
  final Future<bool> Function(String code) onVerify;
  final Future<void> Function()? onResend;

  const AuthChallengeScreen({
    super.key,
    required this.type,
    required this.onVerify,
    this.destination,
    this.onResend,
  });

  @override
  State<AuthChallengeScreen> createState() => _AuthChallengeScreenState();
}

class _AuthChallengeScreenState extends State<AuthChallengeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() => _loading = true);
    try {
      final ok = await widget.onVerify(_code);
      if (!mounted) return;
      if (!ok) {
        _showError('Invalid code. Please check and try again.');
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend || widget.onResend == null) return;
    setState(() => _resending = true);
    try {
      await widget.onResend!();
      _startCountdown();
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String get _title {
    switch (widget.type) {
      case AuthChallengeType.otp:
        return 'Verify Your Identity';
      case AuthChallengeType.mfa:
        return 'Two-Factor Authentication';
      case AuthChallengeType.stepUp:
        return 'Step-Up Verification';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case AuthChallengeType.otp:
        return widget.destination != null
            ? 'Enter the 6-digit code sent to ${widget.destination}'
            : 'Enter the 6-digit verification code';
      case AuthChallengeType.mfa:
        return 'Enter the 6-digit code from your authenticator app';
      case AuthChallengeType.stepUp:
        return 'This action requires additional verification';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AuthChallengeType.otp:
        return Icons.sms_outlined;
      case AuthChallengeType.mfa:
        return Icons.security_outlined;
      case AuthChallengeType.stepUp:
        return Icons.verified_user_outlined;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryGreen, kDeepNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, color: Colors.white, size: 36),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 24),
                    Text(
                      _title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fade(delay: 100.ms),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _subtitle,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 200.ms),
                    ),
                  ],
                ),
              ),
              // Bottom sheet
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // OTP input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 46,
                          height: 56,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryGreen,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: kSlateBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kSlateBorder, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                _focusNodes[i + 1].requestFocus();
                              }
                              if (val.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              if (_code.length == 6) _verify();
                              setState(() {});
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_loading || _code.length < 6) ? null : _verify,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Verify',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.onResend != null)
                      _canResend
                          ? TextButton(
                              onPressed: _resending ? null : _resend,
                              child: Text(
                                _resending ? 'Sending...' : 'Resend Code',
                                style: GoogleFonts.outfit(
                                  color: kPrimaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              'Resend code in ${_resendCountdown}s',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                    const SizedBox(height: 8),
                    Text(
                      'Never share your code with anyone.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
