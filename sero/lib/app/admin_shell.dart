import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/common/sero_bottom_nav.dart';
import '../screens/admin/dashboard/dashboard_home_screen.dart';
import '../screens/admin/society/society_setup_home_screen.dart';
import '../screens/admin/main/admin_users_screen.dart';
import '../screens/admin/complaints/complaints_dashboard_screen.dart';
import '../screens/admin/finance/finance_dashboard_screen.dart';

import '../screens/admin/admin_more_screen.dart';
import '../widgets/shared/admin_drawer.dart';

import 'package:sero/providers/shared/navigation_provider.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  Widget build(BuildContext context) {
    final index = ref.watch(adminNavigationProvider);
    
    // The current admin pages based on the 5-tab navigation
    // 0: Dashboard, 1: Members, 2: Finance, 3: Complaints, 4: More
    final List<Widget> pages = [
      const DashboardHomeScreen(),       // Tab 0: Dashboard
      const AdminUsersScreen(),          // Tab 1: Members
      const FinanceDashboardScreen(),    // Tab 2: Finance (G Button)
      const ComplaintsDashboardScreen(), // Tab 3: Complaints
      const AdminMoreScreen(),           // Tab 4: More
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: SeroBottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(adminNavigationProvider.notifier).state = i,
      ),
    );
  }
}






