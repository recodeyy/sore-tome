import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';

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
  final notifier = ProfileNotifier();
  notifier._hydrate(ref.read(authProvider).value);
  ref.listen(authProvider, (_, next) => notifier._hydrate(next.value));
  return notifier;
});

class ProfileNotifier extends StateNotifier<AdminProfile> {
  ProfileNotifier()
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

  void updateProfile({String? name, String? email, String? phone}) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
    );
  }
}
