import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/visitor.dart';
import 'package:sero/providers/shared/visitors_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Provider/type tile for the visitor quick-select grid. Brand tiles use a
/// plain colored initial avatar (no copyrighted logos).
class _VisitorType {
  final String label;
  final String slug; // canonical `purpose` value sent to the backend
  final IconData? icon; // generic icon; null → colored initial avatar
  final Color color;

  const _VisitorType(this.label, this.slug, this.icon, this.color);
}

const _visitorTypes = [
  _VisitorType('Guest', 'guest', Icons.person_outline_rounded, kAccentGreen),
  _VisitorType('Swiggy', 'delivery', null, Color(0xFFF97316)),
  _VisitorType('Zomato', 'delivery', null, Color(0xFFDC2626)),
  _VisitorType('BigBasket', 'delivery', null, Color(0xFF16A34A)),
  _VisitorType('Blinkit', 'delivery', null, Color(0xFFCA8A04)),
  _VisitorType('Zepto', 'delivery', null, Color(0xFF7C3AED)),
  _VisitorType('Courier', 'delivery', Icons.inventory_2_outlined, kInfo),
  _VisitorType('Cab/Driver', 'cab', Icons.local_taxi_outlined, Color(0xFF475569)),
  _VisitorType('Maintenance', 'maid', Icons.handyman_outlined, Color(0xFF0D9488)),
  _VisitorType('Vendor', 'guest', Icons.storefront_outlined, Color(0xFF92400E)),
  _VisitorType('Other', 'guest', Icons.more_horiz_rounded, kTextSecondary),
];

