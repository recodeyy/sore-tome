import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/common/info_list_tile.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/providers/shared/notification_provider.dart';
import 'package:sero/widgets/shared/admin_drawer.dart';
import 'society_profile_screen.dart';
import 'wings_blocks_screen.dart';
import 'flats_units_screen.dart';
import 'committee_members_screen.dart';

/// Society Setup Home — Screen 1 of 6
/// Main hub showing society overview, quick links, and summary stats.
class SocietySetupHomeScreen extends ConsumerWidget {
  const SocietySetupHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final profileAsync = ref.watch(societyProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B), size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Text(
              'Society Setup',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 22),
                      onPressed: null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Society Banner Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileAsync.maybeWhen(
                              data: (d) => ((d['profile'] as Map?)?['name'] ?? '').toString(),
                              orElse: () => '',
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profileAsync.maybeWhen(
                              data: (d) => ((d['profile'] as Map?)?['type'] ?? '').toString(),
                              orElse: () => '',
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge.active(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu Items ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                InfoListTile(
                  icon: Icons.business,
                  title: 'Society Profile',
                  subtitle: 'Manage society information',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SocietyProfileScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                InfoListTile(
                  icon: Icons.view_column_outlined,
                  title: 'Wings & Blocks',
                  subtitle: 'Manage wings and blocks',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WingsBlocksScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                InfoListTile(
                  icon: Icons.door_front_door_outlined,
                  title: 'Flats / Units',
                  subtitle: 'Manage all flats and units',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlatsUnitsScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                InfoListTile(
                  icon: Icons.people_outline,
                  title: 'Members',
                  subtitle: 'Manage member profiles',
                  onTap: () => Navigator.pushNamed(context, '/admin/society/flats'),
                ),
                const SizedBox(height: 8),
                InfoListTile(
                  icon: Icons.groups_outlined,
                  title: 'Committee Members',
                  subtitle: 'Manage committee members',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommitteeMembersScreen()),
                  ),
                ),
              ]),
            ),
          ),

          // ── Overview Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text(
                'Overview',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
            ),
          ),
          profileAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: LiveLoadingView(label: 'Loading overview…'),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(societyProfileProvider),
              ),
            ),
            data: (d) {
              final structure = (d['structure'] as Map?) ?? const {};
              String count(List<String> keys) {
                for (final k in keys) {
                  if (structure[k] != null) return structure[k].toString();
                }
                return '0';
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    CompactStatCard(
                      value: count(['totalWings', 'total_wings']),
                      label: 'Total Wings',
                      icon: Icons.view_column,
                    ),
                    CompactStatCard(
                      value: count(['totalBlocks', 'total_blocks']),
                      label: 'Total Blocks',
                      icon: Icons.view_module,
                    ),
                    CompactStatCard(
                      value: count(['totalFlats', 'total_units', 'total_flats']),
                      label: 'Total Flats',
                      icon: Icons.apartment,
                    ),
                    CompactStatCard(
                      value: count(['totalMembers', 'total_members']),
                      label: 'Total Members',
                      icon: Icons.people,
                    ),
                  ],
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
