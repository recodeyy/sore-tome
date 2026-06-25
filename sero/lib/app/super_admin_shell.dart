import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/navigation_provider.dart';
import 'package:sero/screens/super_admin/super_admin_more_screen.dart';
import 'package:sero/screens/super_admin/super_admin_overview_screen.dart';
import 'package:sero/screens/super_admin/super_admin_revenue_screen.dart';
import 'package:sero/screens/super_admin/super_admin_societies_screen.dart';
import 'package:sero/screens/super_admin/super_admin_support_screen.dart';
import 'package:sero/widgets/super_admin/super_admin_bottom_nav.dart';
import 'package:sero/widgets/super_admin/super_admin_drawer.dart';

class SuperAdminShell extends ConsumerWidget {
  const SuperAdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(superAdminNavigationProvider);
    final pages = const [
      SuperAdminOverviewScreen(),
      SuperAdminSocietiesScreen(),
      SuperAdminRevenueScreen(),
      SuperAdminSupportScreen(),
      SuperAdminMoreScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      drawer: const SuperAdminDrawer(),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SuperAdminBottomNav(
        currentIndex: index,
        onTap: (value) => ref.read(superAdminNavigationProvider.notifier).state = value,
      ),
    );
  }
}
