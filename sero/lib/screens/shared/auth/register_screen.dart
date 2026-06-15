import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/auth_service.dart';

/// Register screen — new residents fill name, phone, password, flat number.
/// After submitting, their account is "pending" until an admin approves it.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _flatCtrl    = TextEditingController();
  final _blockCtrl   = TextEditingController();
  final _societyCtrl = TextEditingController();

  bool _loading  = false;
  bool _showPass = false;
  bool _done     = false;   // shows success state

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _flatCtrl.dispose();
    _blockCtrl.dispose();
    _societyCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        name: _nameCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        password: _passCtrl.text.trim(),
        flatNumber: _flatCtrl.text.trim(),
        blockName: _blockCtrl.text.trim().isEmpty ? null : _blockCtrl.text.trim(),
        societyId: _societyCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _loading = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _done ? _successView() : _formView(),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────
  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: kPrimaryGreen, size: 56),
            ),
            const SizedBox(height: 32),
            Text(
              'Registration Submitted!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your request has been sent to the society admin.\nYou will be notified once your account is approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15, 
                color: const Color(0xFF64748B), 
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _formView() {
    return Column(
      children: [
        // Premium Header
        Container(
          decoration: const BoxDecoration(
            gradient: kPremiumGradient,
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Join your society',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4),
                child: Text(
                  'Admin approval is required before you can log in.',
                  style: GoogleFonts.outfit(
                    fontSize: 14, 
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Form Fields
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Society code
                  TextFormField(
                    controller: _societyCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Society Code *',
                      prefixIcon: Icon(Icons.business_rounded),
                      hintText: 'e.g. SOCIETY_A',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Society code is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Full name
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixText: '+91  ',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Flat number
                  TextFormField(
                    controller: _flatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Flat Number *',
                      prefixIcon: Icon(Icons.home_outlined),
                      hintText: 'e.g. A-101',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Flat number is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Block name (optional)
                  TextFormField(
                    controller: _blockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Block Name (optional)',
                      prefixIcon: Icon(Icons.apartment_outlined),
                      hintText: 'e.g. Tower B',
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Submit Registration'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}











