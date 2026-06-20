import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

const _kEmerald = kSuperGreen;
const _kBlue = Color(0xFF0EA5E9);
const _kAmber = Color(0xFFF59E0B);
const _kViolet = Color(0xFF8B5CF6);
const _kSlate = Color(0xFF64748B);

Color _roleColor(String role) {
  final r = role.toLowerCase();
  if (r.contains('super')) return _kEmerald;
  if (r.contains('support')) return _kBlue;
  if (r.contains('finance') || r.contains('treasurer')) return _kAmber;
  if (r.contains('audit')) return _kViolet;
  return _kSlate;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class SuperAdminUsersScreen extends ConsumerStatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  ConsumerState<SuperAdminUsersScreen> createState() =>
      _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends ConsumerState<SuperAdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(superAdminUsersProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Users Management',
            subtitle: 'Platform operators & roles',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SuperAdminAsyncView<List<JsonMap>>(
              loading: users.isLoading,
              error: users.hasError ? users.error : null,
              data: users.valueOrNull,
              onRetry: () => ref.invalidate(superAdminUsersProvider),
              builder: (list) => _buildContent(list),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContent(List<JsonMap> list) {
    int total = list.length;
    int admins = 0;
    int active = 0;
    for (final u in list) {
      final role = (u['role'] ?? 'user').toString().toLowerCase();
      final status = (u['status'] ?? '').toString().toLowerCase();
      if (role.contains('admin') || role.contains('super')) admins++;
      if (status == 'approved' || status == 'active') active++;
    }

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? list
        : list.where((u) {
            final name = (u['name'] ?? u['full_name'] ?? '').toString();
            final email = (u['email'] ?? '').toString();
            final role = (u['role'] ?? '').toString();
            return name.toLowerCase().contains(q) ||
                email.toLowerCase().contains(q) ||
                role.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuperAdminSectionCard(
          title: 'Overview',
          child: Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total',
                  value: '$total',
                  icon: Icons.group_rounded,
                  accent: _kEmerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'Admins',
                  value: '$admins',
                  icon: Icons.shield_rounded,
                  accent: _kViolet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'Active',
                  value: '$active',
                  icon: Icons.bolt_rounded,
                  accent: _kBlue,
                ),
              ),
            ],
          ),
        ),
        _SearchField(
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 14),
        SuperAdminSectionCard(
          title: 'Platform Users',
          child: filtered.isEmpty
              ? const SuperAdminEmptyState(
                  icon: Icons.people_outline,
                  title: 'No platform users',
                  message: 'No operator accounts match this view.',
                )
              : Column(
                  children: [
                    for (final u in filtered) _UserCard(user: u),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search users by name, email or role',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kSuperGreen, width: 1.6),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final JsonMap user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? user['full_name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'user').toString();
    final accent = _roleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: GoogleFonts.outfit(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: GoogleFonts.outfit(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
