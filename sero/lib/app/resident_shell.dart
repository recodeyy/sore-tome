import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';
import 'package:sero/widgets/resident/resident_drawer.dart';
import '../screens/resident/home/resident_home_screen.dart';
import '../screens/resident/channels/resident_channels_screen.dart';
import '../screens/resident/payments/bills_dues_screen.dart';
import '../screens/resident/visitors/visitor_approval_screen.dart';
import '../screens/resident/more/resident_more_screen.dart';
import '../screens/resident/onboarding/request_status_screen.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class ResidentShell extends ConsumerStatefulWidget {
  const ResidentShell({super.key});

  @override
  ConsumerState<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends ConsumerState<ResidentShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    // AUTH GATEKEEPER (MR-006): residents without an active membership
    // (no society yet, or account still pending approval) land in the
    // onboarding/status flow instead of a dead-end waiting screen.
    if (user == null || user.societyId.isEmpty || user.status != 'approved') {
      return const RequestStatusScreen();
    }

    // MR-012 resident nav: Home / Community / Pay (raised center) / Visitors / More.
    // Amenities and Profile moved under the More tab.
    final pages = [
      ResidentHomeScreen(onMenuTap: _openMenu),
      const ResidentChannelsScreen(),
      const BillsDuesScreen(),
      const VisitorApprovalScreen(),
      const ResidentMoreScreen(),
    ];

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      NavItemData(icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, label: 'Community'),
      NavItemData(icon: Icons.currency_rupee_rounded, activeIcon: Icons.currency_rupee_rounded, label: 'Pay'),
      NavItemData(icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt_rounded, label: 'Visitors'),
      NavItemData(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More'),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // extendBody:false so page content is laid out ABOVE the bottom menu
      // (the floating pill previously overlapped every screen's content).
      extendBody: false,
      backgroundColor: Colors.white,
      drawer: const ResidentDrawer(),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        centerIndex: 2, // Pay — raised prominent center action
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
