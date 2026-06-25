import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/admin/users_provider.dart';
import '../../../models/user.dart';
import '../../../app/theme.dart';
import '../../../widgets/shared/shimmer_skeleton.dart';

class SecretaryHome extends ConsumerStatefulWidget {
  const SecretaryHome({super.key});

  @override
  ConsumerState<SecretaryHome> createState() => _SecretaryHomeState();
}

class _SecretaryHomeState extends ConsumerState<SecretaryHome> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Resident Management',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            labelColor: kPrimaryGreen,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: kPrimaryGreen,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'APPROVAL QUEUE'),
              Tab(text: 'DIRECTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildApprovalQueue(),
            _buildDirectory(),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalQueue() {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return pendingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState(
            Icons.verified_user_outlined,
            'Queue Clear',
            'No pending registration requests at the moment.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _ResidentRequestCard(user: user);
          },
        );
      },
      loading: () => const _LoadingList(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDirectory() {
    final allAsync = ref.watch(allUsersProvider);

    return allAsync.when(
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No residents found'));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _DirectoryItem(user: user);
          },
        );
      },
      loading: () => const _LoadingList(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(sub, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}

class _ResidentRequestCard extends ConsumerWidget {
  final UserModel user;
  const _ResidentRequestCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryGreen.withValues(alpha: 0.1),
                child: Text(user.name[0], style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Flat ${user.flatNumber} • ${user.phone}', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(userOperationsProvider).rejectUser(user.id, 'Information mismatch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFF1F5F9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(userOperationsProvider).approveUser(user.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('APPROVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _DirectoryItem extends ConsumerWidget {
  final UserModel user;
  const _DirectoryItem({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ['admin', 'main_admin', 'secretary', 'treasurer'].contains(user.role);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
          child: Icon(
            isAdmin ? Icons.shield_rounded : Icons.person_outline_rounded,
            color: isAdmin ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
            size: 20,
          ),
        ),
        title: Text(user.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        subtitle: Text('Flat ${user.flatNumber} • ${user.role.toUpperCase()}', style: GoogleFonts.outfit(fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
          onSelected: (val) {
             ref.read(userOperationsProvider).updateUser(user.id, {'role': val});
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'resident', child: Text('Set as Resident')),
            const PopupMenuItem(value: 'secretary', child: Text('Set as Secretary')),
            const PopupMenuItem(value: 'treasurer', child: Text('Set as Treasurer')),
            const PopupMenuItem(value: 'admin', child: Text('Set as Admin')),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ShimmerSkeleton(height: 120, width: double.infinity),
      ),
    );
  }
}
