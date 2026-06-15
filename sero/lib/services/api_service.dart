import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';
import 'package:sero/config/dev_config.dart';
import 'dart:convert';

class ApiService {
  static String get baseUrl => ApiClient.baseUrl;

  // ─── Token helpers (Bridge to AuthService) ────────────────────────────────
  static Future<String?> getToken() async => await AuthService.getToken();
  
  static Future<void> saveToken(String token) async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken != null) {
      await AuthService.saveTokens(token: token, refreshToken: refreshToken);
    }
  }
  static Future<void> clearToken() async => await AuthService.logout();

  // ─── API Methods (Delegated to ApiClient with Refresh Logic) ──────────────
  static Future<http.Response> get(String endpoint) async {
    if (kUseMockData) {
      return _getMockResponse(endpoint);
    }
    return ApiClient.request('GET', endpoint);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    if (kUseMockData) {
      return _getMockResponse(endpoint, body: body);
    }
    return ApiClient.request('POST', endpoint, body: body);
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    if (kUseMockData) return _getMockResponse(endpoint);
    return ApiClient.request('PUT', endpoint, body: body);
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    if (kUseMockData) return _getMockResponse(endpoint);
    return ApiClient.request('PATCH', endpoint, body: body);
  }

  static Future<http.Response> delete(String endpoint) async {
    if (kUseMockData) return _getMockResponse(endpoint);
    return ApiClient.request('DELETE', endpoint);
  }

  // ─── Mock Data Selector ───────────────────────────────────────────────────
  static http.Response _getMockResponse(String endpoint, {Map<String, dynamic>? body}) {
    // TODO: Connect to backend and remove mock selector
    String jsonStr = '{}';
    int status = 200;

    if (endpoint == '/users/me') {
      jsonStr = jsonEncode({
        'uid': 'id',
        'name': 'Name',
        'phone': 'Phone',
        'flatNumber': '',
        'blockName': '',
        'role': 'admin',
        'status': 'approved',
        'society_id': 'society-id',
      });
    } else if (endpoint == '/auth/login') {
      jsonStr = jsonEncode({
        'token': 'token',
        'refreshToken': 'refresh-token',
        'user': {
          'uid': 'id',
          'name': 'Admin',
          'phone': body?['phone'] ?? '',
          'role': 'main_admin',
          'status': 'approved',
        }
      });
    } else if (endpoint == '/auth/pending') {
      jsonStr = jsonEncode({'pending': []});
    } else if (endpoint == '/users') {
      jsonStr = jsonEncode({'users': []});
    } else if (endpoint == '/notices') {
      jsonStr = jsonEncode({'notices': []});
    } else if (endpoint == '/issues') {
      jsonStr = jsonEncode({'issues': []});
    } else if (endpoint == '/funds/summary') {
      jsonStr = jsonEncode({
        'totalCollected': 0,
        'totalSpent': 0,
        'outstandingDues': 0,
        'overdueCount': 0,
      });
    }

    return http.Response(jsonStr, status, headers: {'content-type': 'application/json'});
  }
}



