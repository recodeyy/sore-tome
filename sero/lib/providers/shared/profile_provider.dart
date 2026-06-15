import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AdminProfile> {
  ProfileNotifier()
      : super(AdminProfile(
          // TODO: Fetch profile from backend
          name: 'Name',
          email: 'Email',
          phone: 'Phone',
          role: 'Role',
          society: 'Society',
        ));

  void updateProfile({String? name, String? email, String? phone}) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
    );
  }
}
