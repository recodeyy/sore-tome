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
          state = AsyncValue.data(UserModel.fromMap(data));
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

        final requiresSelect = data['requiresWorkspaceSelection'] ?? false;
        if (requiresSelect) {
          destinations = data['destinations'] ?? [];
          state = const AsyncValue.data(null);
          return true;
        }

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

        final requiresSelect = data['requiresWorkspaceSelection'] ?? false;
        if (requiresSelect) {
          destinations = data['destinations'] ?? [];
          state = const AsyncValue.data(null);
          return true;
        }

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

  Future<void> logout() async {
    await ApiService.clearToken();
    await AuthService.signOutGoogle();
    destinations = [];
    state = const AsyncValue.data(null);
  }
}
