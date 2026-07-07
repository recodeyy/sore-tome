import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/providers/admin/users_provider.dart';
import 'package:sero/models/user.dart';

// Modularized Widgets
import 'widgets/admin_users_widgets.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/screens/admin/members/join_requests_screen.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

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
      backgroundColor: kSlateBg,
      drawer: const AdminDrawer(),
      body: DefaultTabController(
        length: 3,
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
                    Tab(text: "Residents"),
                    Tab(text: "Join Requests"),
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
                const JoinRequestsScreen(embedded: true),
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
          return EmptyState(
            icon: Icons.person_outline_rounded,
            title: 'No pending approvals',
            message: 'New resident sign-ups awaiting approval will show here.',
            actionLabel: 'Refresh',
            onAction: () => ref.invalidate(pendingUsersProvider),
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
      loading: () => const SkeletonList(itemCount: 4, itemHeight: 110),
      error: (e, st) => ErrorRetryView(
        message: 'Could not load pending approvals.',
        onRetry: () => ref.invalidate(pendingUsersProvider),
      ),
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
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No residents yet',
            message: 'Approved residents of your society will appear here.',
            actionLabel: 'Refresh',
            onAction: () => ref.invalidate(allUsersProvider),
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
      loading: () => const SkeletonList(itemCount: 5, itemHeight: 88),
      error: (e, st) => ErrorRetryView(
        message: 'Could not load residents.',
        onRetry: () => ref.invalidate(allUsersProvider),
      ),
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







