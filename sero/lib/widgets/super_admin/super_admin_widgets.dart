import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

export 'super_admin_drawer.dart';
export 'super_admin_bottom_nav.dart';

class SuperAdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onMenu;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;
  final int unreadCount;

  /// Optional pill shown under the title (e.g. a date range filter).
  final String? periodLabel;
  final VoidCallback? onPeriodTap;

  /// Leading glyph for the menu button. Defaults to a hamburger menu.
  final IconData leadingIcon;

  const SuperAdminHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onMenu,
    this.onNotifications,
    this.onSettings,
    this.unreadCount = 0,
    this.periodLabel,
    this.onPeriodTap,
    this.leadingIcon = Icons.menu_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: kSuperHeaderGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3316A45C),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: leadingIcon,
                onTap: onMenu,
                tooltip: 'Menu',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotifications,
                tooltip: 'Notifications',
                badge: unreadCount,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings ?? onMenu,
                tooltip: 'Settings',
              ),
            ],
          ),
          if (periodLabel != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onPeriodTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        periodLabel!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final int badge;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: kSuperGreen, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuperAdminMetricCard extends StatelessWidget {
  final SuperAdminMetric metric;
  final IconData icon;
  final Color accent;

  const SuperAdminMetricCard({
    super.key,
    required this.metric,
    required this.icon,
    this.accent = kSuperGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              if (metric.trend.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (metric.trendUp
                            ? kAccentGreen
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metric.trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: metric.trendUp
                            ? kAccentGreen
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        metric.trend,
                        style: GoogleFonts.outfit(
                          color: metric.trendUp
                              ? kAccentGreen
                              : const Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SuperAdminSectionCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget child;

  const SuperAdminSectionCard({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSlateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (actionText != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SuperAdminSocietyCard extends StatelessWidget {
  final SuperAdminSociety society;

  const SuperAdminSocietyCard({super.key, required this.society});

  @override
  Widget build(BuildContext context) {
    final renewal = society.renewalDate == null
        ? 'No renewal date'
        : DateFormat('dd MMM yyyy').format(society.renewalDate!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SuperAdminSocietyThumb(
                name: society.name,
                logoUrl: society.logoUrl,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      society.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            [society.city, society.state]
                                    .where((v) => v.isNotEmpty)
                                    .join(', ')
                                    .isEmpty
                                ? 'Location not set'
                                : [society.city, society.state]
                                    .where((v) => v.isNotEmpty)
                                    .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusPill(label: society.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _MiniFact(
                      label: 'Plan',
                      value:
                          society.plan.isEmpty ? 'Unassigned' : society.plan)),
              Expanded(
                  child: _MiniFact(
                      label: 'Members', value: society.members.toString())),
              Expanded(
                  child:
                      _MiniFact(label: 'MAU', value: society.mau.toString())),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (society.setupCompletion / 100).clamp(0, 1),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(kAccentGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setup ${society.setupCompletion.toStringAsFixed(0)}% · Renewal $renewal · Health ${society.health}',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class SuperAdminAsyncView<T> extends StatelessWidget {
  final AsyncSnapshot<T>? snapshot;
  final T? data;
  final Object? error;
  final bool loading;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  const SuperAdminAsyncView({
    super.key,
    this.snapshot,
    this.data,
    this.error,
    this.loading = false,
    required this.builder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonCard(height: 88),
            SkeletonCard(height: 88),
            SkeletonCard(height: 88, margin: EdgeInsets.zero),
          ],
        ),
      );
    }
    if (error != null) {
      return ErrorRetryView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: onRetry ?? () {},
      );
    }
    final value = data ?? snapshot?.data;
    if (value == null) {
      return const SizedBox.shrink();
    }
    return builder(value);
  }
}

/// Rounded building-photo thumbnail for a society. Falls back to a tinted
/// emerald tile with a building glyph + initial when no image is available.
class SuperAdminSocietyThumb extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double size;

  const SuperAdminSocietyThumb({
    super.key,
    required this.name,
    this.logoUrl = '',
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSuperGreen, kSuperGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 26),
    );

    if (logoUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final Color color;
    if (normalized.contains('active')) {
      color = kAccentGreen;
    } else if (normalized.contains('suspend') || normalized.contains('reject')) {
      color = const Color(0xFFEF4444);
    } else if (normalized.contains('pending') ||
        normalized.contains('trial') ||
        normalized.contains('grace') ||
        normalized.contains('onboard') ||
        normalized.contains('review')) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFF0EA5E9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label.isEmpty
                ? 'Unknown'
                : label[0].toUpperCase() + label.substring(1),
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  final String label;
  final String value;

  const _MiniFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Missing widgets for Super Admin UI screens
class SuperAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const SuperAdminAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kSuperGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: kSuperHeaderGradient),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SuperAdminSectionHeader extends StatelessWidget {
  final String title;
  const SuperAdminSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: kPrimaryGreen,
        ),
      ),
    );
  }
}

class SuperAdminModuleTile extends StatelessWidget {
  final SuperAdminModuleLink module;
  final VoidCallback? onTap;

  const SuperAdminModuleTile({super.key, required this.module, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(module.iconKey), color: kPrimaryGreen),
        ),
        title: Text(
          module.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          module.subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () => Navigator.pushNamed(context, module.route),
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'dashboard': return Icons.dashboard_outlined;
      case 'societies': return Icons.business_outlined;
      case 'approval': return Icons.check_circle_outline_rounded;
      case 'revenue': return Icons.monetization_on_outlined;
      case 'subscriptions': return Icons.card_membership_outlined;
      case 'plans': return Icons.view_carousel_outlined;
      case 'features': return Icons.toggle_on_outlined;
      case 'announcements': return Icons.campaign_outlined;
      case 'support': return Icons.support_agent_outlined;
      case 'health': return Icons.monitor_heart_outlined;
      case 'audit': return Icons.text_snippet_outlined;
      case 'impersonation': return Icons.switch_account_outlined;
      case 'api': return Icons.api_outlined;
      case 'users': return Icons.people_outline;
      case 'settings': return Icons.settings_outlined;
      default: return Icons.link;
    }
  }
}

class SuperAdminAsyncError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const SuperAdminAsyncError({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text('Error: $error', style: GoogleFonts.outfit(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class SuperAdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const SuperAdminEmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class SuperAdminSupportTicketCard extends StatelessWidget {
  final SuperAdminSupportTicket ticket;
  final VoidCallback onTap;

  const SuperAdminSupportTicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = ticket.priority.toLowerCase() == 'urgent' || ticket.priority.toLowerCase() == 'high';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(ticket.subject, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${ticket.id} • ${ticket.societyName}', style: GoogleFonts.outfit(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isUrgent ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isUrgent ? Colors.red[300]! : Colors.grey[300]!),
          ),
          child: Text(
            ticket.priority.toUpperCase(),
            style: GoogleFonts.outfit(
              color: isUrgent ? Colors.red[900] : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
