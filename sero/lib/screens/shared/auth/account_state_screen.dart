import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';

enum AccountStateType {
  staffInactive,
  staffNoAssignment,
  societySuspended,
  accountSuspended,
  pendingApproval,
  rejected,
  movedOut,
  sessionExpired,
  noPermittedWorkspace,
  maintenanceMode,
  offline,
  rateLimited,
  invitationExpired,
  invitationUsed,
}

class AccountStateScreen extends StatelessWidget {
  final AccountStateType state;
  final String? referenceId;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const AccountStateScreen({
    super.key,
    required this.state,
    this.referenceId,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  _StateConfig _getConfig() {
    switch (state) {
      case AccountStateType.staffInactive:
        return _StateConfig(
          icon: Icons.badge_outlined,
          iconColor: Colors.orange,
          title: 'Employment Inactive',
          description:
              'Your staff account is currently inactive. Please contact your supervisor or society admin to reactivate your account.',
          primaryLabel: 'Contact Admin',
          secondaryLabel: 'Log Out',
          iconBg: Colors.orange.withValues(alpha: 0.12),
        );
      case AccountStateType.staffNoAssignment:
        return _StateConfig(
          icon: Icons.assignment_late_outlined,
          iconColor: Colors.amber,
          title: 'No Active Assignment',
          description:
              'You are not currently assigned to any active post or zone. Please contact your supervisor for your current assignment.',
          primaryLabel: 'Contact Supervisor',
          secondaryLabel: 'Log Out',
          iconBg: Colors.amber.withValues(alpha: 0.12),
        );
      case AccountStateType.societySuspended:
        return _StateConfig(
          icon: Icons.domain_disabled_outlined,
          iconColor: Colors.redAccent,
          title: 'Society Account Suspended',
          description:
              'Access to this society has been temporarily suspended by the platform. Please contact SERO support for assistance.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Log Out',
          iconBg: Colors.redAccent.withValues(alpha: 0.12),
        );
      case AccountStateType.accountSuspended:
        return _StateConfig(
          icon: Icons.block_outlined,
          iconColor: Colors.redAccent,
          title: 'Account Suspended',
          description:
              'Your account has been suspended. Please contact your society admin or SERO support to resolve this issue.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Log Out',
          iconBg: Colors.redAccent.withValues(alpha: 0.12),
        );
      case AccountStateType.pendingApproval:
        return _StateConfig(
          icon: Icons.hourglass_empty_rounded,
          iconColor: kAccentGreen,
          title: 'Waiting for Approval',
          description:
              'Your registration is pending approval from your society admin. You will be notified once approved.',
          primaryLabel: 'Refresh Status',
          secondaryLabel: 'Log Out',
          iconBg: kAccentGreen.withValues(alpha: 0.12),
        );
      case AccountStateType.rejected:
        return _StateConfig(
          icon: Icons.cancel_outlined,
          iconColor: Colors.redAccent,
          title: 'Registration Not Approved',
          description:
              'Your registration was not approved. Please contact your society admin for more information or register again.',
          primaryLabel: 'Contact Admin',
          secondaryLabel: 'Try Again',
          iconBg: Colors.redAccent.withValues(alpha: 0.12),
        );
      case AccountStateType.movedOut:
        return _StateConfig(
          icon: Icons.home_outlined,
          iconColor: Colors.blueGrey,
          title: 'Unit No Longer Active',
          description:
              'Your residency at this unit has ended. If this is incorrect, please contact your society admin.',
          primaryLabel: 'Contact Admin',
          secondaryLabel: 'Log Out',
          iconBg: Colors.blueGrey.withValues(alpha: 0.12),
        );
      case AccountStateType.sessionExpired:
        return _StateConfig(
          icon: Icons.timer_off_outlined,
          iconColor: Colors.deepOrange,
          title: 'Session Expired',
          description:
              'Your session has expired for security reasons. Please log in again to continue.',
          primaryLabel: 'Log In Again',
          secondaryLabel: null,
          iconBg: Colors.deepOrange.withValues(alpha: 0.12),
        );
      case AccountStateType.noPermittedWorkspace:
        return _StateConfig(
          icon: Icons.workspaces_outlined,
          iconColor: Colors.purple,
          title: 'No Access Found',
          description:
              'No active workspace was found for your account. Please contact your admin or verify your membership.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Log Out',
          iconBg: Colors.purple.withValues(alpha: 0.12),
        );
      case AccountStateType.maintenanceMode:
        return _StateConfig(
          icon: Icons.construction_outlined,
          iconColor: Colors.amber,
          title: 'Scheduled Maintenance',
          description:
              'SERO is currently undergoing scheduled maintenance. Please check back shortly. We apologize for the inconvenience.',
          primaryLabel: 'Try Again',
          secondaryLabel: null,
          iconBg: Colors.amber.withValues(alpha: 0.12),
        );
      case AccountStateType.offline:
        return _StateConfig(
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.grey,
          title: 'You\'re Offline',
          description:
              'Please check your internet connection and try again. Some features may be unavailable.',
          primaryLabel: 'Retry',
          secondaryLabel: null,
          iconBg: Colors.grey.withValues(alpha: 0.12),
        );
      case AccountStateType.rateLimited:
        return _StateConfig(
          icon: Icons.lock_clock_outlined,
          iconColor: Colors.deepOrange,
          title: 'Too Many Attempts',
          description:
              'Access temporarily limited due to too many failed attempts. Please wait a few minutes and try again.',
          primaryLabel: 'Try Later',
          secondaryLabel: 'Contact Support',
          iconBg: Colors.deepOrange.withValues(alpha: 0.12),
        );
      case AccountStateType.invitationExpired:
        return _StateConfig(
          icon: Icons.mail_outline_rounded,
          iconColor: Colors.amber,
          title: 'Invitation Expired',
          description:
              'The invitation link you used has expired. Please request a new invitation from your society admin.',
          primaryLabel: 'Request New Invite',
          secondaryLabel: 'Log Out',
          iconBg: Colors.amber.withValues(alpha: 0.12),
        );
      case AccountStateType.invitationUsed:
        return _StateConfig(
          icon: Icons.check_circle_outline_rounded,
          iconColor: kAccentGreen,
          title: 'Invitation Already Used',
          description:
              'This invitation has already been accepted. Please log in with your existing account credentials.',
          primaryLabel: 'Go to Login',
          secondaryLabel: null,
          iconBg: kAccentGreen.withValues(alpha: 0.12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _getConfig();

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cfg.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, color: cfg.iconColor, size: 48),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                cfg.title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                cfg.description,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 300.ms),
              if (referenceId != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reference ID: $referenceId',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              if (onPrimaryAction != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    child: Text(
                      cfg.primaryLabel,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
              if (cfg.secondaryLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(
                    cfg.secondaryLabel!,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StateConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String primaryLabel;
  final String? secondaryLabel;

  const _StateConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.primaryLabel,
    this.secondaryLabel,
  });
}
