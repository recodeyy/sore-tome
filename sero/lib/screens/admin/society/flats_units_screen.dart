import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/common/status_badge.dart';

/// Flats / Units — Screen 6 of 6
/// Shows flat list with search, wing/block filters, and member count summary.
class FlatsUnitsScreen extends StatefulWidget {
  const FlatsUnitsScreen({super.key});

  @override
  State<FlatsUnitsScreen> createState() => _FlatsUnitsScreenState();
}

class _FlatsUnitsScreenState extends State<FlatsUnitsScreen> {
  String _searchQuery = '';
  String _selectedWing = 'All Wings';
  String _selectedBlock = 'All Blocks';

  List<Map<String, dynamic>> get _filteredFlats {
    return MockSocietyData.flats.where((f) {
      final matchesSearch = _searchQuery.isEmpty ||
          (f['number'] as String).toLowerCase().contains(_searchQuery);
      final matchesWing = _selectedWing == 'All Wings' ||
          f['wing'] == _selectedWing;
      final matchesBlock = _selectedBlock == 'All Blocks' ||
          f['block'] == _selectedBlock;
      return matchesSearch && matchesWing && matchesBlock;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: () {
                    // TODO: API integration - add new flat
                  },
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
              itemCount: _filteredFlats.length,
              itemBuilder: (context, index) {
                final flat = _filteredFlats[index];
                final isOwner = flat['resident'] == 'Owner';
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
                              flat['number'] as String,
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${flat['wing']} · ${flat['block']} · ${flat['type']}',
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
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FlatSummaryBadge(
                  value: MockSocietyData.flatsTotalCount.toString(),
                  label: 'Total Flats',
                ),
                _FlatSummaryBadge(
                  value: MockSocietyData.ownerCount.toString(),
                  label: 'Owner',
                  color: const Color(0xFF059669),
                ),
                _FlatSummaryBadge(
                  value: MockSocietyData.tenantCount.toString(),
                  label: 'Tenant',
                  color: const Color(0xFFEA580C),
                ),
                _FlatSummaryBadge(
                  value: MockSocietyData.vacantCount.toString(),
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
