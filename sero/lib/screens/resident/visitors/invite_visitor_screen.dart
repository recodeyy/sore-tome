import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';

/// §7.3 Resident pre-approval — "Invite Visitor". Resident picks a visitor
/// type, enters details + an optional time window, and gets a gate pass code
/// the guard verifies. Backed by POST /resident/visitors
/// (ResidentService.preApproveVisitor) — no mock data.
class InviteVisitorScreen extends StatefulWidget {
  const InviteVisitorScreen({super.key});

  @override
  State<InviteVisitorScreen> createState() => _InviteVisitorScreenState();
}

class _InviteVisitorScreenState extends State<InviteVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  // Visitor type → stored on the backend as `purpose`. Mirrors the MyGate-style
  // provider list from the prompt (§7.3).
  static const _types = <String>[
    'Guest',
    'Delivery',
    'Cab',
    'Service Provider',
    'Vendor',
    'Domestic Help',
    'Other',
  ];
  String _type = 'Guest';

  DateTime? _expectedAt;
  DateTime? _expiresAt;

  bool _submitting = false;
  Map<String, dynamic>? _pass; // set once the invite is created

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isExpiry}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (!mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    setState(() {
      if (isExpiry) {
        _expiresAt = picked;
      } else {
        _expectedAt = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final res = await ApiService.post('/resident/visitors', {
        'visitorName': _name.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'visitorPhone': _phone.text.trim(),
        'purpose': _type,
        if (_expectedAt != null)
          'expectedAt': _expectedAt!.toUtc().toIso8601String(),
        if (_expiresAt != null)
          'expiresAt': _expiresAt!.toUtc().toIso8601String(),
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(
            () => _pass = (data['visitor'] as Map).cast<String, dynamic>());
      } else {
        String msg = 'Could not create the invite. Please try again.';
        try {
          msg = (jsonDecode(res.body)['error'] as String?) ?? msg;
        } catch (_) {}
        _snack(msg);
      }
    } catch (e) {
      _snack('Network error. Please check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// Short human-friendly pass code from the visitor id.
  String _passCode(Map<String, dynamic> v) {
    final id = (v['id'] ?? '').toString().replaceAll('-', '');
    if (id.length >= 6) return id.substring(id.length - 6).toUpperCase();
    return id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pass == null ? 'Invite Visitor' : 'Gate Pass',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _pass == null ? _buildForm() : _buildPass(_pass!),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final df = DateFormat('EEE d MMM, h:mm a');
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Who is visiting?',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Pre-approve a guest so the gate lets them in quickly.',
              style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          const SizedBox(height: 20),

          // Visitor type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final selected = t == _type;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: kAccentGreen.withValues(alpha: 0.15),
                labelStyle: GoogleFonts.inter(
                  color: selected ? kPrimaryGreen : const Color(0xFF475569),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                    color: selected ? kAccentGreen : const Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _field(
            controller: _name,
            label: 'Visitor name',
            hint: 'e.g. Ramesh Kumar',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _phone,
            label: 'Mobile (optional)',
            hint: '10-digit number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          _dateTile(
            label: 'Expected at',
            value: _expectedAt == null ? 'Any time' : df.format(_expectedAt!),
            onTap: () => _pickDateTime(isExpiry: false),
            onClear: _expectedAt == null
                ? null
                : () => setState(() => _expectedAt = null),
          ),
          const SizedBox(height: 10),
          _dateTile(
            label: 'Pass valid until',
            value: _expiresAt == null ? 'No expiry' : df.format(_expiresAt!),
            onTap: () => _pickDateTime(isExpiry: true),
            onClear: _expiresAt == null
                ? null
                : () => setState(() => _expiresAt = null),
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : Text('Generate Gate Pass',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAccentGreen, width: 1.6)),
          ),
        ),
      ],
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: kAccentGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF94A3B8))),
                  Text(value,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A))),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: const Color(0xFF94A3B8),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }

  // ── Pass ─────────────────────────────────────────────────────────────────
  Widget _buildPass(Map<String, dynamic> v) {
    final code = _passCode(v);
    final df = DateFormat('EEE d MMM, h:mm a');
    final expected = v['expected_at'] != null
        ? df.format(DateTime.tryParse(v['expected_at'].toString())?.toLocal() ??
            DateTime.now())
        : 'Any time';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryGreen, kAccentGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text('Gate Pass Ready',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Text('PASS CODE',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 6),
              Text(
                code,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  _snack('Pass code copied');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy code'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _passRow('Visitor', (v['visitor_name'] ?? _name.text).toString()),
              _passRow('Type', (v['purpose'] ?? _type).toString()),
              if ((v['visitor_phone'] ?? _phone.text).toString().isNotEmpty)
                _passRow(
                    'Mobile', (v['visitor_phone'] ?? _phone.text).toString()),
              _passRow('Expected', expected),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kLightMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: kPrimaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Share this pass code with your visitor. The guard will admit '
                  'them at the gate and you\'ll be notified on entry.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Done',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _passRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k,
                style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
