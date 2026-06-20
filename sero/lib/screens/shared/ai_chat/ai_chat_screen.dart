import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/ai_copilot/ai_copilot_models.dart';
import 'package:sero/providers/ai_copilot/ai_copilot_provider.dart';

import 'widgets/concierge_bubble.dart';
import 'widgets/input_console.dart';
import 'widgets/quick_action_tiles.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? initialContext;
  final String userRole;

  const AiChatScreen({
    super.key,
    this.initialMessage,
    this.initialContext,
    this.userRole = 'resident',
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRoleContext();
      if (widget.initialMessage != null) {
        ref.read(aiCopilotProvider.notifier).sendMessage(
              widget.initialMessage!,
              context: widget.initialContext,
            );
      }
    });
  }

  @override
  void didUpdateWidget(covariant AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncRoleContext());
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _syncRoleContext() {
    ref.read(aiCopilotProvider.notifier).setRoleContext(
          AiRoleContext.fromRole(
            widget.userRole,
            societyId: ref.read(aiCopilotProvider).roleContext.societyId,
          ),
        );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    ref.read(aiCopilotProvider.notifier).setPendingAttachment(
          AiAttachmentDraft(
            localPath: image.path,
            fileName: image.name,
            mimeHint: 'image/*',
          ),
        );
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && ref.read(aiCopilotProvider).pendingAttachment == null) {
      return;
    }
    _msgCtrl.clear();
    ref.read(aiCopilotProvider.notifier).sendMessage(text);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      aiCopilotProvider.select((state) => state.messages.length),
      (_, __) => _scrollToBottom(),
    );

    final state = ref.watch(aiCopilotProvider);
    final notifier = ref.read(aiCopilotProvider.notifier);
    final aiService = ref.watch(aiServiceProvider);
    final role = state.roleContext.normalizedRole;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kSlateBg,
      drawer: _ConversationDrawer(state: state, notifier: notifier),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: _CopilotHeader(
                    roleContext: state.roleContext,
                    language: state.language,
                    isStreaming: state.isStreaming,
                    onOpenHistory: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    onNewChat: notifier.newChat,
                    onStop: notifier.stopGeneration,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _LanguageSelector(
                  selected: state.language,
                  onSelected: notifier.setLanguage,
                ),
              ),
              SliverToBoxAdapter(
                child: _ConversationSearch(
                  query: state.searchQuery,
                  onChanged: notifier.setSearchQuery,
                ),
              ),
              QuickActionTiles(
                userRole: role,
                actions: state.quickActions,
                onQuickAction: notifier.sendQuickAction,
                onAction: (prompt, key) => notifier.sendMessage(
                  prompt,
                  intentKey: key,
                ),
              ),
              if (state.messages.isEmpty)
                const SliverToBoxAdapter(child: _EmptyCopilotState()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final msg = state.messages[index];
                    return ConciergeBubble(
                      message: msg.toBubbleMap(),
                      isUser: msg.role == AiCopilotMessageRole.user,
                      aiService: aiService,
                      userRole: role,
                      onActionExecuted: () => setState(() {}),
                    );
                  }, childCount: state.messages.length),
                ),
              ),
              if (state.isStreaming)
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
            isStreaming: state.isStreaming,
            onSend: _send,
            onStop: notifier.stopGeneration,
            onPickImage: _pickImage,
            onRemoveImage: notifier.clearPendingAttachment,
            imagePath: state.pendingAttachment?.localPath,
            attachmentNotice: state.pendingAttachment == null
                ? null
                : 'Attachment preview only. Backend signed upload/token support is required before AI ingestion.',
          ),
        ],
      ),
    );
  }
}

class _CopilotHeader extends StatelessWidget {
  const _CopilotHeader({
    required this.roleContext,
    required this.language,
    required this.isStreaming,
    required this.onOpenHistory,
    required this.onNewChat,
    required this.onStop,
  });

  final AiRoleContext roleContext;
  final AiCopilotLanguage language;
  final bool isStreaming;
  final VoidCallback onOpenHistory;
  final VoidCallback onNewChat;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: kPremiumGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _HeaderIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: 'Conversation history',
                  onTap: onOpenHistory,
                ),
                const Spacer(),
                _HeaderIconButton(
                  icon: Icons.add_comment_rounded,
                  tooltip: 'New chat',
                  onTap: onNewChat,
                ),
                const SizedBox(width: 10),
                _HeaderIconButton(
                  icon: isStreaming ? Icons.stop_rounded : Icons.auto_awesome,
                  tooltip: isStreaming ? 'Stop generation' : 'SERO Copilot',
                  onTap: isStreaming ? onStop : () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'SERO Copilot',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Role-aware society assistant for rules, complaints, facilities, notices, and authorized operational summaries.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderBadge(
                  icon: Icons.verified_user_rounded,
                  label: _roleLabel(roleContext.normalizedRole),
                ),
                _HeaderBadge(
                  icon: Icons.translate_rounded,
                  label: language.label,
                ),
                _HeaderBadge(
                  icon: Icons.apartment_rounded,
                  label: roleContext.societyId.isEmpty
                      ? 'Current society'
                      : roleContext.societyId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    return role
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.selected,
    required this.onSelected,
  });

  final AiCopilotLanguage selected;
  final ValueChanged<AiCopilotLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kSlateBorder.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: AiCopilotLanguage.values.map((language) {
            final isSelected = language == selected;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Reply language ${language.label}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(language),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      language.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _ConversationSearch extends StatelessWidget {
  const _ConversationSearch({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.outfit(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search current conversation history',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(''),
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

class _ConversationDrawer extends StatelessWidget {
  const _ConversationDrawer({
    required this.state,
    required this.notifier,
  });

  final AiCopilotState state;
  final AiCopilotNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kSlateBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Copilot chats',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New chat',
                    onPressed: () {
                      notifier.newChat();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: notifier.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search conversations',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: state.visibleConversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = state.visibleConversations[index];
                    final selected =
                        conversation.id == state.activeConversationId;
                    return Container(
                      decoration: BoxDecoration(
                        color: selected ? kPrimaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? kPrimaryGreen
                              : kSlateBorder.withValues(alpha: 0.7),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          notifier.selectConversation(conversation.id);
                          Navigator.of(context).pop();
                        },
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          '${conversation.messages.length} messages',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.75)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameDialog(context, conversation);
                            } else if (value == 'archive') {
                              notifier.archiveConversation(conversation.id);
                            } else if (value == 'delete') {
                              notifier.deleteConversation(conversation.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'History is currently held in frontend state. Server persistence and cross-device sync require backend conversation APIs.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    AiCopilotConversation conversation,
  ) {
    final controller = TextEditingController(text: conversation.title);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Conversation title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.renameConversation(conversation.id, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyCopilotState extends StatelessWidget {
  const _EmptyCopilotState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kSlateBorder.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Ask in English, Hindi, or Hinglish. Copilot will request backend-grounded society data instead of relying on client-side totals.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
