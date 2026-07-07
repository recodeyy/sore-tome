import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';
import 'admin_shell.dart';
import 'staff_shell.dart';
import 'super_admin_shell.dart';
import '../screens/shared/auth/welcome_landing_screen.dart';
import '../screens/shared/auth/role_login_landing_screen.dart';
import '../screens/shared/auth/role_login_form_screen.dart';
import '../screens/shared/auth/workspace_selector_screen.dart';
import '../screens/shared/auth/register_screen.dart';
import '../screens/shared/ai/ai_society_pulse_screen.dart';
import '../screens/shared/ai/complaint_intelligence_screen.dart';
import '../screens/shared/ai/predictive_maintenance_screen.dart';
import '../screens/shared/ai/financial_anomaly_screen.dart';
import '../screens/resident/issues/post_issue_screen.dart';
import '../screens/resident/issues/resident_issues_screen.dart';
import '../screens/resident/visitors/visitor_approval_screen.dart';
import '../screens/resident/visitors/invite_visitor_screen.dart';
import '../screens/resident/onboarding/society_search_screen.dart';
import '../screens/resident/onboarding/request_status_screen.dart';
import '../screens/guard/gate_screen.dart';
import '../screens/guard/staff_tasks_screen.dart';
import '../screens/shared/ai_chat/ai_chat_screen.dart';
import '../screens/resident/payments/bills_dues_screen.dart';
import '../screens/resident/amenities/amenities_home_screen.dart';
import '../screens/admin/post_notice_screen.dart';
import '../screens/admin/manage_issues_screen.dart';
import '../screens/shared/splash_screen.dart';
import 'package:sero/widgets/shared/auth_guard.dart';
import '../screens/admin/dashboard/dashboard_home_screen.dart';
import '../screens/admin/dashboard/dashboard_revenue_screen.dart';
import '../screens/admin/dashboard/dashboard_insights_screen.dart';
import '../screens/admin/dashboard/dashboard_notices_screen.dart';
import '../screens/admin/society/society_setup_home_screen.dart';
import '../screens/admin/society/society_profile_screen.dart';
import '../screens/admin/society/society_information_screen.dart';
import '../screens/admin/society/society_logo_screen.dart';
import '../screens/admin/society/wings_blocks_screen.dart';
import '../screens/admin/society/flats_units_screen.dart';
import '../screens/admin/reports/reports_dashboard_screen.dart';
import '../screens/admin/reports/financial_report_screen.dart';
import '../screens/admin/finance/finance_dashboard_screen.dart';
import '../screens/admin/finance/generate_bills_screen.dart';
import '../screens/admin/finance/bill_details_screen.dart';
import '../screens/admin/finance/payment_history_screen.dart';
import '../screens/admin/finance/financial_ledger_screen.dart';
import '../screens/admin/finance/income_reports_screen.dart';
import '../screens/admin/notices/notices_screen.dart';
import '../screens/admin/notices/create_notice_screen.dart';
import '../screens/admin/complaints/complaints_dashboard_screen.dart';
import '../screens/admin/complaints/complaint_details_screen.dart';
import '../screens/admin/staff/staff_dashboard_screen.dart';
import '../screens/admin/staff/staff_list_screen.dart';
import '../screens/admin/staff/amenities_dashboard_screen.dart';

import '../screens/admin/parking/parking_dashboard_screen.dart';
import '../screens/admin/parking/slot_allocation_screen.dart';
import '../screens/admin/assets/assets_dashboard_screen.dart';
import '../screens/admin/assets/lift_details_screen.dart';
import '../screens/shared/notifications/notifications_screen.dart';
import '../screens/shared/profile/profile_screen.dart';
import '../screens/shared/profile/edit_profile_screen.dart';
import '../screens/shared/settings/settings_screen.dart';

