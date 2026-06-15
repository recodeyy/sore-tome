import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:sero/providers/shared/channels_provider.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/presence_provider.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/services/chat_service.dart';
import 'channel_settings_screen.dart';
import 'channel_vault_screen.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/channel_chat_input_bar.dart';
import 'widgets/smart_intent_banner.dart';
import 'widgets/official_notice_bar.dart';
import 'widgets/typing_indicator.dart';

class ChannelChatScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const ChannelChatScreen({super.key, required this.channel});

  @override
  ConsumerState<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends ConsumerState<ChannelChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _msgFocus = FocusNode();
  bool _isUploading = false;
  String? _suggestedIntent; // "ticket" or null
  Timer? _heartbeatTimer;
  Timer? _typingTimer;
  bool _isTyping = false;
  final Map<String, String> _localFilePaths = {}; // Cache paths for retry

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
       _markAsRead();
       _startHeartbeat();
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        final currentLimit = ref.read(messageLimitProvider(widget.channel.id));
        ref.read(messageLimitProvider(widget.channel.id).notifier).state = currentLimit + 50;
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _msgFocus.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    try {
      await ApiService.post('/channels/${widget.channel.id}/read', {});
    } catch (_) {}
  }

  void _onTextChanged(String val) {
    if (!_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), () {
      _isTyping = false;
      _sendTypingStatus(false);
    });

    final lowercase = val.toLowerCase();
    final ticketKeywords = ["broken", "leak", "lift", "maintenance", "noise", "water"];
    bool matched = false;
    for (var k in ticketKeywords) {
      if (lowercase.contains(k)) matched = true;
    }
    
    if (matched != (_suggestedIntent != null)) {
       setState(() => _suggestedIntent = matched ? "ticket" : null);
    }
  }

  Future<void> _sendTypingStatus(bool isTyping) async {
    try {
       await ApiService.post('/channels/${widget.channel.id}/typing', {'isTyping': isTyping});
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _sendTypingStatus(_isTyping);
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    setState(() => _isUploading = true);
    
    final user = ref.read(authProvider).value;
    final clientId = const Uuid().v4();

    String? messageId;
    try {
      final response = await ApiService.post('/channels/${widget.channel.id}/messages', {
        'text': 'Sharing media...',
        'clientId': clientId,
        'senderName': user?.name ?? "Unknown",
        'senderFlat': user?.flatNumber ?? "",
        'status': 'uploading'
      });
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to create message: ${response.body}");
      }
      
      final data = jsonDecode(response.body);
      messageId = data['id'];
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize upload: $e')));
      setState(() => _isUploading = false);
      return;
    }

    try {
      if (image.path.isNotEmpty) {
        _localFilePaths[messageId!] = image.path;
      }
      
      final token = await ApiService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/channels/${widget.channel.id}/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['messageId'] = messageId!;
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      final response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Upload failed with status ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _joinDeal(String msgId) async {
    try {
       await ApiService.post('/channels/${widget.channel.id}/messages/$msgId/join-deal', {});
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You joined the deal!")));
    } catch (_) {}
  }

  void _showActionMenu(ChatMessage msg, bool isAdmin, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            if (isAdmin && !msg.isOfficial && !msg.isDeleted)
              _buildActionItem(
                Icons.verified_rounded, "Stamp as Official Notice", () async {
                  Navigator.pop(context);
                  await ApiService.post('/channels/${widget.channel.id}/messages/${msg.id}/stamp', {});
                },
              ),
            if (isAdmin && !msg.isDeleted)
              _buildActionItem(
                Icons.task_alt_rounded, "Convert to Official Ticket", () async {
                  Navigator.pop(context);
                  await ApiService.post('/channels/${widget.channel.id}/messages/${msg.id}/convert-to-issue', {});
                  ref.read(issuesProvider.notifier).refresh();
                },
              ),
            if ((isMe || isAdmin) && !msg.isDeleted)
              _buildActionItem(
                Icons.delete_outline_rounded, "Delete for Everyone", () async {
                   Navigator.pop(context);
                   await ApiService.delete('/channels/${widget.channel.id}/messages/${msg.id}');
                },
              ),
            _buildActionItem(Icons.copy_rounded, "Copy Text", () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF345D7E)),
      title: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<void> _sendMessage({String smartType = "chat"}) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    
    _msgCtrl.clear();
    setState(() => _suggestedIntent = null);

    final user = ref.read(authProvider).value;
    final chatService = ref.read(chatServiceProvider);

    final message = ChatMessage(
      id: "temp-${DateTime.now().millisecondsSinceEpoch}",
      text: text,
      senderId: user?.id ?? "",
      senderName: user?.name ?? "Unknown",
      senderFlat: user?.flatNumber ?? "",
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      smartType: smartType,
    );

    await chatService.sendMessage(widget.channel.id, message);
    
    if (smartType == 'issue_creation') {
      // Invalidate issues provider to show new ticket in other screens
      ref.read(issuesProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎫 Ticket created successfully!")),
        );
      }
    }
  }

  void _handleRetry(ChatMessage msg) {
    ref.read(chatServiceProvider).sendMessage(widget.channel.id, msg);
  }

  void _handleIncomingMessages(List<ChatMessage> messages) {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    for (var m in messages) {
      if (m.senderId != user.id && !m.deliveredBy.contains(user.id)) {
        _sendDeliveryAck(m.id);
      }
    }
  }

  Future<void> _sendDeliveryAck(String msgId) async {
    try {
      await ApiService.post('/channels/${widget.channel.id}/messages/$msgId/delivered', {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // ── Only read static auth data at the top level ──────────────────────────
    // Do NOT watch any StreamProvider here. Every `ref.watch` here causes the
    // entire Scaffold (including AppBar IconButtons with hover regions) to
    // rebuild on every Firestore event, which triggers mouse_tracker.dart:199.
    final currentUser = ref.read(authProvider).value;
    final bool isAdmin = ["admin", "main_admin", "secretary"].contains(currentUser?.role);
    final bool canChat = !widget.channel.isReadOnly || isAdmin;

    // Listen (not watch) to deliver ACKs without triggering a rebuild
    ref.listen(mergedMessagesProvider(widget.channel.id), (previous, next) {
      next.whenData((messages) => _handleIncomingMessages(messages));
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              elevation: 0,
              centerTitle: false,
              foregroundColor: const Color(0xFF1E293B),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.channel.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B))),
                  // Presence/typing only watches presence — isolated from messages
                  IgnorePointer(
                    ignoring: true,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final typingUsers = ref.watch(typingUsersProvider(widget.channel.id));
                        final presence = ref.watch(presenceProvider(widget.channel.id)).value ?? [];
                        
                        if (typingUsers.isNotEmpty) {
                           return TypingStatusText(
                             text: "${typingUsers.join(', ')} ${typingUsers.length > 1 ? 'are' : 'is'} typing...",
                           );
                        }

                        final onlineMods = presence.where((p) => ['admin', 'moderator', 'secretary', 'main_admin'].contains(p.role)).toList();
                        if (onlineMods.isNotEmpty) {
                          return Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(
                                "${onlineMods.first.name}${onlineMods.length > 1 ? ' +${onlineMods.length - 1}' : ''} (Admin) online",
                                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w700),
                              ),
                            ],
                          );
                        }

                        final count = presence.length;
                        return Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text("${count > 0 ? count : 1} Residents Active", style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              // These IconButtons MUST NOT be inside any reactive Consumer
              actions: [
                IconButton(
                  icon: const Icon(Icons.inventory_2_outlined, size: 21),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelVaultScreen(channel: widget.channel))),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 21),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelSettingsScreen(channel: widget.channel))),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          // ── Message list: the ONLY part that rebuilds on Firestore updates ──
          Consumer(
            builder: (context, ref, child) {
              final messagesAsync = ref.watch(mergedMessagesProvider(widget.channel.id));
              return OfficialNoticeBar(messagesState: messagesAsync);
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messagesAsync = ref.watch(mergedMessagesProvider(widget.channel.id));
                return messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return _buildEmptyState();
                    
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        bool showSender = true;
                        bool showDateHeader = false;
                        bool isCompact = false;
                        
                        if (index < messages.length - 1) {
                          final prevMsg = messages[index + 1];
                          final sameSender = msg.senderId == prevMsg.senderId;
                          final sameDay = _isSameDay(msg.createdAt, prevMsg.createdAt);
                          
                          if (sameSender && sameDay) {
                            showSender = false;
                            if (msg.createdAt.difference(prevMsg.createdAt).inMinutes.abs() < 5) {
                              isCompact = true;
                            }
                          }
                          
                          if (!sameDay) showDateHeader = true;
                        } else {
                          showDateHeader = true;
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: isCompact ? 2 : 8),
                          child: Column(
                            children: [
                              if (showDateHeader) _buildDateHeader(msg.createdAt),
                              ChatBubble(
                                key: ValueKey(msg.id),
                                message: msg,
                                isMe: msg.senderId == currentUser?.id,
                                showSender: showSender,
                                isCompact: isCompact,
                                onLongPress: () => _showActionMenu(msg, isAdmin, msg.senderId == currentUser?.id),
                                onRetry: () => _handleRetry(msg),
                                onJoinDeal: _joinDeal,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF345D7E))),
                  error: (e, _) => const Center(child: Text("Connection Lost. Retrying...")),
                );
              },
            ),
          ),
          // ── Typing indicator row — isolated, pointer-ignored ────────────────
          IgnorePointer(
            ignoring: true,
            child: Consumer(
              builder: (context, ref, child) {
                final typingUsers = ref.watch(typingUsersProvider(widget.channel.id));
                if (typingUsers.isEmpty) return const SizedBox.shrink();
                
                final text = typingUsers.length == 1 
                    ? "${typingUsers.first} is typing..." 
                    : "${typingUsers.length} people are typing...";
  
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF94A3B8))),
                      const SizedBox(width: 10),
                      Text(text, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_suggestedIntent != null) SmartIntentBanner(onCreateTicket: () {
            _sendMessage(smartType: 'issue_creation');
          }),
          if (_isUploading) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text("Sharing media...", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                ],
              ),
            ),
          // ── Input bar — completely static, NEVER rebuilt by data changes ────
          ChannelChatInputBar(
            controller: _msgCtrl,
            focusNode: _msgFocus,
            canChat: canChat,
            onPickImage: _pickAndUploadImage,
            onSendMessage: _sendMessage,
            onChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    String label;
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
       label = "TODAY";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
       label = "YESTERDAY";
    } else {
       label = DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: const Color(0xFF345D7E).withValues(alpha: 0.05), shape: BoxShape.circle),
              child: const Icon(Icons.forum_outlined, size: 36, color: Color(0xFF345D7E)),
            ),
            const SizedBox(height: 24),
            Text("The Pulse Hub", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text("Your secure society discussion space.", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.5)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }
}









