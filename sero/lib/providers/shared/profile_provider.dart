import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/api_service.dart';

class AdminProfile {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String society;
  final String? profilePicture;

  AdminProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.society,
    this.profilePicture,
  });

  AdminProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? society,
    String? profilePicture,
  }) {
    return AdminProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      society: society ?? this.society,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AdminProfile>((ref) {
  // Hydrate from the authenticated user (/users/me) and keep in sync.
  final notifier = ProfileNotifier(ref);
  notifier._hydrate(ref.read(authProvider).value);
  ref.listen(authProvider, (_, next) => notifier._hydrate(next.value));
  return notifier;
});

class ProfileNotifier extends StateNotifier<AdminProfile> {
  final Ref _ref;
  ProfileNotifier(this._ref)
      : super(AdminProfile(
          name: '',
          email: '',
          phone: '',
          role: '',
          society: '',
        ));

  /// Populate from the live authenticated user model.
  void _hydrate(dynamic user) {
    if (user == null) return;
    state = AdminProfile(
      name: user.name ?? '',
      email: state.email,
      phone: user.phone ?? '',
      role: user.role ?? '',
      society: user.societyId ?? '',
      profilePicture: user.photoUrl,
    );
  }

  /// Persist editable profile fields to the backend (PATCH /users/me), update
  /// local state, and refresh the auth user so the dashboard greeting + drawer
  /// reflect the new name immediately.
  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    // Optimistic local update for instant UI feedback.
    state = state.copyWith(name: name, email: email, phone: phone);
    if (name != null && name.trim().isNotEmpty) {
      _ref.read(authProvider.notifier).applyLocalUser(name: name.trim());
    }
    try {
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (email != null) body['email'] = email.trim();
      if (body.isNotEmpty) {
        await ApiService.patch('/users/me', body);
        // Re-sync from the server so any normalisation is reflected.
        await _ref.read(authProvider.notifier).refreshUser();
      }
    } catch (_) {/* optimistic state already applied */}
  }
}
