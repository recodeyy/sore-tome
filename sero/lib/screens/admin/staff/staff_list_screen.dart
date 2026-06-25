import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/sero_search_bar.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

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
              onFilterTap: () => AdminActions.comingSoon(context, 'Advanced filters'),
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
                    return _StaffCard(
                      name: (staff['name'] ?? staff['full_name'] ?? '').toString(),
                      role: (staff['role'] ?? staff['designation'] ?? '').toString(),
                      id: (staff['id'] ?? staff['staff_id'] ?? '').toString(),
                      joined: joined,
                      status: (staff['status'] ?? '').toString(),
                      imageUrl: (staff['image'] ?? staff['photo'] ?? '').toString(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AdminActions.comingSoon(context, 'Adding staff'),
        backgroundColor: const Color(0xFF064E3B),
        child: const Icon(Icons.add, color: Colors.white),
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

  const _StaffCard({
    required this.name,
    required this.role,
    required this.id,
    required this.joined,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.toLowerCase() == 'active' ? const Color(0xFF059669) : const Color(0xFFEA580C);

    return Container(
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
    );
  }
}
