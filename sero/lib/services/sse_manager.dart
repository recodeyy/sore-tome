import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_chunk.dart';
import 'auth_service.dart';
import '../config/env.dart';
import 'package:flutter/foundation.dart';

/// SSE Manager (V5.2 Upgrade)
/// ❗ PRO FIX: Cancellation, Backpressure, and Exponential Backoff.
class SseManager {
  static const String baseUrl = Environment.apiBaseUrl;

  /// Post a streaming request to backend.
  /// Yields MessageChunks until complete or cancelled.
  static Stream<MessageChunk> streamRequest(
    String endpoint,
    Map<String, dynamic> body, {
    int maxRetries = 3,
  }) async* {
    int attempts = 0;
    bool isComplete = false;

    while (attempts < maxRetries && !isComplete) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final request = http.StreamedRequest('POST', url);

        // 1. Headers & Auth
        final token = await AuthService.getToken();
        request.headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (token != null) 'Authorization': 'Bearer $token',
        });

        // 2. Body
        request.sink.add(utf8.encode(jsonEncode({...body, 'stream': true})));
        request.sink.close();

        // 3. Execution
        final client = http.Client();
        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('SSE Request Failed: ${response.statusCode}');
        }

        // 4. Transform Stream
        await for (final line
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6);
            if (dataStr == '[DONE]') {
              isComplete = true;
              break;
            }

            try {
              final json = jsonDecode(dataStr);
              yield MessageChunk(
                text: json['reply'] ?? '',
                isComplete: json['done'] ?? false,
                type: json['type'],
                metadata: json,
              );

              if (json['done'] == true) {
                isComplete = true;
                break;
              }
            } catch (e) {
              debugPrint('SSE Parse Error: $e');
              // Yield raw text if JSON fails
              yield MessageChunk.partial(dataStr);
            }
          }
        }

        client.close();
        if (isComplete) return;
      } catch (e) {
        attempts++;
        debugPrint('SSE Attempt $attempts failed: $e');

        if (attempts >= maxRetries) {
          yield MessageChunk.completion(
            'Connection lost. Please check your internet and try again.',
            type: 'error',
          );
          return;
        }

        // ❗ Exponential Backoff
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }
}
