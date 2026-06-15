import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import '../../screens/shared/auth/login_screen.dart';
import '../../screens/shared/auth/pending_approval_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final List<String>? allowedRoles;
  final bool requireApproved;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requireApproved = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          // Force login if no user
          return const LoginScreen();
        }

        // Check if approval is required and user is still pending
        if (requireApproved && user.status == 'pending') {
          return const PendingApprovalScreen();
        }

        // Role-based check
        if (allowedRoles != null && !allowedRoles!.contains(user.role)) {
          return const _AccessDeniedView();
        }

        return child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Auth Error: $e')),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You do not have permission to view this screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



