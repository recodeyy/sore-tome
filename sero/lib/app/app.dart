import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';
import '../screens/shared/auth/login_screen.dart';
import '../screens/shared/auth/register_screen.dart';
import '../screens/resident/issues/post_issue_screen.dart';
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

class SocietyApp extends StatelessWidget {
  const SocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocietyApp',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash':            (_) => const SplashScreen(),
        '/login':             (_) => const LoginScreen(),
        '/register':          (_) => const RegisterScreen(),
        
        // --- PROTECTED ROUTES ---
        '/home':              (_) => const AuthGuard(child: MainShell()),
        '/admin':             (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'treasurer', 'secretary'],
                                      child: MainShell(),
                                    ),
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

        // --- COMMON ROUTES ---
        '/notifications':             (_) => const AuthGuard(child: NotificationsScreen()),
        '/profile':                   (_) => const AuthGuard(child: ProfileScreen()),
        '/profile/edit':              (_) => const AuthGuard(child: EditProfileScreen()),
        '/settings':                  (_) => const AuthGuard(child: SettingsScreen()),
      },
    );
  }
}





