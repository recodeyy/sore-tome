import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// §8 Staff parcel desk — guard logs an inbound delivery for a flat and hands
/// it over against the resident's OTP. Live: GET/POST /parcels, POST
/// /parcels/:id/collect.
class StaffParcelsScreen extends StatefulWidget {
  const StaffParcelsScreen({super.key});

  @override
  State<StaffParcelsScreen> createState() => _StaffParcelsScreenState();
}

class _StaffParcelsScreenState extends State<StaffParcelsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await ApiService.get('/parcels?status=pending');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return ((data['parcels'] as List?) ?? const [])
          .map((x) => (x as Map).cast<String, dynamic>())
          .toList();
    }
    throw Exception('Failed to load parcels');
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _openLogSheet() async {
    final logged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _LogParcelSheet(),
    );
    if (logged == true) _refresh();
  }

  Future<void> _collect(String id) async {
    final otp = await showDialog<String>(
      context: context,
      builder: (ctx) => const _OtpDialog(),
    );
    if (otp == null || otp.isEmpty) return;
    final res = await ApiService.post('/parcels/$id/collect', {'otp': otp});
    if (!mounted) return;
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Parcel handed over')));
      _refresh();
    } else {
      String msg = 'Incorrect OTP';
      try {
        msg = (jsonDecode(res.body)['error'] as String?) ?? msg;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Parcel Desk',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLogSheet,
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: Text('Log Parcel',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4, itemHeight: 84);
          }
          if (snap.hasError) {
            return ErrorRetryView(
                message: 'Could not load parcels.', onRetry: _refresh);
          }
          final parcels = snap.data ?? const [];
          if (parcels.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No pending parcels',
              message: 'Log an inbound delivery with the button below.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parcels.length,
              itemBuilder: (context, i) {
                final p = parcels[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          color: kPrimaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${p['courier']}'
                                '${(p['unit_id'] ?? '').toString().isNotEmpty ? ' → ${p['unit_id']}' : ''}',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A))),
                            if ((p['description'] ?? '').toString().isNotEmpty)
                              Text(p['description'].toString(),
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                      fontSize: 13)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _collect(p['id'].toString()),
                        child: const Text('Hand over'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LogParcelSheet extends StatefulWidget {
  const _LogParcelSheet();

  @override
  State<_LogParcelSheet> createState() => _LogParcelSheetState();
}

class _LogParcelSheetState extends State<_LogParcelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unit = TextEditingController();
  final _courier = TextEditingController();
  final _desc = TextEditingController();
  bool _saving = false;

  static const _couriers = [
    'Amazon',
    'Flipkart',
    'Swiggy',
    'Zomato',
    'BigBasket',
    'Blinkit',
    'Zepto',
    'Courier',
    'Other'
  ];

  @override
  void dispose() {
    _unit.dispose();
    _courier.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/parcels', {
        if (_unit.text.trim().isNotEmpty) 'unitId': _unit.text.trim(),
        'courier': _courier.text.trim(),
        if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
      });
      if ((res.statusCode == 201 || res.statusCode == 200) && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not log parcel')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log a parcel',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _couriers.map((c) {
                final sel = c == _courier.text;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => setState(() => _courier.text = c),
                  selectedColor: kAccentGreen.withValues(alpha: 0.15),
                  labelStyle: GoogleFonts.inter(
                    color: sel ? kPrimaryGreen : const Color(0xFF475569),
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                      color: sel ? kAccentGreen : const Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _courier,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Pick or type a courier'
                  : null,
              decoration: _dec('Courier', 'e.g. Amazon'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unit,
              decoration: _dec('Flat (e.g. A-1402)', 'Target flat'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: _dec('Note (optional)', 'e.g. Large box'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : Text('Log & notify resident',
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccentGreen, width: 1.6)),
      );
}

class _OtpDialog extends StatefulWidget {
  const _OtpDialog();

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter collection OTP'),
      content: TextField(
        controller: _otp,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration:
            const InputDecoration(hintText: '6-digit code from resident'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, _otp.text.trim()),
            child: const Text('Confirm')),
      ],
    );
  }
}
