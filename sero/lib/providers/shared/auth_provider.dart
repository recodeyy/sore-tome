import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/services/auth_service.dart';
import 'package:sero/models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  List<dynamic> destinations = [];

  /// True when the active session token is UNSCOPED (no society selected) and
  /// the backend asked the user to pick a workspace. While true, society-scoped
  /// data screens MUST NOT be loaded — the AuthGuard routes to the selector.
  bool requiresWorkspaceSelection = false;

  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();

    final token = await ApiService.getToken();
    if (token != null) {
      try {
        final res = await ApiService.get('/users/me');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final user = UserModel.fromMap(data);
          // A restored token can be UNSCOPED (society_id == null) when the user
          // has >1 workspace and never completed selection. Such a token would
          // make every society-scoped screen silently render zeros/blanks.
          // There is no read-only "list my workspaces" endpoint, so the safe
          // recovery is to drop the unscoped session and force a fresh login,
          // which repopulates `destinations` and routes to the selector.
          if (user.societyId.isEmpty && _isSocietyScopedRole(user.role)) {
            await ApiService.clearToken();
            requiresWorkspaceSelection = false;
            state = const AsyncValue.data(null);
            return;
          }
          // Restored backend session: re-establish the Firebase Auth session so
          // Firestore-backed screens keep working after an app restart. The JWT
          // is valid but the Firebase SDK session may have lapsed; re-issue a
          // fresh custom token from /auth/firebase-token and sign in with it.
          await _reauthFirebase();
          state = AsyncValue.data(user);
        } else {
          await ApiService.clearToken();
          state = const AsyncValue.data(null);
        }
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Re-issues a Firebase custom token for the active backend session and signs
  /// the Firestore SDK back in. Best-effort: failures are swallowed so a
  /// Firebase hiccup never blocks app startup.
  Future<void> _reauthFirebase() async {
    try {
      final res = await ApiService.get('/auth/firebase-token');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await AuthService.signInToFirebase(data['firebaseToken'] ?? data['data']?['firebaseToken']);
      }
    } catch (_) {/* non-fatal */}
  }

  /// Roles whose screens require a society-scoped token. Platform/super-admin
  /// roles operate cross-society and are exempt from workspace selection.
  static bool _isSocietyScopedRole(String role) {
    const platform = {
      'super_admin', 'superadmin', 'platform_owner',
      'platform_operations', 'platform_support', 'platform_security',
    };
    return !platform.contains(role.toLowerCase());
  }

  Future<bool> login(String phone, String password, {String? portal}) async {
    state = const AsyncValue.loading();

    try {
      final res = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
        if (portal != null) 'portal': portal,
      });
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = body['data'] ?? body;
        
        await AuthService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'] ?? '',
        );
        // Establish the Firebase Auth session so Firestore-backed screens work.
        await AuthService.signInToFirebase(data['firebaseToken']);

        final requiresSelect = data['requiresWorkspaceSelection'] ?? false;
        if (requiresSelect) {
          destinations = data['destinations'] ?? [];
          requiresWorkspaceSelection = true;
          state = const AsyncValue.data(null);
          return true;
        }

        requiresWorkspaceSelection = false;
        state = AsyncValue.data(UserModel.fromMap(data['user']));
        return false;

      } else if (res.statusCode == 403) {
        final errDetails = body['error'] ?? body;
        if (errDetails is Map && errDetails['code'] == 'PORTAL_MISMATCH') {
          throw errDetails['message'] ?? 'Portal mismatch';
        }
        final status = body['status'] ?? 'pending';
        final msg = status == 'rejected'
            ? 'Your registration was rejected by the admin.'
            : 'Your account is pending admin approval.';
        throw msg;
      } else {
        final errDetails = body['error'] ?? body;
        throw (errDetails is Map ? errDetails['message'] : errDetails) ?? 'Login failed';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Google sign-in / sign-up. Returns true if workspace selection is required,
  /// false if a session was established. Returns null if the user cancelled the
  /// Google account picker.
  Future<bool?> loginWithGoogle({String? portal}) async {
    final String? idToken;
    try {
      idToken = await AuthService.signInWithGoogle();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
    if (idToken == null) return null; // cancelled — leave state unchanged

    state = const AsyncValue.loading();
    try {
      final res = await ApiService.post('/auth/firebase', {
        'idToken': idToken,
        if (portal != null) 'portal': portal,
      });
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = body['data'] ?? body;
        await AuthService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'] ?? '',
        );
        await AuthService.signInToFirebase(data['firebaseToken']);

        final requiresSelect = data['requiresWorkspaceSelection'] ?? false;
        if (requiresSelect) {
          destinations = data['destinations'] ?? [];
          requiresWorkspaceSelection = true;
          state = const AsyncValue.data(null);
          return true;
        }

        requiresWorkspaceSelection = false;
        state = AsyncValue.data(UserModel.fromMap(data['user']));
        return false;
      } else if (res.statusCode == 403) {
        final errDetails = body['error'] ?? body;
        if (errDetails is Map && errDetails['code'] == 'PORTAL_MISMATCH') {
          throw errDetails['message'] ?? 'Portal mismatch';
        }
        final status = body['status'] ?? 'pending';
        throw status == 'rejected'
            ? 'Your registration was rejected by the admin.'
            : 'Your account is pending admin approval.';
      } else {
        final errDetails = body['error'] ?? body;
        throw (errDetails is Map ? errDetails['message'] : errDetails) ?? 'Google sign-in failed';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> selectWorkspace(Map<String, dynamic> destination) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.post('/auth/workspace/select', {
        'workspaceId': destination['workspaceId'],
      });
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = body['data'] ?? body;
        await AuthService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'] ?? '',
        );
        // Re-establish Firebase with the now society-scoped custom token so
        // Firestore reads carry the correct society_id claim.
        await AuthService.signInToFirebase(data['firebaseToken']);

        // Selection succeeded: the token is now society-scoped.
        requiresWorkspaceSelection = false;
        destinations = [];

        // Fetch the fresh workspace-scoped user profile
        final meRes = await ApiService.get('/users/me');
        if (meRes.statusCode == 200) {
          final meData = jsonDecode(meRes.body);
          state = AsyncValue.data(UserModel.fromMap(meData));
        } else {
          throw 'Failed to fetch workspace user profile';
        }
      } else {
        final errDetails = body['error'] ?? body;
        throw (errDetails is Map ? errDetails['message'] : errDetails) ?? 'Workspace selection failed';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Re-fetch the authenticated user from /users/me and update state so the
  /// dashboard greeting, drawer header, etc. reflect profile edits immediately.
  Future<void> refreshUser() async {
    try {
      final res = await ApiService.get('/users/me');
      if (res.statusCode == 200) {
        state = AsyncValue.data(UserModel.fromMap(jsonDecode(res.body)));
      }
    } catch (_) {/* keep current state on failure */}
  }

  /// Optimistically patch the in-memory user (e.g. after a profile name save)
  /// so the UI updates instantly, without waiting for a network round-trip.
  void applyLocalUser({String? name, String? photoUrl}) {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncValue.data(UserModel(
      id: cur.id,
      name: name ?? cur.name,
      phone: cur.phone,
      flatNumber: cur.flatNumber,
      block: cur.block,
      role: cur.role,
      status: cur.status,
      societyId: cur.societyId,
      residentType: cur.residentType,
      maintenanceExempt: cur.maintenanceExempt,
      photoUrl: photoUrl ?? cur.photoUrl,
    ));
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    await AuthService.signOutGoogle();
    destinations = [];
    requiresWorkspaceSelection = false;
    state = const AsyncValue.data(null);
  }
}
