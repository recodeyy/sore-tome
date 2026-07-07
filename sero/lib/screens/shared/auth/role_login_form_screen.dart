import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/shared/brand_logo.dart';

class RoleLoginFormScreen extends ConsumerStatefulWidget {
  final String portal; // super-admin | admin | staff | resident

  const RoleLoginFormScreen({
    super.key,
    required this.portal,
  });

  @override
  ConsumerState<RoleLoginFormScreen> createState() => _RoleLoginFormScreenState();
}

class _RoleLoginFormScreenState extends ConsumerState<RoleLoginFormScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final input = _identifierCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      _showError('Please enter both your identifier and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final requiresSelect = await ref.read(authProvider.notifier).login(
            input,
            pass,
            portal: widget.portal,
          );

      if (!mounted) return;

      if (requiresSelect) {
        Navigator.pushReplacementNamed(context, '/workspace-select');
      } else {
        final user = ref.read(authProvider).value;
        if (user != null) {
          final role = user.role.toLowerCase();
          if (['super_admin', 'superadmin', 'platform_owner', 'platform_operations', 'platform_support', 'platform_security'].contains(role)) {
            Navigator.pushNamedAndRemoveUntil(context, '/super-admin', (_) => false);
          } else if (['main_admin', 'admin', 'secretary', 'treasurer', 'committee_member'].contains(role)) {
            Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
          } else if (['guard', 'security_manager', 'facility_manager', 'supervisor', 'maintenance_staff', 'housekeeping_staff', 'reception_staff', 'parcel_desk_staff', 'staff'].contains(role)) {
            Navigator.pushNamedAndRemoveUntil(context, '/staff', (_) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getPortalHeading() {
    switch (widget.portal) {
      case 'super-admin':
        return 'Super Admin Portal';
      case 'admin':
        return 'Society Administration';
      case 'staff':
        return 'Staff & Security Portal';
      default:
        return 'Resident Services';
    }
  }

  String _getPortalLabel() {
    switch (widget.portal) {
      case 'super-admin':
        return 'Platform Email';
      case 'staff':
        return 'Employee ID or Registered Mobile';
      default:
        return 'Mobile Number or Email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getPortalHeading();
    final label = _getPortalLabel();

    return Scaffold(
      backgroundColor: kMintBg,
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGreenGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header Context
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kInkGreen),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kMintTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SocietyLogo(size: 28, color: kFreshGreen),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: kInkGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fade(duration: 400.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Secure portal session',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF5B7468),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Input Sheet
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: kFreshGreen.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.portal == 'super-admin') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Authorized Platform Personnel Only.',
                                style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: label,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_showPass,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kFreshGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Sign In',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.portal == 'resident') ...[
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                            children: [
                              TextSpan(
                                text: 'Register →',
                                style: GoogleFonts.outfit(
                                  color: kFreshGreenDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                        child: RichText(
                          text: TextSpan(
                            text: 'New to your society? ',
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                            children: [
                              TextSpan(
                                text: 'Join a society →',
                                style: GoogleFonts.outfit(
                                  color: kFreshGreenDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {}, // Recover workflow
                        child: Text(
                          'Trouble logging in?',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
