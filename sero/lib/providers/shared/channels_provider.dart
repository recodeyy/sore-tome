import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:sero/services/api_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'presence_provider.dart';

enum MessageStatus { sending, sent, delivered, error }

class Channel {
  final String id;
  final String name;
  final String description;
  final bool isReadOnly;
  final List<String> allowedRoles;
  final List<String> moderatorIds;
  final String? smartType; 
  final Map<String, dynamic>? quietHours; 
  final bool vaultEnabled;

  Channel({
    required this.id,
    required this.name,
    required this.description,
    this.isReadOnly = false,
    this.allowedRoles = const ["resident", "admin"],
    this.moderatorIds = const [],
    this.smartType,
    this.quietHours,
    this.vaultEnabled = false,
  });

  factory Channel.fromMap(Map<String, dynamic> map, String id) {
    return Channel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isReadOnly: map['isReadOnly'] ?? false,
      allowedRoles: List<String>.from(map['allowedRoles'] ?? ["resident", "admin"]),
      moderatorIds: List<String>.from(map['moderatorIds'] ?? []),
      smartType: map['smartType'],
      quietHours: map['quietHours'],
      vaultEnabled: map['vaultEnabled'] ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final String? clientId; // UUID for deduplication
  final String text;
  final String senderId;
  final String senderName;
  final String senderFlat;
  final DateTime createdAt;
  final bool isOfficial;
  final bool isSystemMessage;
  final bool isDeleted;
  final List<String> readBy;
  final List<String> deliveredBy; // 3-stage lifecycle
  final int deliveredCount;
  final String? mediaUrl;
  final String? mediaType; 
  final String? fileName;
  final String? smartType; 
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final bool isEdited;
  final double uploadProgress;

  ChatMessage({
    required this.id,
    this.clientId,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderFlat,
    required this.createdAt,
    this.isOfficial = false,
    this.isSystemMessage = false,
    this.isDeleted = false,
    this.readBy = const [],
    this.deliveredBy = const [],
    this.deliveredCount = 0,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.smartType,
    this.metadata,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.uploadProgress = 1.0,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    MessageStatus status = MessageStatus.sent;
    final dbStatus = map['status'] as String?;
    
    if (dbStatus == 'uploading') {
      status = MessageStatus.sending;
    } else if (dbStatus == 'failed') {
      status = MessageStatus.error;
    } else if ((map['deliveredCount'] ?? 0) > 0) {
      status = MessageStatus.delivered;
    }

    return ChatMessage(
      id: id,
      clientId: map['clientId'],
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderFlat: map['senderFlat'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOfficial: map['isOfficial'] ?? false,
      isSystemMessage: map['isSystemMessage'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      deliveredBy: List<String>.from(map['deliveredBy'] ?? []),
      deliveredCount: map['deliveredCount'] ?? 0,
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'],
      fileName: map['fileName'],
      smartType: map['smartType'],
      metadata: map['metadata'],
      isEdited: map['isEdited'] ?? false,
      uploadProgress: (map['uploadProgress']?.toDouble()) ?? 1.0,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (clientId != null) 'clientId': clientId,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'senderFlat': senderFlat,
      'isOfficial': isOfficial,
      'isSystemMessage': isSystemMessage,
      'isDeleted': isDeleted,
      'readBy': readBy,
      'deliveredBy': deliveredBy,
      'deliveredCount': deliveredCount,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      if (fileName != null) 'fileName': fileName,
      if (smartType != null) 'smartType': smartType,
      if (metadata != null) 'metadata': metadata,
      'isEdited': isEdited,
      'uploadProgress': uploadProgress,
    };
  }

  ChatMessage copyWith({
    MessageStatus? status,
    String? id,
    String? text,
    List<String>? deliveredBy,
    int? deliveredCount,
    List<String>? readBy,
    bool? isEdited,
    double? uploadProgress,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      clientId: clientId,
      text: text ?? this.text,
      senderId: senderId,
      senderName: senderName,
      senderFlat: senderFlat,
      createdAt: createdAt,
      isOfficial: isOfficial,
      isSystemMessage: isSystemMessage,
      isDeleted: isDeleted,
      readBy: readBy ?? this.readBy,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      fileName: fileName,
      smartType: smartType,
      isEdited: isEdited ?? this.isEdited,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ✅ BUG-18 FIX: Filter channels by society_id using the logged-in user's societyId.
// Previously this fetched ALL channels across ALL societies, relying solely on Firestore
// Security Rules as the only defense. Defense-in-depth requires the query to be scoped.
final channelsListProvider = StreamProvider.autoDispose<List<Channel>>((ref) {
  final user = ref.watch(authProvider).value;
  final societyId = user?.societyId;

  // If user is not logged in or society not resolved yet, return empty stream
  if (societyId == null || societyId.isEmpty) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('channels')
      .where('society_id', isEqualTo: societyId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Channel.fromMap(doc.data(), doc.id)).toList());
});

// Memory buffer for optimistic UI
final pendingMessagesProvider = StateProvider.family<List<ChatMessage>, String>((ref, channelId) => []);

final channelMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, channelId) {
  return FirebaseFirestore.instance
      .collection('channels')
      .doc(channelId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50) // Default initial load
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList());
});

// Cursor-based Pagination State
final messageLimitProvider = StateProvider.family<int, String>((ref, channelId) => 50);

final typingUsersProvider = Provider.family<List<String>, String>((ref, channelId) {
  final presenceAsync = ref.watch(presenceProvider(channelId).select((p) => p));
  return presenceAsync.maybeWhen(
    data: (presence) => presence.where((p) => p.isTyping).map((p) => p.name).toList(),
    orElse: () => [], 
  );
});

final paginatedMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, channelId) {
  final limit = ref.watch(messageLimitProvider(channelId));
  
  return FirebaseFirestore.instance
      .collection('channels')
      .doc(channelId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList());
});

// The Unified Hub - Merges DB data and Memory data for 0ms feel
final mergedMessagesProvider = Provider.family<AsyncValue<List<ChatMessage>>, String>((ref, channelId) {
  final stream = ref.watch(paginatedMessagesProvider(channelId));
  final pending = ref.watch(pendingMessagesProvider(channelId));

  return stream.when(
    data: (dbMessages) {
      final confirmedClientIds = dbMessages.where((m) => m.clientId != null).map((m) => m.clientId!).toSet();
      final confirmedHashes = dbMessages.where((m) => m.clientId == null).map((m) => "${m.text}_${m.createdAt.minute}").toSet();

      final uniquePending = pending.where((p) {
        if (p.clientId != null) return !confirmedClientIds.contains(p.clientId);
        return !confirmedHashes.contains("${p.text}_${p.createdAt.minute}");
      }).toList();
      
      return AsyncValue.data([...uniquePending, ...dbMessages]);
    },
    // CRITICAL: Always show pending messages even if the main stream is loading or has an error
    loading: () => AsyncValue.data(pending),
    error: (err, stack) => AsyncValue.data(pending),
  );
});

final briefingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiService.get('/channels/admin/briefing');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {"summary": "Briefing unavailable", "insights": []};
  } catch (e) {
    return {
      "summary": "Briefing temporarily down.",
      "insights": ["Check connection", "Retry later"]
    };
  }
});



