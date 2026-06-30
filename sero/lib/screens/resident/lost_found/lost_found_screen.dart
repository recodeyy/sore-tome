import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/lost_found_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident Lost & Found — report lost items or things you found.
class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen> {
  String _filter = 'all'; // 'all' | 'lost' | 'found'

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(lostFoundProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lost & Found',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        onPressed: _openForm,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Report',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('Lost', 'lost'),
                const SizedBox(width: 8),
                _chip('Found', 'found'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(lostFoundProvider),
              child: async.when(
                loading: () =>
                    const LiveLoadingView(label: 'Loading items…'),
                error: (e, _) => LiveErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(lostFoundProvider)),
                data: (items) {
                  final filtered = _filter == 'all'
                      ? items
                      : items.where((i) => i.kind == _filter).toList();
                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        LiveEmptyView(
                          icon: Icons.search_off_outlined,
                          message:
                              'Nothing here yet.\nTap "Report" to add a lost or found item.',
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _ItemCard(item: filtered[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF064E3B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF064E3B)
                  : const Color(0xFFE2E8F0)),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  Future<void> _openForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ReportForm(),
    );
    if (created == true) ref.invalidate(lostFoundProvider);
  }
}

class _ItemCard extends StatelessWidget {
  final LostFoundItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.kind == 'lost';
    final resolved = item.status == 'resolved';
    final kindColor =
        isLost ? const Color(0xFFEF4444) : const Color(0xFF059669);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(item.kind.isEmpty ? '—' : item.kind, kindColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
              ),
              if (resolved)
                _badge('resolved', const Color(0xFF94A3B8)),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.location.isNotEmpty) ...[
                const Icon(Icons.place_outlined,
                    size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(item.location,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(width: 12),
              ],
              if (item.posterName.isNotEmpty)
                Expanded(
                  child: Text('by ${item.posterName}',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF94A3B8))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(),
          style: GoogleFonts.outfit(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm();

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  String _kind = 'lost';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'kind': _kind,
      'title': _title.text.trim(),
      if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
    };
    try {
      final res = await ApiService.post('/community/lost-found', body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(
            jsonDecode(res.body)['error'] ?? 'Failed to report item');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report an item',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Row(
            children: [
              _toggle('Lost', 'lost'),
              const SizedBox(width: 10),
              _toggle('Found', 'found'),
            ],
          ),
          const SizedBox(height: 14),
          _field(_title, 'Title'),
          const SizedBox(height: 12),
          _field(_desc, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _field(_location, 'Location'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.outfit(
                    color: const Color(0xFFEF4444), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Submit Report',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, String value) {
    final selected = _kind == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kind = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF064E3B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? const Color(0xFF064E3B)
                    : const Color(0xFFE2E8F0)),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? Colors.white : const Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
    );
  }
}
