import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';

/// Wings & Blocks — Screen 5 of 6
/// Toggle between Wings and Blocks view, search, list, and total overview.
class WingsBlocksScreen extends ConsumerStatefulWidget {
  const WingsBlocksScreen({super.key});

  @override
  ConsumerState<WingsBlocksScreen> createState() => _WingsBlocksScreenState();
}

class _WingsBlocksScreenState extends ConsumerState<WingsBlocksScreen> {
  bool _showWings = true; // toggle Wings/Blocks tab
  String _searchQuery = '';

  /// Prompt for a new wing/block name and create it via the structure API.
  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final isWing = _showWings;
    final label = isWing ? 'Wing' : 'Block';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $label', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: '$label name'),
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
    if (name == null || name.isEmpty) return;
    try {
      final ok = isWing
          ? await AdminSocietyService.addWing(name)
          : await AdminSocietyService.addBlock(name);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(structureSummaryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label "$name" added'), backgroundColor: const Color(0xFF064E3B)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add $label'), backgroundColor: const Color(0xFFB91C1C)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final structureAsync = ref.watch(structureSummaryProvider);
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
                    'Wings & Blocks',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                GestureDetector(
                  onTap: _showAddDialog,
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

          // ── Toggle Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showWings = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _showWings ? kPrimaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Wings',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _showWings ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showWings = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_showWings ? kPrimaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Blocks',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !_showWings ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search ${_showWings ? 'wings' : 'blocks'}',
              onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
              onFilterTap: () {},
            ),
          ),

          // ── List ──
          Expanded(
            child: structureAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading structure…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(structureSummaryProvider),
              ),
              data: (data) {
                final wings = (data['wings'] as List?) ?? const [];
                final blocks = (data['blocks'] as List?) ?? const [];
                return _showWings ? _buildWingsList(wings) : _buildBlocksList(blocks);
              },
            ),
          ),

          // ── Total Overview ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Overview',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final summary = structureAsync.maybeWhen(
                      data: (d) => (d['summary'] as Map?) ?? const {},
                      orElse: () => const {},
                    );
                    String count(List<String> keys) {
                      for (final k in keys) {
                        if (summary[k] != null) return summary[k].toString();
                      }
                      return '0';
                    }
                    return Row(
                      children: [
                        _OverviewBadge(
                          icon: Icons.view_column,
                          value: count(['totalWings', 'total_wings']),
                          label: 'Wings',
                        ),
                        const SizedBox(width: 16),
                        _OverviewBadge(
                          icon: Icons.view_module,
                          value: count(['totalBlocks', 'total_blocks']),
                          label: 'Blocks',
                          iconColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 16),
                        _OverviewBadge(
                          icon: Icons.apartment,
                          value: count(['totalFlats', 'total_units', 'total_flats']),
                          label: 'Flats',
                          iconColor: const Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 16),
                        _OverviewBadge(
                          icon: Icons.people,
                          value: count(['totalMembers', 'total_members']),
                          label: 'Members',
                          iconColor: const Color(0xFF7C3AED),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildWingsList(List source) {
    final wings = source.where((w) {
      if (_searchQuery.isEmpty) return true;
      return (w is Map ? (w['name'] ?? '').toString() : '')
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();

    if (wings.isEmpty) {
      return const LiveEmptyView(
        icon: Icons.view_column_outlined,
        message: 'No wings found.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      itemCount: wings.length,
      itemBuilder: (context, index) {
        final wing = (wings[index] as Map?) ?? const {};
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
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
                child: const Icon(Icons.apartment_rounded, size: 22, color: Color(0xFF064E3B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (wing['name'] ?? '').toString(),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${wing['blocks'] ?? 0} Blocks · ${wing['flats'] ?? wing['units'] ?? 0} Flats',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlocksList(List source) {
    final blocks = source.where((b) {
      if (_searchQuery.isEmpty) return true;
      final m = b is Map ? b : const {};
      return (m['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
          (m['wing'] ?? '').toString().toLowerCase().contains(_searchQuery);
    }).toList();

    if (blocks.isEmpty) {
      return const LiveEmptyView(
        icon: Icons.view_module_outlined,
        message: 'No blocks found.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = (blocks[index] as Map?) ?? const {};
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.view_module_rounded, size: 22, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (block['name'] ?? '').toString(),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${block['wing'] ?? ''} · ${block['flats'] ?? block['units'] ?? 0} Flats',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _OverviewBadge({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF064E3B)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
