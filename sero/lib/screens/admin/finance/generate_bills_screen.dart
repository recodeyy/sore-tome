import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Generate Bills — Screen 2 of 6
/// Multi-step form for creating new maintenance or utility bills.
class GenerateBillsScreen extends ConsumerStatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  ConsumerState<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends ConsumerState<GenerateBillsScreen> {
  // Bill type is a domain enum (no endpoint).
  static const List<String> _billTypes = ['Maintenance', 'Water', 'Electricity', 'Sinking Fund', 'Other'];

  String? _selectedWing;
  String? _selectedBlock;
  String _selectedBillType = _billTypes[0];

  @override
  Widget build(BuildContext context) {
    final structureAsync = ref.watch(structureSummaryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Generate Bills', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.description_outlined, color: Color(0xFF1E293B)), onPressed: () => Navigator.pushNamed(context, '/admin/finance/history')),
        ],
      ),
      body: structureAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading structure…'),
        error: (e, _) => LiveErrorView(
          error: e,
          onRetry: () => ref.invalidate(structureSummaryProvider),
        ),
        data: (structure) {
          final wings = ((structure['wings'] as List?) ?? const [])
              .map((w) => (w is Map ? (w['name'] ?? w['wing_name'] ?? '') : '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          final blocks = ((structure['blocks'] as List?) ?? const [])
              .map((b) => (b is Map ? (b['name'] ?? b['block_name'] ?? '') : '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          // Keep selection valid against live lists.
          if (_selectedWing != null && !wings.contains(_selectedWing)) _selectedWing = null;
          if (_selectedBlock != null && !blocks.contains(_selectedBlock)) _selectedBlock = null;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Step Indicator ──
                const _StepIndicator(currentStep: 1),
                const SizedBox(height: 32),

                // ── Select Wing ──
                _buildLabel('Select Wing'),
                _buildDropdown(
                  value: _selectedWing,
                  hint: wings.isEmpty ? 'No wings available' : 'Select Wing',
                  items: wings,
                  onChanged: (v) => setState(() => _selectedWing = v),
                ),
                const SizedBox(height: 16),

                // ── Select Block ──
                _buildLabel('Select Block'),
                _buildDropdown(
                  value: _selectedBlock,
                  hint: blocks.isEmpty ? 'No blocks available' : 'Select Block',
                  items: blocks,
                  onChanged: (v) => setState(() => _selectedBlock = v),
                ),
                const SizedBox(height: 16),

            // ── Bill Month ──
            _buildLabel('Bill Month'),
            _buildPickerField(icon: Icons.calendar_today_outlined, value: 'May 2024'),
            const SizedBox(height: 16),

            // ── Due Date ──
            _buildLabel('Due Date'),
            _buildPickerField(icon: Icons.calendar_today_outlined, value: '31 May 2024'),
            const SizedBox(height: 16),

            // ── Bill Type ──
            _buildLabel('Bill Type'),
            _buildDropdown(
              value: _selectedBillType,
              hint: 'Select Bill Type',
              items: _billTypes,
              onChanged: (v) => setState(() => _selectedBillType = v!),
            ),
            const SizedBox(height: 16),

            // ── Add Other Charges ──
            _buildLabel('Add Other Charges'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                   Text('₹ 0', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                   const Spacer(),
                   const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Actions ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => AdminActions.comingSoon(context, 'Bill generation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Continue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => AdminActions.comingSoon(context, 'Saving drafts'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF064E3B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Save as Draft', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF064E3B))),
              ),
            ),
            const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
    );
  }

  Widget _buildDropdown({required String? value, required List<String> items, required ValueChanged<String?> onChanged, String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8))),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B))))).toList(),
          onChanged: items.isEmpty ? null : onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildPickerField({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E293B)),
          const SizedBox(width: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStep(1, 'Bill Details', currentStep >= 1),
        _buildDivider(currentStep >= 2),
        _buildStep(2, 'Select Flats', currentStep >= 2),
        _buildDivider(currentStep >= 3),
        _buildStep(3, 'Preview', currentStep >= 3),
      ],
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF064E3B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE2E8F0), width: 1),
            ),
            child: Center(
              child: Text(step.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: isActive ? Colors.white : const Color(0xFF94A3B8))),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isActive) {
    return Container(width: 30, height: 2, margin: const EdgeInsets.only(bottom: 18), color: isActive ? const Color(0xFF064E3B) : const Color(0xFFE2E8F0));
  }
}
