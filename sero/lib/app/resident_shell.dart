import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';
import '../screens/resident/home/resident_home_screen.dart';
import '../screens/resident/channels/resident_channels_screen.dart';
import '../screens/resident/amenities/amenities_home_screen.dart';
import '../screens/resident/payments/bills_dues_screen.dart';
import '../screens/resident/profile/resident_profile_screen.dart';
import '../screens/resident/registration/registration_pending_screen.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class ResidentShell extends ConsumerStatefulWidget {
  const ResidentShell({super.key});

  @override
  ConsumerState<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends ConsumerState<ResidentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    
    // AUTH GATEKEEPER: Lock app until admin approval
    if (user?.status != 'approved') {
      return const RegistrationPendingScreen();
    }

    // Design bottom nav (resident mockups): Home / Community / Amenities / Payments / Profile
    final pages = [
      const ResidentHomeScreen(),
      const ResidentChannelsScreen(),
      const AmenitiesHomeScreen(),
      const BillsDuesScreen(),
      const ResidentProfileScreen(),
    ];

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      NavItemData(icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, label: 'Community'),
      NavItemData(icon: Icons.pool_outlined, activeIcon: Icons.pool_rounded, label: 'Amenities'),
      NavItemData(icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, label: 'Payments'),
      NavItemData(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
