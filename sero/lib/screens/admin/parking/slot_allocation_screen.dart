import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

class SlotAllocationScreen extends ConsumerStatefulWidget {
  const SlotAllocationScreen({super.key});

  @override
  ConsumerState<SlotAllocationScreen> createState() => _SlotAllocationScreenState();
}

class _SlotAllocationScreenState extends ConsumerState<SlotAllocationScreen> {
  String selectedTab = 'Basement 1';
  Map<String, dynamic>? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(parkingSlotsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Slot Allocation',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '12',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SeroSearchBar(hintText: 'Search by flat no. or owner name'),
          ),

          // ── Tabs ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildTab('All'),
                _buildTab('Basement 1'),
                _buildTab('Basement 2'),
                _buildTab('Ground Floor'),
              ],
            ),
          ),

          // ── Slot Legend ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Allocated', const Color(0xFF059669)),
                const SizedBox(width: 16),
                _buildLegendItem('Reserved', const Color(0xFF2563EB)),
                const SizedBox(width: 16),
                _buildLegendItem('Available', const Color(0xFF94A3B8)),
                const SizedBox(width: 16),
                _buildLegendItem('Blocked', const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            selectedTab,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // ── Slot Grid ──
          Expanded(
            child: slotsAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading slots…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(parkingSlotsProvider),
              ),
              data: (slots) {
                if (slots.isEmpty) {
                  return const LiveEmptyView(
                    icon: Icons.local_parking_rounded,
                    message: 'No parking slots found.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index] is Map
                        ? (slots[index] as Map).cast<String, dynamic>()
                        : <String, dynamic>{};
                    final isSelected = selectedSlot != null &&
                        selectedSlot!['id'] == slot['id'];
                    return GestureDetector(
                      onTap: () => setState(() => selectedSlot = slot),
                      child: _buildSlotIcon(slot, isSelected),
                    );
                  },
                );
              },
            ),
          ),

          // ── Bottom Selection Panel ──
          if (selectedSlot != null)
            _buildSelectionPanel()
          else
            const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Dashboard', false),
            _buildNavItem(Icons.local_parking_rounded, 'Slots', true),
            _buildNavItem(Icons.person_pin_circle_outlined, 'Visitors', false),
            _buildNavItem(Icons.report_problem_outlined, 'Violations', false),
            _buildNavItem(Icons.more_horiz_rounded, 'More', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? kPrimaryGreen : kSlateBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSlotIcon(Map<String, dynamic> slot, bool isSelected) {
    final color = _getStatusColor((slot['status'] ?? '').toString());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (slot['id'] ?? slot['slot_id'] ?? slot['code'] ?? '').toString(),
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isSelected ? color : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionPanel() {
    final slot = selectedSlot ?? const {};
    final flat = (slot['flat'] ?? slot['unit'] ?? '').toString();
    final owner = (slot['owner'] ?? slot['allocated_to'] ?? '').toString();
    final vehicle = (slot['vehicle'] ?? slot['vehicle_number'] ?? '').toString();
    final type = (slot['type'] ?? slot['vehicle_type'] ?? '').toString();
    final bool hasData = flat.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (slot['id'] ?? slot['slot_id'] ?? slot['code'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryGreen,
                ),
              ),
              StatusBadge(
                label: (slot['status'] ?? '').toString(),
                bgColor: _getStatusColor((slot['status'] ?? '').toString()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasData)
            Row(
              children: [
                Expanded(child: _buildDetailItem('Allocated To', '$flat • $owner')),
                Expanded(child: _buildDetailItem('Vehicle No.', vehicle)),
              ],
            ),
          if (hasData) const SizedBox(height: 16),
          if (hasData)
            Row(
              children: [
                Expanded(child: _buildDetailItem('Type', type)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
          if (!hasData)
            Text(
              'No vehicle allocated to this slot yet.',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => AdminActions.comingSoon(context, 'Slot allocation'),
              child: const Text('Allocate Slot'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'allocated':
      case 'occupied':
        return const Color(0xFF059669);
      case 'reserved':
        return const Color(0xFF2563EB);
      case 'blocked':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
