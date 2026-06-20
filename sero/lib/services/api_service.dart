import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';
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
    return ApiClient.request('GET', endpoint);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return ApiClient.request('POST', endpoint, body: body);
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    return ApiClient.request('PUT', endpoint, body: body);
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    return ApiClient.request('PATCH', endpoint, body: body);
  }

  static Future<http.Response> delete(String endpoint) async {
    return ApiClient.request('DELETE', endpoint);
  }

  // ─── Envelope helper (new Postgres backend: {success, data, meta}) ─────────
  /// Unwraps the standard `{ success, data, meta }` envelope returned by the
  /// new `/api/v1` Postgres-backed endpoints. Throws on non-2xx or
  /// `success == false`. Returns the raw `data` field (Map or List).
  static dynamic unwrap(http.Response res) {
    final dynamic decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
        if (decoded['success'] == true) return decoded['data'];
        throw Exception(decoded['error'] ?? decoded['message'] ?? 'Request failed');
      }
      // Endpoint not (yet) using the envelope — return body as-is.
      return decoded;
    }
    final msg = (decoded is Map)
        ? (decoded['error'] ?? decoded['message'])
        : null;
    throw Exception(msg ?? 'Request failed (${res.statusCode})');
  }
}



