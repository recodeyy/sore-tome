import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/providers/admin/users_provider.dart';
import 'package:sero/models/user.dart';

// Modularized Widgets
import 'widgets/admin_users_widgets.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingUsersProvider);
    final allAsync = ref.watch(allUsersProvider);

    final totalUsers = allAsync.maybeWhen(
      data: (users) => users.length,
      orElse: () => 0,
    );
    final pendingUsersCount = pendingAsync.maybeWhen(
      data: (users) => users.length,
      orElse: () => 0,
    );
    final exemptUsersCount = allAsync.maybeWhen(
      data: (users) => users.where((u) => u.maintenanceExempt).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const AdminDrawer(),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Builder(
              builder: (context) => AdminHeader(
                category: "Residents",
                showMenu: true,
                onMenu: () => Scaffold.of(context).openDrawer(),
                onBack: () => Navigator.pop(context),
              ),
            ),

            MetricHeroCard(
              totalUsers: totalUsers,
              pendingUsers: pendingUsersCount,
              exemptUsers: exemptUsersCount,
            ),
            const SizedBox(height: 32),

            // --- MODERN TAB SWITCHER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Color(0xFF1F2937),
                  unselectedLabelColor: Color(0xFF64748B),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: "Pending"),
                    Tab(text: "Residents List"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- LIST CONTENT ---
            Expanded(
              child: TabBarView(children: [
                _PendingTab(),
                _AllUsersTab(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return pendingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 64,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fade();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final u = users[index];
            return PendingUserCard(
              user: u,
              index: index,
              onApprove: () => ref.read(userOperationsProvider).approveUser(u.id),
              onReject: () => ref.read(userOperationsProvider).rejectUser(u.id, 'Rejected by admin'),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF345D7E)),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _AllUsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allUsersProvider);

    return allAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final u = users[index];
            return ResidentCard(
              user: u,
              index: index,
              onTap: () => _showEditDialog(context, ref, u),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF345D7E)),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, UserModel u) {
    String selectedType = u.residentType;
    bool exempt = u.maintenanceExempt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Edit ${u.name}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: ['owner', 'tenant', 'guest']
                      .map(
                        (x) => DropdownMenuItem(
                          value: x,
                          child: Text(x.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v ?? selectedType),
                  decoration: const InputDecoration(labelText: 'Resident Type'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Maintenance Exempt'),
                  value: exempt,
                  onChanged: (v) => setState(() => exempt = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(userOperationsProvider).updateUser(u.id, {
                    'residentType': selectedType,
                    'maintenanceExempt': exempt,
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}







