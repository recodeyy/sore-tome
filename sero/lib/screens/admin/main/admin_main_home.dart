import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/providers/admin/dashboard_provider.dart';
import 'package:sero/providers/shared/funds_provider.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'admin_users_screen.dart';
import 'admin_maintenance_screen.dart';
import 'admin_access_logs_screen.dart';
import 'admin_channels_screen.dart';
import '../post_notice_screen.dart';
import 'widgets/admin_home_widgets.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/models/guest_pass.dart';

class AdminMainHome extends ConsumerWidget {
  const AdminMainHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        color: const Color(0xFF345D7E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const AdminHomeHeader(
              title: "Admin\nDashboard",
              subtitle: "Estate status updated real-time.",
            ),
            Consumer(
              builder: (context, ref, child) {
                final dashboardAsync = ref.watch(dashboardProvider);
                
                return dashboardAsync.when(
                  data: (stats) => SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInvitationBanner(context, ref),
                      _buildMorningBriefing(context, ref),
                      LiveActivityHero(
                        count: stats.activeResidentsCount.toString(),
                        label: "Residents\nOn-Site",
                        onManageAccess: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                        ),
                        onAccessLogs: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminAccessLogsScreen(),
                            ),
                          );
                        },
                      ),
                      PendingApprovalsHero(
                        count: stats.pendingApprovalsCount.toString().padLeft(2, '0'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                        ),
                        children: stats.topIssues.isEmpty
                            ? [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          "All clear! No urgent issues.",
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ]
                            : stats.topIssues.map((issue) {
                                final color = issue.priority == 'high'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF3B82F6);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PendingItemTile(
                                    name: issue.title,
                                    priority: issue.priority.toUpperCase(),
                                    color: color,
                                  ),
                                );
                              }).toList(),
                      ),
                      RecentUpdatesSection(
                        onNewPost: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostNoticeScreen()),
                        ),
                        children: stats.recentUpdates.isEmpty
                            ? [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      "No recent notices or events.",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                )
                              ]
                            : stats.recentUpdates.expand((update) {
                                return [
                                  RecentUpdateTile(
                                    category: update.category ?? "UPDATE",
                                    title: update.title,
                                    subtitle: update.body ?? update.description ?? "",
                                    time: _formatTime(update.createdAt),
                                    badgeColor: update.type == 'event'
                                        ? const Color(0xFFDBEAFE)
                                        : const Color(0xFFE0E7FF),
                                    textColor: update.type == 'event'
                                        ? const Color(0xFF1E40AF)
                                        : const Color(0xFF4338CA),
                                  ),
                                  const Divider(height: 32, color: Color(0xFFF1F5F9)),
                                ];
                              }).toList()
                          ..removeLast(),
                      ),
                      FinancialOverviewCard(
                        total: _formatCurrency(stats.financials.totalCollected, stats.financials.currency),
                        progress: stats.financials.percentage / 100,
                        target: _formatCurrency(stats.financials.target, stats.financials.currency),
                        percentage: "${stats.financials.percentage}%",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
                        ),
                        onEditTarget: () => _showEditTargetBottomSheet(context, ref, stats.financials.target),
                      ),

                      // --- VISITOR MONITOR (Gate Security) ---
                      _buildVisitorMonitor(context, ref),
                      
                      const SizedBox(height: 100),
                    ]),
                  ),
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF345D7E)),
                    ),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              "Failed to sync dashboard",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF345D7E),
                                foregroundColor: Colors.white,
                                minimumSize: Size.zero,
                              ),
                              child: const Text("Reconnect Now"),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationBanner(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(Icons.hub_rounded, color: Color(0xFF3B82F6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hub Management",
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    "Create new channels or broadcast to residents.",
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminChannelsScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF345D7E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("MANAGE", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorningBriefing(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingProvider);

    return briefingAsync.when(
      data: (data) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF345D7E), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF345D7E).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Morning Pulse",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "AI INSIGHT",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data['summary'] ?? "Scanning society hubs for updates...",
                style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...(data['insights'] as List? ?? []).take(2).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.amber, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.toString(),
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatCurrency(double amount, String currency) {
    if (amount >= 1000000) {
      return "$currency${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "$currency${(amount / 1000).toStringAsFixed(1)}K";
    }
    return "$currency${amount.toStringAsFixed(0)}";
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "Just now";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _showEditTargetBottomSheet(BuildContext context, WidgetRef ref, double currentTarget) {
    final controller = TextEditingController(text: currentTarget.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Target',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            "Set monthly society goal.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF345D7E),
                      ),
                      decoration: InputDecoration(
                        prefixText: "Rs ",
                        prefixStyle: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final newTarget = double.tryParse(controller.text);
                        if (newTarget != null) {
                          setModalState(() => isSaving = true);
                          try {
                            await ref.read(fundsProvider.notifier).updateSettings(target: newTarget);
                            if (context.mounted) Navigator.pop(context);
                            ref.read(dashboardProvider.notifier).refresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Collection target updated!")),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          } finally {
                            if (context.mounted) setModalState(() => isSaving = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            "Save Changes",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisitorMonitor(BuildContext context, WidgetRef ref) {
    final passesAsync = ref.watch(allTodayGuestPassesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "VISITOR MONITOR",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.security, size: 16, color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 12),
          passesAsync.when(
            data: (passes) {
              if (passes.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      "No pre-approved visitors today",
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                );
              }
              return Column(
                children: passes.take(5).map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: p.status == GuestPassStatus.arrived ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          p.category == GuestPassCategory.delivery ? Icons.delivery_dining_rounded : Icons.person_rounded,
                          color: p.status == GuestPassStatus.arrived ? Colors.green : const Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.visitorName,
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                            ),
                            Text(
                              "Flat ${p.flatNumber} • ${p.category.name.toUpperCase()}",
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (p.status == GuestPassStatus.approved)
                        ElevatedButton(
                          onPressed: () => CommunityActions.checkInVisitor(p.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF345D7E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("CHECK-IN", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else if (p.status == GuestPassStatus.arrived)
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    ],
                  ),
                ).animate().fade().slideX(begin: 0.1)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text("Error loading visitors: $e"),
          ),
        ],
      ),
    );
  }
}







