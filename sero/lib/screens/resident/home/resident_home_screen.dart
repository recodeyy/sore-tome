import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/resident/notice_card.dart';
import 'package:sero/widgets/resident/issue_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/models/guest_pass.dart';
import '../../shared/profile/profile_screen.dart';
import 'package:sero/widgets/shared/shimmer_skeleton.dart';
import '../facilities/facilities_screen.dart';
import '../polls/polls_screen.dart';
import '../voice/voice_mode_screen.dart';
import '../visitors/visitor_approval_screen.dart';
import '../funds/resident_funds_screen.dart';


class ResidentHomeScreen extends ConsumerStatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  ConsumerState<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends ConsumerState<ResidentHomeScreen> {
  
  // Track previous counts for pulse animation
  int? _prevNoticeCount;
  int? _prevIssueCount;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticesStreamProvider);
    final issuesAsync = ref.watch(issuesStreamProvider);
    final balanceAsync = ref.watch(residentBalanceProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceModeScreen())),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.mic, color: kPrimaryGreen),
        label: Text('VOICE MODE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
      ).animate().scale(delay: 1.seconds, duration: 500.ms, curve: Curves.elasticOut),
      body: Column(
        children: [
          _buildTopBar(user),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(residentBalanceProvider);
              },
              color: kPrimaryGreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 160),
                children: [
                  // --- QUICK PAY BANNER ---
                  balanceAsync.when(
                    data: (balance) => balance > 0 
                      ? _buildQuickPayBanner(balance) 
                      : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // --- ACCESS CONTROL (GUEST GATE) ---
                  _sectionLabel('Access Control'),
                  const SizedBox(height: 6),
                  _buildGuestGate(),

                  const SizedBox(height: 24),

                  // --- NEW PHASE 3 QUICK ACTIONS ---
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _quickActionButton(
                          'Book Amenity',
                          Icons.pool_rounded,
                          kPrimaryBlue,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FacilitiesScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickActionButton(
                          'Digital Polls',
                          Icons.how_to_vote_rounded,
                          kPrimaryGreen,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _sectionLabel('Society Pulse'),
                  const SizedBox(height: 6),
                  
                  // --- STAT CARDS ---
                  Row(
                    children: [
                      Expanded(
                        child: issuesAsync.when(
                          data: (issues) {
                            final openCount = issues.where((i) => i.status == 'open').length;
                            final shouldPulse = _prevIssueCount != null && openCount > _prevIssueCount!;
                            _prevIssueCount = openCount;
                            
                            Widget card = _StatCard(
                              value: '$openCount', 
                              label: 'Open issues',
                              icon: Icons.error_outline,
                              color: kAccentGreen,
                            );
                            
                            if (shouldPulse) {
                              return card.animate(onPlay: (controller) => controller.repeat(reverse: true, count: 3))
                                .moveY(begin: 0, end: -4, duration: 400.ms, curve: Curves.easeInOut)
                                .tint(color: kAccentGreen.withValues(alpha: 0.2));
                            }
                            return card;
                          },
                          loading: () => const ShimmerSkeleton(width: double.infinity, height: 140, borderRadius: 24),
                          error: (_, __) => const _StatCardPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: noticesAsync.when(
                          data: (notices) {
                            final count = notices.length;
                            final shouldPulse = _prevNoticeCount != null && count > _prevNoticeCount!;
                            _prevNoticeCount = count;
                            
                            Widget card = _StatCard(
                              value: '$count', 
                              label: 'New notices',
                              icon: Icons.notifications_none,
                              color: kAccentBlue,
                            );
                            
                            if (shouldPulse) {
                              return card.animate(onPlay: (controller) => controller.repeat(reverse: true, count: 3))
                                .moveY(begin: 0, end: -4, duration: 400.ms, curve: Curves.easeInOut)
                                .tint(color: kAccentBlue.withValues(alpha: 0.2));
                            }
                            return card;
                          },
                          loading: () => const ShimmerSkeleton(width: double.infinity, height: 140, borderRadius: 24),
                          error: (_, __) => const _StatCardPlaceholder(),
                        ),
                      ),
                    ],
                  ),

                  
                  const SizedBox(height: 24),
                  
                  _sectionLabel('Latest notices'),
                  const SizedBox(height: 6),

                  noticesAsync.when(
                    data: (notices) => Column(
                      children: notices.take(3).map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NoticeCard(notice: n),
                      )).toList(),
                    ),
                    loading: () => const ListSkeleton(itemCount: 3),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  _sectionLabel('My recent issues'),
                  const SizedBox(height: 6),
                  issuesAsync.when(
                    data: (issues) => Column(
                      children: issues.take(3).map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IssueCard(issue: i),
                      )).toList(),
                    ),
                    loading: () => const ListSkeleton(itemCount: 3),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestGate() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pre-approve Guest',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Generate entry pass for your visitor',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                // ✅ BUG-09 FIX: Navigate to VisitorApprovalScreen to manage visitor entries
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VisitorApprovalScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final passesAsync = ref.watch(activeGuestPassesProvider);
              return passesAsync.when(
                data: (passes) {
                  if (passes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No active passes today",
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: passes.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final p = passes[index];
                        final categoryColor = p.category == GuestPassCategory.delivery ? kAccentBlue : kAccentGreen;
                        final categoryIcon = p.category == GuestPassCategory.delivery ? Icons.delivery_dining_rounded : Icons.people_rounded;
                        return _guestEntryMini(p.visitorName, p.status.toString().split('.').last.toUpperCase(), categoryIcon, categoryColor);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Text('Error: $e'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _guestEntryMini(String type, String status, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    status,
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPayBanner(double balance) {
    // ✅ BUG-12 FIX: Derive current month name dynamically instead of hardcoding
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonth = monthNames[DateTime.now().month - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: kPrimaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${balance.toStringAsFixed(0)} Due',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                Text(
                  'Maintenance for $currentMonth is pending',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            // ✅ BUG-09 FIX: Navigate to ResidentFundsScreen to complete payment
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResidentFundsScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('PAY NOW', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate().slideX(begin: 1, curve: Curves.easeOutCubic, duration: 600.ms);
  }

  Widget _buildTopBar(dynamic user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: kPremiumGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33064E3B),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    user?.name ?? "Resident",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: kAccentGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sunset Valley Society • Flat ${user?.flatNumber ?? "..."}',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value, 
    required this.label, 
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12, 
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardPlaceholder extends StatelessWidget {
  const _StatCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.3)),
      ),
      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen))),
    );
  }
}
