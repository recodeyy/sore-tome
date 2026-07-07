import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/screens/guard/gate_screen.dart';
import 'package:sero/screens/guard/guard_home.dart';
import 'package:sero/screens/guard/staff_home_screen.dart';
import 'package:sero/screens/guard/staff_more_screen.dart';
import 'package:sero/screens/guard/staff_tasks_screen.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';

/// Staff/Guard operational shell (MR-007): Home, Gate, Tasks, Security, More.
class StaffShell extends ConsumerStatefulWidget {
  const StaffShell({super.key});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      StaffHomeScreen(onGoToTab: _goToTab),
      const GateScreen(),
      const StaffTasksScreen(),
      // Security tab keeps the original guard dashboard (visitors + staff feed).
      const GuardHome(),
      const StaffMoreScreen(),
    ];

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      NavItemData(icon: Icons.door_sliding_outlined, activeIcon: Icons.door_sliding_rounded, label: 'Gate'),
      NavItemData(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Tasks'),
      NavItemData(icon: Icons.security_outlined, activeIcon: Icons.security_rounded, label: 'Security'),
      NavItemData(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More'),
    ];

    return Scaffold(
      extendBody: false,
      backgroundColor: Colors.white,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        onTap: _goToTab,
      ),
    );
  }
}
