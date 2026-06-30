import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/common/status_badge.dart';

/// Flats / Units — Screen 6 of 6
/// Shows flat list with search, wing/block filters, and member count summary.
class FlatsUnitsScreen extends ConsumerStatefulWidget {
  const FlatsUnitsScreen({super.key});

  @override
  ConsumerState<FlatsUnitsScreen> createState() => _FlatsUnitsScreenState();
}

class _FlatsUnitsScreenState extends ConsumerState<FlatsUnitsScreen> {
  String _searchQuery = '';
  String _selectedWing = 'All Wings';
  String _selectedBlock = 'All Blocks';

  /// Prompt for a unit number and create it via POST /structure/units.
  Future<void> _showAddFlatDialog() async {
    final controller = TextEditingController();
    final number = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Flat / Unit', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Unit number (e.g. A-101)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (number == null || number.isEmpty) return;
    try {
      final ok = await AdminSocietyService.addUnit(number);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(structureUnitsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unit "$number" added'), backgroundColor: const Color(0xFF064E3B)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add unit'), backgroundColor: Color(0xFFB91C1C)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  String _unitNumber(Map f) =>
      (f['number'] ?? f['unit_number'] ?? f['name'] ?? '').toString();
  String _unitWing(Map f) => (f['wing'] ?? '').toString();
  String _unitBlock(Map f) => (f['block'] ?? '').toString();
  String _unitType(Map f) => (f['type'] ?? f['unit_type'] ?? '').toString();
  String _occupancy(Map f) =>
      (f['resident'] ?? f['occupancy_type'] ?? f['occupancy'] ?? '').toString();
  bool _isVacant(Map f) =>
      (f['status'] ?? '').toString().toLowerCase() == 'vacant';
  bool _isOwner(Map f) {
    final o = _occupancy(f).toLowerCase();
    return o == 'owner';
  }

  List _filteredFlats(List units) {
    return units.where((f) {
      final m = f is Map ? f : const {};
      final matchesSearch = _searchQuery.isEmpty ||
          _unitNumber(m).toLowerCase().contains(_searchQuery);
      final matchesWing = _selectedWing == 'All Wings' || _unitWing(m) == _selectedWing;
      final matchesBlock =
          _selectedBlock == 'All Blocks' || _unitBlock(m) == _selectedBlock;
      return matchesSearch && matchesWing && matchesBlock;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(structureUnitsProvider);
    // The provider yields a Map { units, summary } — read the `units` list out
    // of it (casting the Map directly to a List always produced an empty list,
    // which blanked this screen even when data was present).
    final List unitsList = (unitsAsync.value?['units'] as List?) ?? [];
    final filtered = _filteredFlats(unitsList);

    final totalFlats = unitsList.length;
    final ownerCount = unitsList.where((u) => _occupancy(u as Map).toLowerCase() == 'owner').length;
    final tenantCount = unitsList.where((u) => _occupancy(u as Map).toLowerCase() == 'tenant').length;
    final vacantCount = unitsList.where((u) => _isVacant(u as Map)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Flats / Units',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                GestureDetector(
                  onTap: _showAddFlatDialog,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search flat or block',
              onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
              onFilterTap: () {},
            ),
          ),

          // ── Filter Dropdowns ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWing,
                        isExpanded: true,
                        items: ['All Wings', 'A Wing', 'B Wing', 'C Wing', 'D Wing']
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B))),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedWing = val);
                        },
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBlock,
                        isExpanded: true,
                        items: ['All Blocks', 'Block 1', 'Block 2']
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B))),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBlock = val);
                        },
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Flats List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final flat = filtered[index] as Map;
                final isOwner = _occupancy(flat).toLowerCase() == 'owner';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_outlined, size: 20, color: Color(0xFF064E3B)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _unitNumber(flat),
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_unitWing(flat)} · ${_unitBlock(flat)} · ${_unitType(flat)}',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      isOwner ? StatusBadge.owner() : StatusBadge.tenant(),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Bottom Summary ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FlatSummaryBadge(
                  value: totalFlats.toString(),
                  label: 'Total Flats',
                ),
                _FlatSummaryBadge(
                  value: ownerCount.toString(),
                  label: 'Owner',
                  color: const Color(0xFF059669),
                ),
                _FlatSummaryBadge(
                  value: tenantCount.toString(),
                  label: 'Tenant',
                  color: const Color(0xFFEA580C),
                ),
                _FlatSummaryBadge(
                  value: vacantCount.toString(),
                  label: 'Vacant',
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _FlatSummaryBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _FlatSummaryBadge({
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
