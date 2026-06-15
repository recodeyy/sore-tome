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
    Map<String, dynamic>? context,
  }) async* {
    _history.add({'role': 'user', 'content': userMessage});

    String fullReply = "";
    String? finalType;
    Map<String, dynamic>? finalMetadata;

    // Send to SSE Manager
    final stream = SseManager.streamRequest('/ai/chat', {
      'message': userMessage,
      'base64Image': base64Image,
      'context': context,
      'history': _history.sublist(0, _history.length - 1),
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

    // On completion, persist to history
    _history.add({
      'role': 'assistant',
      'content': fullReply,
      'type': finalType ?? 'text',
      ...?finalMetadata,
    });
  }

  /// REST-only fallback (Legacy support)
  Future<Map<String, dynamic>> sendMessage(
    String userMessage, {
    String? base64Image,
    Map<String, dynamic>? context,
  }) async {
    _history.add({'role': 'user', 'content': userMessage});
    // ... (logic remains same for non-streaming context like images)
    try {
      final res = await ApiService.post('/ai/chat', {
        'message': userMessage,
        'base64Image': base64Image,
        'context': context,
        'history': _history.sublist(0, _history.length - 1),
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply =
            data['reply'] ??
            (data['type'] == 'draft'
                ? 'Draft generated'
                : 'No reply from server');
        _history.add({
          'role': 'assistant',
          'content': reply,
          'type': data['type'] ?? 'text',
          ...data,
        });
        return data;
      } else {
        final error = 'Server Error: ${res.body}';
        _history.add({'role': 'assistant', 'content': error});
        return {'type': 'text', 'reply': error};
      }
    } catch (e) {
      final error = 'Connection Error: $e';
      _history.add({'role': 'assistant', 'content': error});
      return {'type': 'text', 'reply': error};
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
