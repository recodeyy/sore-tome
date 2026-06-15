import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';
import '../screens/resident/home/resident_home_screen.dart';
import '../screens/resident/channels/resident_channels_screen.dart';
import '../screens/resident/issues/resident_issues_screen.dart';
import '../screens/shared/ai_chat/ai_chat_screen.dart';
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

    // 0-Home (Pulse/Security), 1-Hub (Social/Market), 2-Support (Service/Records), 3-AI (Assistant)
    final pages = [
      const ResidentHomeScreen(), 
      const ResidentChannelsScreen(),
      const ResidentIssuesScreen(),
      const AiChatScreen(
        userRole: 'resident',
        initialMessage: 'How can you help me today?',
      ),
    ];

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      NavItemData(icon: Icons.chat_outlined, activeIcon: Icons.chat_rounded, label: 'Hub'),
      NavItemData(icon: Icons.miscellaneous_services_outlined, activeIcon: Icons.miscellaneous_services_rounded, label: 'Support'),
      NavItemData(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'Assistant'),
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
