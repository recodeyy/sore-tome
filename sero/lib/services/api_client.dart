import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

class ApiClient {
  static const String baseUrl = Environment.apiBaseUrl;
  static Future<bool>? _refreshFuture;

  /// Unified Header Generator (V5.2)
  static Future<Map<String, String>> getHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Main Request Bridge
  static Future<http.Response> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _executeRequest(method, url, headers, body);

      if (response.statusCode == 401 && requiresAuth) {
        final success = await _handleRefresh();
        if (success) {
          final newHeaders = await getHeaders(requiresAuth: true);
          return await _executeRequest(method, url, newHeaders, body);
        }
      }

      // V5.2: Unified Error Logger
      if (response.statusCode >= 400) {
        debugPrint(
          'API Error [$endpoint]: ${response.statusCode} - ${response.body}',
        );
      }

      return response;
    } catch (e) {
      debugPrint('Network Error [$endpoint]: $e');
      rethrow;
    }
  }

  static Future<http.Response> _executeRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      case 'DELETE':
        return await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
      case 'PATCH':
        return await http.patch(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      default:
        throw Exception('Method $method not supported');
    }
  }

  /// Multipart File Upload
  static Future<http.StreamedResponse> upload(
    String endpoint,
    String fieldName,
    Uint8List fileBytes,
    String fileName, {
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    final token = await AuthService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: fileName,
    ));

    return await request.send();
  }

  static Future<bool> _handleRefresh() async {
    if (_refreshFuture != null) return await _refreshFuture!;
    _refreshFuture = _performRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  static Future<bool> _performRefresh() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (_) {}

    await AuthService.logout();
    return false;
  }
}
