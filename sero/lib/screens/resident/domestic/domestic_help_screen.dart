import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// §7.3 Domestic help — a resident's maid/cook/driver with gate access the
/// guard honours. Live: GET/POST/PATCH/DELETE /domestic-help.
class DomesticHelpScreen extends StatefulWidget {
  const DomesticHelpScreen({super.key});

  @override
  State<DomesticHelpScreen> createState() => _DomesticHelpScreenState();
}

class _DomesticHelpScreenState extends State<DomesticHelpScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await ApiService.get('/domestic-help');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return ((data['helpers'] as List?) ?? const [])
          .map((x) => (x as Map).cast<String, dynamic>())
          .toList();
    }
    throw Exception('Failed to load helpers');
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _setStatus(String id, String status) async {
    final res =
        await ApiService.patch('/domestic-help/$id/status', {'status': status});
    if (res.statusCode == 200) {
      _refresh();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update access')));
    }
  }

  Future<void> _remove(String id) async {
    final res = await ApiService.delete('/domestic-help/$id');
    if (res.statusCode == 200) {
      _refresh();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove helper')));
    }
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddHelperSheet(),
    );
    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Domestic Help',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Help',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4, itemHeight: 88);
          }
          if (snap.hasError) {
            return ErrorRetryView(
                message: 'Could not load your domestic help.',
                onRetry: _refresh);
          }
          final helpers = snap.data ?? const [];
          if (helpers.isEmpty) {
            return const EmptyState(
              icon: Icons.cleaning_services_outlined,
              title: 'No help added',
              message:
                  'Add your maid, cook or driver so the gate can check them in and notify you.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: helpers.length,
              itemBuilder: (context, i) => _HelperCard(
                helper: helpers[i],
                onStatus: _setStatus,
                onRemove: _remove,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  final Map<String, dynamic> helper;
  final Future<void> Function(String id, String status) onStatus;
  final Future<void> Function(String id) onRemove;
  const _HelperCard(
      {required this.helper, required this.onStatus, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final id = helper['id'].toString();
    final status = (helper['access_status'] ?? 'active').toString();
    final type = (helper['helper_type'] ?? 'maid').toString();
    final active = status == 'active';
    final revoked = status == 'revoked';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kLightMint,
                child: Icon(_iconFor(type), color: kPrimaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helper['name'].toString(),
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF0F172A))),
                    Text(
                        '${type[0].toUpperCase()}${type.substring(1)}'
                        '${(helper['phone'] ?? '').toString().isNotEmpty ? ' · ${helper['phone']}' : ''}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ),
              StatusChip(
                label: active ? 'Active' : (revoked ? 'Revoked' : 'Paused'),
                semantic: active
                    ? ChipSemantic.success
                    : (revoked ? ChipSemantic.error : ChipSemantic.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!revoked)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onStatus(id, active ? 'paused' : 'active'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreen,
                      side: const BorderSide(color: kAccentGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                        active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 18),
                    label: Text(active ? 'Pause' : 'Resume'),
                  ),
                ),
              if (!revoked) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRevoke(context, id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFecaca)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(revoked ? 'Remove' : 'Revoke'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, String id) {
    final revoked = (helper['access_status'] ?? '').toString() == 'revoked';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(revoked ? 'Remove helper?' : 'Revoke access?'),
        content: Text(revoked
            ? 'This permanently removes the helper from your list.'
            : 'The gate will no longer let this helper in until you re-activate them.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              revoked ? onRemove(id) : onStatus(id, 'revoked');
            },
            child: Text(revoked ? 'Remove' : 'Revoke',
                style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'cook':
        return Icons.restaurant_rounded;
      case 'driver':
        return Icons.directions_car_rounded;
      case 'nanny':
        return Icons.child_care_rounded;
      default:
        return Icons.cleaning_services_rounded;
    }
  }
}

class _AddHelperSheet extends StatefulWidget {
  const _AddHelperSheet();

  @override
  State<_AddHelperSheet> createState() => _AddHelperSheetState();
}

class _AddHelperSheetState extends State<_AddHelperSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'maid';
  bool _saving = false;

  static const _types = ['maid', 'cook', 'driver', 'nanny', 'other'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/domestic-help', {
        'name': _name.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'helperType': _type,
      });
      if ((res.statusCode == 201 || res.statusCode == 200) && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not add helper')));
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
            Text('Add domestic help',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final sel = t == _type;
                return ChoiceChip(
                  label: Text('${t[0].toUpperCase()}${t.substring(1)}'),
                  selected: sel,
                  onSelected: (_) => setState(() => _type = t),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              decoration: _dec('Name', 'e.g. Sita Devi'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _dec('Mobile (optional)', '10-digit number'),
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
                    : Text('Save',
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
