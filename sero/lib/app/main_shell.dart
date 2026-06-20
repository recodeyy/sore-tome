import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/core/permissions/role_utils.dart';
import 'admin_shell.dart';
import 'resident_shell.dart';
import 'super_admin_shell.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final role = RoleUtils.normalize(user?.role ?? 'resident');

    if (RoleUtils.isSuperAdmin(role)) {
      return const SuperAdminShell();
    }

    if (RoleUtils.isResident(role)) {
      return const ResidentShell();
    } else {
      return const AdminShell();
    }
  }
}