import '../screens/super_admin/kyc_verification_screen.dart';
import '../screens/super_admin/setup_progress_screen.dart';
import '../screens/super_admin/feature_controls_screen.dart';
import '../screens/super_admin/api_access_screen.dart';
import '../screens/super_admin/audit_log_screen.dart';
import '../screens/super_admin/system_health_screen.dart';
import '../screens/super_admin/impersonation_screen.dart';
import '../screens/super_admin/super_admin_plans_screen.dart';
import '../screens/super_admin/super_admin_announcements_screen.dart';
import '../screens/super_admin/super_admin_reports_screen.dart';
import '../screens/super_admin/super_admin_analytics_screen.dart';
import '../screens/super_admin/super_admin_users_screen.dart';
import '../screens/super_admin/super_admin_approvals_screen.dart';
import '../screens/super_admin/super_admin_settings_screen.dart';
import '../screens/super_admin/super_admin_support_screen.dart';

/// Global navigator key so services (push-notification deep links) can
/// navigate without a BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SocietyApp extends StatelessWidget {
  const SocietyApp({super.key});

  /// Registered named routes. Exposed statically so NotificationService can
  /// validate incoming deep links before navigating.
  static final Map<String, WidgetBuilder> routes = {
        '/splash':            (_) => const SplashScreen(),
        '/welcome':           (_) => const WelcomeLandingScreen(),
        '/login':             (_) => const RoleLoginLandingScreen(),
        '/login/super-admin': (_) => const RoleLoginFormScreen(portal: 'super-admin'),
        '/login/admin':       (_) => const RoleLoginFormScreen(portal: 'admin'),
        '/login/staff':       (_) => const RoleLoginFormScreen(portal: 'staff'),
        '/login/resident':    (_) => const RoleLoginFormScreen(portal: 'resident'),
        '/workspace-select':  (_) => const WorkspaceSelectorScreen(),
        '/register':          (_) => const RegisterScreen(),
        
        // --- PROTECTED ROUTES ---
        '/home':              (_) => const AuthGuard(child: MainShell()),
        '/admin':             (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'admin', 'treasurer', 'secretary', 'committee_member'],
                                      child: AdminShell(),
                                    ),
        '/staff':             (_) => const AuthGuard(
                                      allowedRoles: ['guard', 'security_manager', 'facility_manager', 'supervisor', 'maintenance_staff', 'housekeeping_staff', 'reception_staff', 'parcel_desk_staff', 'staff'],
                                      child: StaffShell(),
                                    ),
        '/super-admin':       (_) => const AuthGuard(
                                      allowedRoles: ['super_admin', 'superadmin', 'platform_owner', 'platform_operations', 'platform_support', 'platform_security'],
                                      child: SuperAdminShell(),
                                    ),
        '/super-admin/kyc':           (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: KycVerificationScreen()),
        '/super-admin/setup-progress':(_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SetupProgressScreen()),
        '/super-admin/features':      (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: FeatureControlsScreen()),
        '/super-admin/api-access':    (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: ApiAccessScreen()),
        '/super-admin/audit':         (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: AuditLogScreen()),
        '/super-admin/system-health': (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SystemHealthScreen()),
        '/super-admin/impersonation': (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: ImpersonationScreen()),
        '/super-admin/plans':         (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminPlansScreen()),
        '/super-admin/subscriptions': (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminPlansScreen()),
        '/super-admin/announcements': (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminAnnouncementsScreen()),
        '/super-admin/reports':       (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminReportsScreen()),
        '/super-admin/analytics':     (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminAnalyticsScreen()),
        '/super-admin/users':         (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminUsersScreen()),
        '/super-admin/approvals':     (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminApprovalsScreen()),
        '/super-admin/settings':      (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminSettingsScreen()),
        '/super-admin/support':       (_) => const AuthGuard(allowedRoles: ['super_admin', 'superadmin'], child: SuperAdminSupportScreen()),
        '/post-issue':        (_) => const AuthGuard(child: PostIssueScreen()),
        '/admin/post-notice': (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'secretary'],
                                      child: PostNoticeScreen(),
                                    ),
        '/admin/manage-issues': (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'secretary'],
                                      child: ManageIssuesScreen(),
                                    ),
        
        // --- NEW ADMIN DASHBOARD ROUTES ---
        '/admin/dashboard':           (_) => const AuthGuard(child: DashboardHomeScreen()),
        '/admin/dashboard/revenue':   (_) => const AuthGuard(child: DashboardRevenueScreen()),
        '/admin/dashboard/insights':  (_) => const AuthGuard(child: DashboardInsightsScreen()),
        '/admin/dashboard/notices':   (_) => const AuthGuard(child: DashboardNoticesScreen()),

        // --- NEW SOCIETY SETUP ROUTES ---
        '/admin/society-setup':       (_) => const AuthGuard(child: SocietySetupHomeScreen()),
        '/admin/society/profile':     (_) => const AuthGuard(child: SocietyProfileScreen()),
        '/admin/society/info':        (_) => const AuthGuard(child: SocietyInformationScreen()),
        '/admin/society/logo':        (_) => const AuthGuard(child: SocietyLogoScreen()),
        '/admin/society/wings':       (_) => const AuthGuard(child: WingsBlocksScreen()),
        '/admin/society/flats':       (_) => const AuthGuard(child: FlatsUnitsScreen()),

        // --- NEW REPORTS ROUTES ---
        '/admin/reports':             (_) => const AuthGuard(child: ReportsDashboardScreen()),
        '/admin/reports/financial':   (_) => const AuthGuard(child: FinancialReportScreen()),

        // --- NEW FINANCE ROUTES ---
        '/admin/finance':             (_) => const AuthGuard(child: FinanceDashboardScreen()),
        '/admin/finance/generate-bills': (_) => const AuthGuard(child: GenerateBillsScreen()),
        '/admin/finance/bill-details': (_) => const AuthGuard(child: BillDetailsScreen()),
        '/admin/finance/history':     (_) => const AuthGuard(child: PaymentHistoryScreen()),
        '/admin/finance/ledger':      (_) => const AuthGuard(child: FinancialLedgerScreen()),
        '/admin/finance/reports':     (_) => const AuthGuard(child: IncomeReportsScreen()),

        // --- NEW COMMUNICATION ROUTES ---
        '/admin/notices':             (_) => const AuthGuard(child: NoticesScreen()),
        '/admin/communication/create-notice': (_) => const AuthGuard(child: CreateNoticeScreen()),

        // --- NEW COMPLAINTS ROUTES ---
        '/admin/complaints':          (_) => const AuthGuard(child: ComplaintsDashboardScreen()),
        '/admin/complaints/details':  (_) => const AuthGuard(child: ComplaintDetailsScreen()),

        // --- NEW STAFF & AMENITIES ROUTES ---
        '/admin/staff':               (_) => const AuthGuard(child: StaffDashboardScreen()),
        '/admin/staff/list':          (_) => const AuthGuard(child: StaffListScreen()),
        '/admin/amenities':           (_) => const AuthGuard(child: AmenitiesDashboardScreen()),

        // --- NEW PARKING ROUTES ---
        '/admin/parking':             (_) => const AuthGuard(child: ParkingDashboardScreen()),
        '/admin/parking/allocation':  (_) => const AuthGuard(child: SlotAllocationScreen()),

        // --- NEW ASSET MANAGEMENT ROUTES ---
        '/admin/assets':              (_) => const AuthGuard(child: AssetsDashboardScreen()),
        '/admin/assets/details':      (_) => const AuthGuard(child: LiftDetailsScreen()),

        // --- AI INNOVATION ROUTES ---
        '/ai/pulse':                  (_) => const AuthGuard(
                                              allowedRoles: ['main_admin', 'admin', 'treasurer', 'secretary', 'committee_member', 'super_admin', 'superadmin'],
                                              child: AISocietyPulseScreen(),
                                            ),
        '/ai/complaint-intelligence': (_) => const AuthGuard(
                                              allowedRoles: ['main_admin', 'admin', 'secretary', 'committee_member', 'super_admin', 'superadmin'],
                                              child: ComplaintIntelligenceScreen(),
                                            ),
        '/ai/maintenance':            (_) => const AuthGuard(
                                              allowedRoles: ['main_admin', 'admin', 'committee_member', 'super_admin', 'superadmin'],
                                              child: PredictiveMaintenanceScreen(),
                                            ),
        '/ai/financial-anomaly':      (_) => const AuthGuard(
                                              allowedRoles: ['main_admin', 'admin', 'treasurer', 'super_admin', 'superadmin'],
                                              child: FinancialAnomalyScreen(),
                                            ),

        // --- COMMON ROUTES ---
        '/notifications':             (_) => const AuthGuard(child: NotificationsScreen()),
        '/profile':                   (_) => const AuthGuard(child: ProfileScreen()),
        '/profile/edit':              (_) => const AuthGuard(child: EditProfileScreen()),
        '/settings':                  (_) => const AuthGuard(child: SettingsScreen()),

        // --- STAFF/GUARD ROUTES (MR-007) ---
        // '/staff/gate' aliases the reworked guard_home gate console so any
        // existing deep link into the guard flow keeps working.
        '/staff/gate':                (_) => const AuthGuard(
                                              allowedRoles: ['guard', 'security_manager', 'facility_manager', 'supervisor', 'maintenance_staff', 'housekeeping_staff', 'reception_staff', 'parcel_desk_staff', 'staff'],
                                              child: GateScreen(),
                                            ),
        '/staff/tasks':               (_) => const AuthGuard(
                                              allowedRoles: ['guard', 'security_manager', 'facility_manager', 'supervisor', 'maintenance_staff', 'housekeeping_staff', 'reception_staff', 'parcel_desk_staff', 'staff'],
                                              child: StaffTasksScreen(),
                                            ),
        '/staff/assistant':           (_) => const AuthGuard(
                                              child: AiChatScreen(
                                                userRole: 'staff',
                                                initialMessage: 'How can I help with your shift today?',
                                              ),
                                            ),

        // --- RESIDENT ONBOARDING (MR-006) ---
        // Society search is a public endpoint, so no AuthGuard: a new user can
        // browse societies before registering. Submitting the join request and
        // checking status require a session.
        '/onboarding':                (_) => const SocietySearchScreen(),
        '/onboarding/status':         (_) => const AuthGuard(
                                              requireApproved: false,
                                              child: RequestStatusScreen(),
                                            ),

        // --- RESIDENT DEEP-LINK ROUTES (push notifications) ---
        '/resident/visitors':         (_) => const AuthGuard(child: VisitorApprovalScreen()),
        '/resident/invite-visitor':   (_) => const AuthGuard(child: InviteVisitorScreen()),
        '/resident/payments':         (_) => const AuthGuard(child: BillsDuesScreen()),
        '/resident/complaints':       (_) => const AuthGuard(child: ResidentIssuesScreen()),
        '/resident/amenities':        (_) => const AuthGuard(child: AmenitiesHomeScreen()),
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocietyApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: appTheme(),
      initialRoute: '/splash',
      routes: routes,
      // Safety net: any route that isn't registered renders a friendly
      // "coming soon" screen instead of crashing to a red error page.
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _ComingSoonScreen(routeName: settings.name ?? ''),
        settings: settings,
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String routeName;

  const _ComingSoonScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kSuperGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kSuperHeaderGradient),
        ),
        title: const Text('Coming Soon'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: kSuperGreenSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.rocket_launch_outlined,
                    color: kSuperGreen, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'This module is on the way',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                routeName.isEmpty
                    ? 'The screen you tried to open is not available yet.'
                    : 'The screen "$routeName" is not available yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(backgroundColor: kSuperGreen),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




