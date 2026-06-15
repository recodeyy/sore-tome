import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/models/user.dart';
import 'package:sero/widgets/shared/brand_logo.dart';

class AdminHeader extends StatelessWidget {
  final String category;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final bool showMenu;

  const AdminHeader({
    super.key,
    required this.category,
    this.onBack,
    this.onMenu,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: showMenu ? onMenu : onBack,
                icon: Icon(showMenu ? Icons.menu : Icons.arrow_back_ios_new, size: showMenu ? 24 : 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF064E3B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SocietyLogo(size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "The Sero",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              Text(
                category,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1F2937),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Resident\nManagement",
            style: GoogleFonts.outfit(
              color: const Color(0xFF1F2937),
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricHeroCard extends StatelessWidget {
  final int totalUsers;
  final int pendingUsers;
  final int exemptUsers;

  const MetricHeroCard({
    super.key,
    required this.totalUsers,
    required this.pendingUsers,
    required this.exemptUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL RESIDENTS",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$totalUsers",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1F2937),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 60,
              width: 1,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmallMetricRow(
                      label: "Pending",
                      value: "$pendingUsers",
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    SmallMetricRow(
                      label: "Exempt",
                      value: "$exemptUsers",
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const SmallMetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class PendingUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final int index;

  const PendingUserCard({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onReject,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(
              Icons.person_add_rounded,
              color: Color(0xFF1E40AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Flat: ${user.flatNumber} · ${user.phone}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusActionButton(
                icon: Icons.check_rounded,
                color: const Color(0xFF10B981),
                onTap: onApprove,
              ),
              const SizedBox(width: 8),
              StatusActionButton(
                icon: Icons.close_rounded,
                color: const Color(0xFFEF4444),
                onTap: onReject,
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}

class StatusActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const StatusActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class ResidentCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final int index;

  const ResidentCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isExempt = user.maintenanceExempt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isExempt
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                isExempt ? Icons.no_accounts_rounded : Icons.person_rounded,
                color: isExempt ? const Color(0xFFD97706) : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Flat: ${user.flatNumber} · ${user.residentType}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isExempt ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isExempt ? 'Exempt' : 'Paying',
                style: GoogleFonts.outfit(
                  color: isExempt ? const Color(0xFFD97706) : const Color(0xFF1E40AF),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}







