import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/services/auth_service.dart';
import 'package:sero/models/user.dart';
import 'package:sero/config/dev_config.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    
    if (kUseMockData) {
      // In mock mode, we assume user is already logged in if there's a token
      final token = await ApiService.getToken();
      if (token != null) {
        state = AsyncValue.data(UserModel(
          id: 'mock-admin-id',
          name: 'Demo Admin',
          phone: '+919876543210',
          flatNumber: 'A-101',
          block: 'Block A',
          role: 'main_admin',
          status: 'approved',
          societyId: 'mock-society-id',
        ));
        return;
      }
      state = const AsyncValue.data(null);
      return;
    }

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

    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate delay
      
      final mockUser = UserModel(
        id: 'mock-admin-id',
        name: 'Demo Admin',
        phone: phone,
        flatNumber: 'A-101',
        block: 'Block A',
        role: 'main_admin',
        status: 'approved',
        societyId: 'mock-society-id',
      );
      
      await AuthService.saveTokens(token: 'mock-token', refreshToken: 'mock-refresh-token');
      state = AsyncValue.data(mockUser);
      return;
    }

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
}



