import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/shared/brand_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/config/dev_config.dart';

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
    
    // In Mock mode, allow login with any credentials or even empty
    if (!kUseMockData && (phone.isEmpty || pass.isEmpty)) return;

    final loginPhone = kUseMockData ? (phone.isEmpty ? '+919876543210' : '+91$phone') : '+91$phone';
    final loginPass = kUseMockData ? (pass.isEmpty ? 'password' : pass) : pass;

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

  // ── Admin Login ─────────────────────────────────────────────
  Future<void> _loginAdmin() async {
    final user = _adminUserCtrl.text.trim();
    final pass = _adminPassCtrl.text.trim();
    
    // In Mock mode, allow login with any credentials or even empty
    if (!kUseMockData && (user.isEmpty || pass.isEmpty)) return;

    final loginUser = kUseMockData ? (user.isEmpty ? 'admin' : user) : user;
    final loginPass = kUseMockData ? (pass.isEmpty ? 'password' : pass) : pass;

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











