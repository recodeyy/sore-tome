import 'dart:convert';
import 'api_service.dart';
import 'sse_manager.dart';
import '../models/message_chunk.dart';

class AiService {
  final List<Map<String, dynamic>> _history = [];

  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// STREAMING: New high-performance SSE chat (V5.2)
  /// UI can listen to chunks and render word-by-word.
  Stream<MessageChunk> sendMessageStream(
    String userMessage, {
    String? base64Image,
    List<Map<String, dynamic>>? history,
    String? conversationId,
    String? language,
    String? requestId,
    List<String> attachmentTokens = const [],
    Map<String, dynamic>? context,
  }) async* {
    final managedHistory = history ?? List<Map<String, dynamic>>.from(_history);
    final usesExternalHistory = history != null;
    if (!usesExternalHistory) {
      _history.add({'role': 'user', 'content': userMessage});
    }

    String fullReply = "";
    String? finalType;
    Map<String, dynamic>? finalMetadata;

    // Send to SSE Manager
    final stream = SseManager.streamRequest('/ai/chat', {
      'message': userMessage,
      if (base64Image != null) 'base64Image': base64Image,
      if (conversationId != null) 'conversationId': conversationId,
      if (language != null) 'language': language,
      if (requestId != null) 'requestId': requestId,
      if (attachmentTokens.isNotEmpty) 'attachmentTokens': attachmentTokens,
      'context': context,
      'history': managedHistory,
    });

    await for (final chunk in stream) {
      if (!chunk.isComplete) {
        fullReply += chunk.text;
      } else {
        // Only take the final text if it's different/more complete
        if (chunk.text.length > fullReply.length) {
          fullReply = chunk.text;
        }
        finalType = chunk.type;
        finalMetadata = chunk.metadata;
      }

      yield chunk;
    }

    // On completion, persist only for legacy callers. Riverpod callers own state.
    if (!usesExternalHistory) {
      _history.add({
        'role': 'assistant',
        'content': fullReply,
        'type': finalType ?? 'text',
        ...?finalMetadata,
      });
    }
  }

  /// REST-only fallback (Legacy support)
  Future<Map<String, dynamic>> sendMessage(
    String userMessage, {
    String? base64Image,
    List<Map<String, dynamic>>? history,
    String? conversationId,
    String? language,
    String? requestId,
    List<String> attachmentTokens = const [],
    Map<String, dynamic>? context,
  }) async {
    final managedHistory = history ?? List<Map<String, dynamic>>.from(_history);
    final usesExternalHistory = history != null;
    if (!usesExternalHistory) {
      _history.add({'role': 'user', 'content': userMessage});
    }
    // ... (logic remains same for non-streaming context like images)
    try {
      final res = await ApiService.post('/ai/chat', {
        'message': userMessage,
        if (base64Image != null) 'base64Image': base64Image,
        if (conversationId != null) 'conversationId': conversationId,
        if (language != null) 'language': language,
        if (requestId != null) 'requestId': requestId,
        if (attachmentTokens.isNotEmpty) 'attachmentTokens': attachmentTokens,
        'context': context,
        'history': managedHistory,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = data['reply'] ??
            (data['type'] == 'draft'
                ? 'Draft generated'
                : 'No reply from server');
        if (!usesExternalHistory) {
          _history.add({
            'role': 'assistant',
            'content': reply,
            'type': data['type'] ?? 'text',
            ...data,
          });
        }
        return data;
      } else {
        final error = 'Server Error: ${res.body}';
        if (!usesExternalHistory) {
          _history.add({'role': 'assistant', 'content': error});
        }
        return {
          'type': 'system_unavailable',
          'reply': error,
          'requestId': requestId,
          'statusCode': res.statusCode,
        };
      }
    } catch (e) {
      final error = 'Connection Error: $e';
      if (!usesExternalHistory) {
        _history.add({'role': 'assistant', 'content': error});
      }
      return {
        'type': 'system_unavailable',
        'reply': error,
        'requestId': requestId,
      };
    }
  }

  Future<Map<String, dynamic>> executeAction(String actionId) async {
    try {
      final res = await ApiService.post('/ai/execute-tool', {
        'actionId': actionId,
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Action failed: ${res.body}');
      }
    } catch (e) {
      throw Exception('Execution Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getDigest() async {
    try {
      final res = await ApiService.get('/ai/digest');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  void clearHistory() => _history.clear();
}