/// Gate tab (MR-007/MR-009): visitor-type quick-select grid, gate entry form,
/// expected/pending/inside visitor lists with mark-arrived and checkout.
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitorsAsync = ref.watch(guardVisitorsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimaryGreen,
          onRefresh: () async => ref.invalidate(guardVisitorsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Text(
                'Gate Console',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search visitors by name or flat…',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'New Entry — pick visitor type',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _typeGrid(),
              const SizedBox(height: 20),
              visitorsAsync.when(
                loading: () => const Column(
                  children: [
                    SkeletonCard(),
                    SkeletonCard(),
                    SkeletonCard(),
                  ],
                ),
                error: (e, _) => ErrorRetryView(
                  message: 'Could not load the gate visitor feed.',
                  onRetry: () => ref.invalidate(guardVisitorsProvider),
                ),
                data: (visitors) => _visitorSections(visitors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemCount: _visitorTypes.length,
      itemBuilder: (context, i) {
        final t = _visitorTypes[i];
        return InkWell(
          onTap: () => _openEntrySheet(t),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSlateBorder),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: t.icon != null
                      ? Icon(t.icon, color: t.color, size: 20)
                      : Center(
                          child: Text(
                            t.label.characters.first.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: t.color,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Visitor lists ─────────────────────────────────────────────────────────

  Widget _visitorSections(List<Visitor> all) {
    bool matches(Visitor v) =>
        _query.isEmpty ||
        v.name.toLowerCase().contains(_query) ||
        v.targetFlat.toLowerCase().contains(_query);

    final expected = all
        .where((v) => (v.status == 'expected' || v.status == 'pre_approved') && matches(v))
        .toList();
    final pending = all.where((v) => v.status == 'pending' && matches(v)).toList();
    // The /guard/visitors feed marks people on premises as 'checked_in' (or
    // 'arrived'/'inside' from older flows); 'approved' covers resident-approved
    // entries that haven't exited. Only 'approved' was matched before, so
    // couriers/maids the guard checked in never appeared and could not be
    // checked out.
    const insideStatuses = {'approved', 'checked_in', 'arrived', 'inside'};
    final inside = all
        .where((v) => insideStatuses.contains(v.status) && v.exitTime == null && matches(v))
        .toList();

    if (expected.isEmpty && pending.isEmpty && inside.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _query.isEmpty ? 'No visitors right now' : 'No matches',
        message: _query.isEmpty
            ? 'Log a new entry using the visitor types above.'
            : 'No visitor matches "$_query". Try a different search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expected.isNotEmpty) ...[
          _sectionHeader('Expected (pre-approved)', expected.length),
          ...expected.map((v) => _VisitorTile(
                visitor: v,
                chip: const StatusChip(label: 'EXPECTED', semantic: ChipSemantic.info),
                actionLabel: 'Mark Arrived',
                onAction: () => _markArrived(v),
              )),
        ],
        if (pending.isNotEmpty) ...[
          _sectionHeader('Awaiting resident approval', pending.length),
          ...pending.map((v) => _VisitorTile(
                visitor: v,
                chip: const StatusChip(label: 'PENDING', semantic: ChipSemantic.warning),
              )),
        ],
        if (inside.isNotEmpty) ...[
          _sectionHeader('Inside', inside.length),
          ...inside.map((v) => _VisitorTile(
                visitor: v,
                chip: const StatusChip(label: 'INSIDE', semantic: ChipSemantic.success),
                actionLabel: 'Check Out',
                onAction: () => _checkout(v),
              )),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kLightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kPrimaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markArrived(Visitor v) async {
    try {
      // The gate feed comes from /guard/visitors, so entry must be recorded on
      // the same store. Fall back to the legacy action route for old records.
      var res = await ApiService.post('/guard/visitors/${v.id}/entry', {});
      if (res.statusCode == 404) {
        res = await ApiService.patch('/visitors/${v.id}/action', {'action': 'arrived'});
      }
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ref.invalidate(guardVisitorsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not mark arrived (${res.statusCode})'),
          backgroundColor: kError,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  Future<void> _checkout(Visitor v) async {
    try {
      // Same-store checkout: the gate feed ids live under /guard/visitors, so
      // the legacy PATCH /visitors/{id}/checkout can never find them. Keep the
      // legacy route as a fallback for records created by the old flow.
      var res = await ApiService.post('/guard/visitors/${v.id}/check-out', {});
      if (res.statusCode == 404) {
        res = await ApiService.patch('/visitors/${v.id}/checkout', {});
      }
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ref.invalidate(guardVisitorsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Checkout failed (${res.statusCode})'),
          backgroundColor: kError,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  // ─── New entry sheet ───────────────────────────────────────────────────────

  Future<void> _openEntrySheet(_VisitorType type) async {
    // Load units first so the guard picks the exact flat; the real unit_id is
    // what lets the backend notify that flat's resident(s).
    List<Map<String, dynamic>> units = [];
    try {
      final res = await ApiService.get('/structure/units');
      if (res.statusCode == 200) {
        units = ((jsonDecode(res.body)['units'] as List?) ?? const [])
            .map((u) => (u as Map).cast<String, dynamic>())
            .toList();
      }
    } catch (_) {/* dropdown will be empty; still allow logging */}
    if (!mounted) return;

    final nameCtrl = TextEditingController(
      text: type.icon == null ? '${type.label} delivery' : '',
    );
    final phoneCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    String? selectedUnitId;
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: type.icon != null
                          ? Icon(type.icon, color: type.color, size: 20)
                          : Center(
                              child: Text(
                                type.label.characters.first.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: type.color,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Log ${type.label} Entry',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close_rounded, color: kTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Visitor name / company'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Vehicle number (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Purpose / note (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnitId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Target flat'),
                  items: units.map((u) {
                    final id = (u['id'] ?? '').toString();
                    final number = (u['number'] ?? 'Flat').toString();
                    return DropdownMenuItem(
                      value: id,
                      child: Text(number, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: isLoading ? null : (v) => setSheetState(() => selectedUnitId = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || selectedUnitId == null) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(const SnackBar(
                                content: Text('Enter a name and select the target flat.'),
                              ));
                              return;
                            }
                            setSheetState(() => isLoading = true);
                            try {
                              // Canonical guard endpoint (preserved from the
                              // original guard_home flow): lands in
                              // /guard/visitors and fans out a notification to
                              // that flat's resident(s).
                              final res = await ApiService.post('/guard/visitors/check-in', {
                                'name': nameCtrl.text.trim(),
                                'purpose': purposeCtrl.text.trim().isNotEmpty
                                    ? purposeCtrl.text.trim()
                                    : type.slug,
                                'unitId': selectedUnitId,
                                if (phoneCtrl.text.trim().isNotEmpty)
                                  'phone': phoneCtrl.text.trim(),
                                if (vehicleCtrl.text.trim().isNotEmpty)
                                  'vehicleNumber': vehicleCtrl.text.trim(),
                              });
                              if (res.statusCode < 200 || res.statusCode >= 300) {
                                throw Exception('Check-in failed (${res.statusCode})');
                              }
                              ref.invalidate(guardVisitorsProvider);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: kError),
                                );
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Check In Visitor'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitorTile extends StatelessWidget {
  final Visitor visitor;
  final Widget chip;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _VisitorTile({
    required this.visitor,
    required this.chip,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kLightMint,
            child: Icon(
              visitor.type == 'delivery'
                  ? Icons.local_shipping_outlined
                  : visitor.type == 'cab'
                      ? Icons.local_taxi_outlined
                      : Icons.person_outline,
              color: kPrimaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (visitor.targetFlat.isNotEmpty) ...[
                      Text(
                        'Flat ${visitor.targetFlat}',
                        style: GoogleFonts.outfit(fontSize: 12, color: kTextSecondary),
                      ),
                      const SizedBox(width: 8),
                    ],
                    chip,
                  ],
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryGreen,
                side: const BorderSide(color: kPrimaryGreen),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
