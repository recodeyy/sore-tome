import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/shared/brand_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedIndex = 0; // 0 for Resident, 1 for Admin

  // Resident fields
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Admin fields
  final _adminUserCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showAdminPass = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  // ── Resident Login ──────────────────────────────────────────
  Future<void> _loginResident() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    
    if (phone.isEmpty || pass.isEmpty) return;

    final loginPhone = '+91$phone';
    final loginPass = pass;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(loginPhone, loginPass);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      final msg = e is Map ? e['error'] : e.toString();
      _showError(msg ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign-In / Sign-Up ────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(authProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      if (result == null) return; // user cancelled the Google picker
      if (result) {
        // Multiple workspaces — let the user pick one.
        Navigator.pushNamed(context, '/workspace-select');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is Map ? e['error'] : e.toString();
      _showError(msg ?? 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Admin Login ─────────────────────────────────────────────
  Future<void> _loginAdmin() async {
    final user = _adminUserCtrl.text.trim();
    final pass = _adminPassCtrl.text.trim();
    
    if (user.isEmpty || pass.isEmpty) return;

    final loginUser = user;
    final loginPass = pass;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(loginUser, loginPass);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      final msg = e is Map ? e['error'] : e.toString();
      _showError(msg ?? 'Admin login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: kPrimaryGreen, // Matte deep green for premium feel
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SocietyLogo(size: 80)
                          .animate()
                          .fade(duration: 800.ms)
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 24),
                      Text(
                        'SERO',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 10,
                        ),
                      )
                          .animate()
                          .fade(delay: 200.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOutQuint),
                      Text(
                        'Connects the Society',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6,
                        ),
                      ).animate().fade(delay: 400.ms),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet Form
              RepaintBoundary(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Toggle (Pill style)
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.fastOutSlowIn,
                              alignment: _selectedIndex == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 0),
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: _selectedIndex == 0
                                              ? kDeepNavy
                                              : const Color(0xFF64748B),
                                          fontWeight: _selectedIndex == 0
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                        child: const Text('Resident'),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 1),
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: _selectedIndex == 1
                                              ? kDeepNavy
                                              : const Color(0xFF64748B),
                                          fontWeight: _selectedIndex == 1
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                        child: const Text('Admin'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
  
                      // HEAVY FIX: SizedBox with fixed height prevents "jumping"
                      // INDEXEDSTACK prevents "lag" by keeping forms alive in background
                      SizedBox(
                        height: 275, // Locked height for ultimate stability
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: [
                            // Resident Form
                            AnimatedOpacity(
                              opacity: _selectedIndex == 0 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: _residentForm(),
                            ),
                            // Admin Form
                            AnimatedOpacity(
                              opacity: _selectedIndex == 1 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: _adminForm(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: 600.ms, delay: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutQuint),
            ],
          ),
        ),
      ),
    );
  }

  // ── Resident form ─────────────────────────────────────────────────────────
  Widget _residentForm() {
    return Column(
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixText: '+91  ',
            hintText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          obscureText: !_showPass,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF94A3B8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _loginResident,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Login',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _loginWithGoogle,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_circle, size: 20, color: Color(0xFF4285F4)),
            ),
            label: Text(
              'Continue with Google',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          child: RichText(
            text: TextSpan(
              text: "Don't have an account? ",
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: 'Register →',
                  style: GoogleFonts.outfit(
                    color: kAccentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Admin form ────────────────────────────────────────────────────────────
  Widget _adminForm() {
    return Column(
      children: [
        TextField(
          controller: _adminUserCtrl,
          decoration: const InputDecoration(
            hintText: 'Admin username',
            prefixIcon: Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPassCtrl,
          obscureText: !_showAdminPass,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF94A3B8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showAdminPass ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _showAdminPass = !_showAdminPass),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _loginAdmin,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Admin Login',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {}, // Admin-specific reset flow
          child: Text(
            'Forgot your password?',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Button style removed to use theme-defined ElevatedButtonTheme
}











