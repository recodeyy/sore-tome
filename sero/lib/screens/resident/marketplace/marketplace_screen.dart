import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/marketplace_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident Marketplace — buy/sell listings within the society.
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketplaceProvider);
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
        title: Text('Marketplace',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Sell',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(marketplaceProvider),
        child: async.when(
          loading: () =>
              const LiveLoadingView(label: 'Loading marketplace…'),
          error: (e, _) => LiveErrorView(
              error: e, onRetry: () => ref.invalidate(marketplaceProvider)),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  LiveEmptyView(
                    icon: Icons.storefront_outlined,
                    message:
                        'No listings yet.\nTap "Sell" to list the first item.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              itemCount: items.length,
              itemBuilder: (context, i) => _ItemCard(item: items[i]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SellForm(),
    );
    if (created == true) ref.invalidate(marketplaceProvider);
  }
}

class _ItemCard extends StatelessWidget {
  final MarketplaceItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final sold = item.status == 'sold';
    final price = '₹${(item.priceMinor / 100).toStringAsFixed(2)}';
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
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
              ),
              if (sold)
                _Badge(
                  text: 'SOLD',
                  color: const Color(0xFFEF4444),
                )
              else if (item.priceMinor > 0)
                Text(price,
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669))),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (item.category.isNotEmpty) ...[
                _Badge(text: item.category, color: const Color(0xFF059669)),
                const SizedBox(width: 8),
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
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
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

class _SellForm extends StatefulWidget {
  const _SellForm();

  @override
  State<_SellForm> createState() => _SellFormState();
}

class _SellFormState extends State<_SellForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _category.dispose();
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
    final priceRupees = double.tryParse(_price.text.trim());
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
      if (priceRupees != null) 'priceMinor': (priceRupees * 100).round(),
      if (_category.text.trim().isNotEmpty) 'category': _category.text.trim(),
    };
    try {
      final res = await ApiService.post('/community/marketplace', body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(
            jsonDecode(res.body)['error'] ?? 'Failed to create listing');
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
          Text('List an item',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _field(_title, 'Title'),
          const SizedBox(height: 12),
          _field(_desc, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _field(_price, 'Price (₹)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          _field(_category, 'Category'),
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
                  : Text('Post Listing',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
