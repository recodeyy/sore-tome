import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/services/auth_service.dart';
import 'package:sero/models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
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

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // ✅ BUG-03 FIX: Save both access AND refresh tokens on login
        await AuthService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'] ?? '',
        );
        state = AsyncValue.data(UserModel.fromMap(data['user']));

      } else if (res.statusCode == 403) {
        // ✅ BUG-20 FIX: Distinguish 403 (pending/rejected) from 401 (wrong credentials)
        final status = data['status'] ?? 'pending';
        final msg = status == 'rejected'
            ? 'Your registration was rejected by the admin.'
            : 'Your account is pending admin approval.';
        throw msg;
      } else {
        throw data['error'] ?? 'Login failed';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.delete('/users/me');
      if (res.statusCode == 200) {
        await ApiService.clearToken();
        state = const AsyncValue.data(null);
      } else {
        final data = jsonDecode(res.body);
        throw data['error'] ?? 'Failed to delete account';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}



