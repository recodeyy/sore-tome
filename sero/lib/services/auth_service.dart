import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/env.dart';

// Use centralized environment config
final String kBaseUrl = Environment.apiBaseUrl.replaceAll('/api/v1', '');

class AuthService {
  static const _storage = FlutterSecureStorage();

  // ─── Register (resident) ──────────────────────────────────────────────────
  static Future<String> register({
    required String name,
    required String phone,
    required String password,
    required String flatNumber,
    required String societyId,
    String? blockName,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        'flatNumber': flatNumber,
        'society_id': societyId,
        'blockName': blockName ?? '',
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['message'];
    } else {
      throw data['error'] ?? 'Registration failed';
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'refreshToken', value: data['refreshToken']);
      await _storage.write(key: 'user', value: jsonEncode(data['user']));
      
      // AI V2.4: Sync FCM Token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await updateFcmToken(fcmToken);
        }
      } catch (e) {
        debugPrint('FCM Token sync failed: $e');
      }
      
      return data;
    } else if (response.statusCode == 403) {
      throw {'error': data['error'], 'status': data['status']};
    } else {
      throw data['error'] ?? 'Login failed';
    }
  }

  // AI V2.4: Update FCM Token on Backend
  static Future<void> updateFcmToken(String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$kBaseUrl/users/me'),
        headers: await authHeaders(),
        body: jsonEncode({'fcmToken': token}),
      );
      if (response.statusCode != 200) {
        debugPrint('Failed to update FCM token on server: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user');
  }

  // ─── Token helpers ────────────────────────────────────────────────────────
  static Future<String?> getToken() async => await _storage.read(key: 'token');
  static Future<String?> getRefreshToken() async => await _storage.read(key: 'refreshToken');

  static Future<void> saveTokens({required String token, required String refreshToken}) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  // ─── Saved user helper ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final userStr = await _storage.read(key: 'user');
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  // ─── Role helper ──────────────────────────────────────────────────────────
  static Future<String> getRole() async {
    final user = await getSavedUser();
    return user?['role'] ?? 'resident';
  }

  // ─── Is logged in ─────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ─── Auth header helper ───────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Get my notifications (Deprecated: use ApiClient for production) ──────
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$kBaseUrl/auth/notifications'),
      headers: await authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['notifications'];
    throw data['error'] ?? 'Failed to load notifications';
  }
}
