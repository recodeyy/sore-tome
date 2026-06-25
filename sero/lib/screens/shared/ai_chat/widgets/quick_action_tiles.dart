import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/ai_copilot/ai_copilot_models.dart';

class QuickActionTiles extends StatelessWidget {
  final String userRole;
  final Function(String, String?) onAction;
  final List<AiQuickAction>? actions;
  final ValueChanged<AiQuickAction>? onQuickAction;

  const QuickActionTiles({
    super.key,
    required this.userRole,
    required this.onAction,
    this.actions,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin';
    final typedActions = actions;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildListDelegate(typedActions != null
            ? typedActions
                .map(
                  (action) => ActionCard(
                    icon: _iconFor(action.iconName),
                    title: action.title,
                    subtitle: action.subtitle,
                    onTap: () {
                      final handler = onQuickAction;
                      if (handler != null) {
                        handler(action);
                      } else {
                        onAction(action.prompt, action.key);
                      }
                    },
                  ),
                )
                .toList(growable: false)
            : isAdmin
                ? [
                    ActionCard(
                      icon: Icons.campaign_rounded,
                      title: 'Communication',
                      subtitle: 'Draft notices &\nannouncements',
                      onTap: () => onAction(
                          'Help me draft a professional society notice for the members.',
                          'notices'),
                    ),
                    ActionCard(
                      icon: Icons.insert_chart_rounded,
                      title: 'Data Digest',
                      subtitle: 'Analyze resident\ntrends',
                      onTap: () => onAction(
                          'Analyze our society data and provide a digest of resident trends and occupancy.',
                          'stats'),
                    ),
                    ActionCard(
                      icon: Icons.gavel_rounded,
                      title: 'Rule Auditor',
                      subtitle: 'Bylaw compliance\nchecks',
                      onTap: () => onAction(
                          'Audit our society rules for bylaw compliance and suggest improvements.',
                          'rules'),
                    ),
                    ActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Financials',
                      subtitle: 'Budget & levy\ntracking',
                      onTap: () => onAction(
                          'Provide a high-level summary of our treasury, collections, and recent expenditures.',
                          'financials'),
                    ),
                  ]
                : [
                    ActionCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Community Help',
                      subtitle: 'Ask about society\nrules & usage',
                      onTap: () => onAction(
                          'What are the key society rules regarding visitor parking and renovation?',
                          'rules'),
                    ),
                    ActionCard(
                      icon: Icons.engineering_rounded,
                      title: 'Maintenance',
                      subtitle: 'Get help with\nhome issues',
                      onTap: () => onAction(
                          'I have a plumbing issue in my bathroom. What are the society procedures for repairs?',
                          'issues'),
                    ),
                    ActionCard(
                      icon: Icons.event_available_rounded,
                      title: 'Facility Use',
                      subtitle: 'Booking rules\n& guidelines',
                      onTap: () => onAction(
                          'How can I book the clubhouse for a private event? Are there any charges?',
                          'amenities'),
                    ),
                    ActionCard(
                      icon: Icons.description_rounded,
                      title: 'Records Area',
                      subtitle: 'Access meeting\nminutes & docs',
                      onTap: () => onAction(
                          'Summarize the latest meeting minutes (MOM) for important decisions.',
                          'records'),
                    ),
                  ]),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'dashboard':
        return Icons.dashboard_rounded;
      case 'domain_add':
        return Icons.domain_add_rounded;
      case 'engineering':
        return Icons.engineering_rounded;
      case 'event_available':
        return Icons.event_available_rounded;
      case 'event_note':
        return Icons.event_note_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'home_repair_service':
        return Icons.home_repair_service_rounded;
      case 'hub':
        return Icons.hub_rounded;
      case 'insert_chart':
        return Icons.insert_chart_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'pending_actions':
        return Icons.pending_actions_rounded;
      case 'policy':
        return Icons.policy_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'report':
        return Icons.report_rounded;
      case 'sos':
        return Icons.sos_rounded;
      case 'sync_alt':
        return Icons.sync_alt_rounded;
      case 'task_alt':
        return Icons.task_alt_rounded;
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kPrimaryGreen, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
