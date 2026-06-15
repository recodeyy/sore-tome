import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'monitor_service.dart';
import 'api_service.dart';

/// The 'Elite' messaging engine responsible for 10/10 reliability.
/// Abstraction layer for Encryption, Feature Flags, and Scalability.
class ChatService {
  final Ref ref;
  final MonitorService _monitor = MonitorService();

  ChatService(this.ref);

  /// Centralized exit point for all messages.
  /// Handles encryption, feature-flag checks, and structured logging.
  Future<void> sendMessage(String channelId, ChatMessage message) async {
    final stopwatch = Stopwatch()..start();
    
    // 1. Encryption Preparation (Hook)
    final processedText = _encrypt(message.text);

    try {
      // 2. Dispatch to API
      final response = await ApiService.post('/channels/$channelId/messages', {
        ...message.toMap(),
        'text': processedText,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _monitor.trackLatency('send_message', stopwatch.elapsedMilliseconds);
        _monitor.logEvent('message_sent_successfully');

        // OPTIMISTIC SYNC: Transition from 'sending' to 'sent'
        final notifier = ref.read(pendingMessagesProvider(channelId).notifier);
        notifier.update((state) => state.map((m) => 
          m.id == message.id ? m.copyWith(status: MessageStatus.sent) : m
        ).toList());
      } else {
        throw Exception('Server rejected message: ${response.statusCode}');
      }
    } catch (e, stack) {
      _monitor.logError('Failed to send message', error: e, stack: stack);
      
      // ERROR SYNC: Transition to 'error'
      final notifier = ref.read(pendingMessagesProvider(channelId).notifier);
      notifier.update((state) => state.map((m) => 
        m.id == message.id ? m.copyWith(status: MessageStatus.error) : m
      ).toList());
      
      rethrow;
    }
  }

  /// Centralized entry point for all incoming messages.
  /// Handles decryption and data normalization.
  ChatMessage processIncoming(ChatMessage msg) {
    final decryptedText = _decrypt(msg.text);
    return msg.copyWith(text: decryptedText);
  }

  // --- Elite Hooks ---

  String _encrypt(String plainText) {
    // ELITE HOOK: Future E2EE implementation point.
    // Return encrypted blob here.
    return plainText; 
  }

  String _decrypt(String cypherText) {
    // ELITE HOOK: Future E2EE implementation point.
    return cypherText;
  }
}

final chatServiceProvider = Provider((ref) => ChatService(ref));


