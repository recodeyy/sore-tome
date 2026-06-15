import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/ai_service.dart';

// Modularized Widgets
import 'widgets/quick_action_tiles.dart';
import 'widgets/concierge_bubble.dart';
import 'widgets/input_console.dart';
import 'package:sero/services/firestore_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? initialContext;
  final String userRole; // 'resident' or 'admin'

  const AiChatScreen({
    super.key, 
    this.initialMessage, 
    this.initialContext,
    this.userRole = 'resident',
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _aiService = AiService();
  final _firestore = FirestoreService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode(); // Track input focus
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _isFocused = false; // Add focus state

  // Attachment State
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();

    // Add listener to track focus changes for animation
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });

    // V3.11: Handle initial message and context
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(message: widget.initialMessage, context: widget.initialContext);
      });
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose(); // Cleanup
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
  }

  void _send({String? message, Map<String, dynamic>? context}) async {
    final text = (message ?? _msgCtrl.text).trim();
    if ((text.isEmpty && _selectedImage == null) || _loading) return;

    final currentImage = _selectedImage;
    final currentBase64 = _base64Image;

    _msgCtrl.clear();
    _removeImage(); // Clear selection after sending

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'imagePath': currentImage?.path,
      });
      _loading = true;
    });
    _scrollToBottom();

    final data = await _aiService.sendMessage(
      text,
      base64Image: currentBase64,
      context: {
        ...(context ?? {}),
        'userRole': widget.userRole,
      },
    );
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', ...data});
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
               const SliverToBoxAdapter(child: SizedBox(height: 24)),
               QuickActionTiles(
                 userRole: widget.userRole,
                 onAction: (prompt, key) async {
                Map<String, dynamic>? context;
                if (key == 'financials') {
                  final summary = await _firestore.getFundSummary();
                  context = {
                    'totalCollected': summary.totalCollected,
                    'totalSpent': summary.totalSpent,
                    'outstandingDues': summary.outstandingDues,
                    'categories': summary.categoryBreakdown,
                    'databaseStatus': 'Live Data from Firestore',
                    'groundingRule': 'CRITICAL: Use these EXACT numbers. If any value is 0, report it as 0. Do NOT hallucinate placeholder values.',
                  };
                }
                _send(message: prompt, context: context);
              }),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final msg = _messages[index];
                    return ConciergeBubble(
                      message: msg,
                      isUser: msg['role'] == 'user',
                      aiService: _aiService,
                      userRole: widget.userRole,
                      onActionExecuted: () => setState(() {}),
                    );
                  }, childCount: _messages.length),
                ),
              ),

              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: TypingIndicator(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 300)),
            ],
          ),

          FloatingInputConsole(
            controller: _msgCtrl,
            focusNode: _focusNode,
            isFocused: _isFocused,
            onSend: _send,
            onPickImage: _pickImage,
            onRemoveImage: _removeImage,
            imagePath: _selectedImage?.path,
          ),
        ],
      ),
    );
  }
}











