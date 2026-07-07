import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_staff_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/screens/admin/staff/add_staff_screen.dart';

/// Staff List Screen — Staff Module (2/2)
/// Filterable list of all society staff members with status badges and quick-call actions.
class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String _selectedFilter = 'All Staff';
  String _query = '';
  String? _roleFilter; // null = any role
  String? _shiftFilter; // null = any shift

  String _roleOf(dynamic s) =>
      (s is Map ? (s['role'] ?? s['designation'] ?? '').toString() : '');
  String _shiftOf(dynamic s) =>
      (s is Map ? (s['shift'] ?? s['shift_name'] ?? '').toString() : '');

  int get _activeAdvancedFilters =>
      (_roleFilter != null ? 1 : 0) + (_shiftFilter != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final allStaff = staffAsync.valueOrNull ?? const [];
    String statusOf(dynamic s) =>
        (s is Map ? (s['status'] ?? '').toString() : '').toLowerCase();
    final allCount = allStaff.length;
    final activeCount = allStaff.where((s) => statusOf(s) == 'active').length;
    final onLeaveCount = allStaff.where((s) => statusOf(s) == 'on leave' || statusOf(s) == 'leave').length;
    final resignedCount = allStaff.where((s) => statusOf(s) == 'resigned').length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Staff List', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF1E293B)), onPressed: () => Navigator.pushNamed(context, '/notifications')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SeroSearchBar(
              hintText: 'Search staff by name, role...',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onFilterTap: () => _showAdvancedFilters(allStaff),
            ),
          ),

          // ── Filter Chips ──
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'All Staff', count: allCount, isSelected: _selectedFilter == 'All Staff', onTap: () => setState(() => _selectedFilter = 'All Staff')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Active', count: activeCount, isSelected: _selectedFilter == 'Active', onTap: () => setState(() => _selectedFilter = 'Active')),
                const SizedBox(width: 8),
                _FilterChip(label: 'On Leave', count: onLeaveCount, isSelected: _selectedFilter == 'On Leave', onTap: () => setState(() => _selectedFilter = 'On Leave')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Resigned', count: resignedCount, isSelected: _selectedFilter == 'Resigned', onTap: () => setState(() => _selectedFilter = 'Resigned')),
              ],
            ),
          ),

          // ── Active advanced filters ──
          if (_activeAdvancedFilters > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_roleFilter != null)
                          _ActiveFilterPill(label: 'Role: $_roleFilter', onClear: () => setState(() => _roleFilter = null)),
                        if (_shiftFilter != null)
                          _ActiveFilterPill(label: 'Shift: $_shiftFilter', onClear: () => setState(() => _shiftFilter = null)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _roleFilter = null;
                      _shiftFilter = null;
                    }),
                    child: Text('Clear', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF064E3B))),
                  ),
                ],
              ),
            ),

          // ── Staff List ──
          Expanded(
            child: staffAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading staff…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(staffListProvider),
              ),
              data: (staffList) {
                final filtered = staffList.where((s) {
                  if (_selectedFilter == 'All Staff') return true;
                  if (_selectedFilter == 'Active') return statusOf(s) == 'active';
                  if (_selectedFilter == 'On Leave') {
                    return statusOf(s) == 'on leave' || statusOf(s) == 'leave';
                  }
                  if (_selectedFilter == 'Resigned') return statusOf(s) == 'resigned';
                  return true;
                }).where((s) {
                  if (_roleFilter != null && _roleOf(s) != _roleFilter) return false;
                  if (_shiftFilter != null && _shiftOf(s) != _shiftFilter) return false;
                  return true;
                }).where((s) {
                  if (_query.isEmpty) return true;
                  final m = s is Map ? s : const {};
                  final hay = [
                    m['name'], m['full_name'], m['role'], m['designation'],
                    m['id'], m['staff_id'],
                  ].where((e) => e != null).join(' ').toLowerCase();
                  return hay.contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const LiveEmptyView(
                    icon: Icons.groups_outlined,
                    message: 'No staff members found.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final staff = filtered[index] is Map
                        ? filtered[index] as Map
                        : const {};
                    final joined = (staff['joined'] ??
                            staff['joined_at'] ??
                            staff['created_at'] ??
                            '')
                        .toString();
                    final staffId =
                        (staff['id'] ?? staff['staff_id'] ?? '').toString();
                    return _StaffCard(
                      name: (staff['name'] ?? staff['full_name'] ?? '').toString(),
                      role: (staff['role'] ?? staff['designation'] ?? '').toString(),
                      id: staffId,
                      joined: joined,
                      status: (staff['status'] ?? '').toString(),
                      imageUrl: (staff['image'] ?? staff['photo'] ?? '').toString(),
                      onManage: () => _manageStatus(
                        staffId,
                        (staff['name'] ?? staff['full_name'] ?? '').toString(),
                        (staff['status'] ?? '').toString(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddStaffScreen()),
          );
          if (added == true) ref.invalidate(staffListProvider);
        },
        backgroundColor: const Color(0xFF064E3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Staff approval / status management. Lets the admin Activate (approve),
  /// Suspend (hold), or Terminate (off-board) a staff member via
  /// PATCH /staff-v2/:id/status. Refreshes the list on success.
  Future<void> _manageStatus(String staffId, String name, String current) async {
    if (staffId.isEmpty) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Manage $name',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B))),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF059669)),
              title: Text('Approve / Activate',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              enabled: current.toLowerCase() != 'active',
              onTap: () => Navigator.pop(ctx, 'active'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.pause_circle_outline, color: Color(0xFFEA580C)),
              title: Text('Suspend',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              enabled: current.toLowerCase() != 'suspended',
              onTap: () => Navigator.pop(ctx, 'suspended'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              title: Text('Terminate',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              enabled: current.toLowerCase() != 'terminated',
              onTap: () => Navigator.pop(ctx, 'terminated'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      await AdminStaffService.setStatus(staffId, action);
      if (!mounted) return;
      ref.invalidate(staffListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name updated to $action')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: ${'$e'.replaceFirst('Exception: ', '')}')),
      );
    }
  }

  /// Advanced-filter bottom-sheet: refine the staff list by role and shift.
  /// Options are derived from the live staff data so they always match reality.
  Future<void> _showAdvancedFilters(List<dynamic> allStaff) async {
    final roles = <String>{
      for (final s in allStaff)
        if (_roleOf(s).trim().isNotEmpty) _roleOf(s).trim(),
    }.toList()
      ..sort();
    final shifts = <String>{
      for (final s in allStaff)
        if (_shiftOf(s).trim().isNotEmpty) _shiftOf(s).trim(),
    }.toList()
      ..sort();

    var role = _roleFilter;
    var shift = _shiftFilter;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget chips(String title, List<String> opts, String? selected, ValueChanged<String?> onPick) {
              if (opts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('No $title data available',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: opts.map((o) {
                      final isSel = o == selected;
                      return GestureDetector(
                        onTap: () => setSheetState(() => onPick(isSel ? null : o)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF064E3B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(o,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : const Color(0xFF64748B),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Advanced Filters',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  chips('Role', roles, role, (v) => role = v),
                  chips('Shift', shifts, shift, (v) => shift = v),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setSheetState(() {
                            role = null;
                            shift = null;
                          }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Reset',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _roleFilter = role;
                              _shiftFilter = shift;
                            });
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E3B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Apply',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveFilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _ActiveFilterPill({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF059669))),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.count, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064E3B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9)),
        ),
        child: Center(
          child: Text(
            '$label ($count)',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final String name;
  final String role;
  final String id;
  final String joined;
  final String status;
  final String imageUrl;
  final VoidCallback? onManage;

  const _StaffCard({
    required this.name,
    required this.role,
    required this.id,
    required this.joined,
    required this.status,
    required this.imageUrl,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.toLowerCase() == 'active' ? const Color(0xFF059669) : const Color(0xFFEA580C);

    return GestureDetector(
      onTap: onManage,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                Text(role, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('$id • Joined $joined', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCFCE7))),
                child: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
