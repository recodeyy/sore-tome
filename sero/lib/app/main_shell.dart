import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'admin_shell.dart';
import 'resident_shell.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final role = user?.role ?? 'resident';

    // Dispatcher: Redirect based on high-level role
    if (role == 'resident') {
      return const ResidentShell();
    } else {
      // main_admin, treasurer, secretary
      return const AdminShell();
    }
  }
}



