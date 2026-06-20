import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/ai_copilot/ai_copilot_models.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final aiCopilotProvider =
    StateNotifierProvider<AiCopilotNotifier, AiCopilotState>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  final roleContext = AiRoleContext.fromRole(
    auth?.role ?? 'resident_owner',
    societyId: auth?.societyId ?? '',
  );
  return AiCopilotNotifier(
    aiService: ref.watch(aiServiceProvider),
    initialRoleContext: roleContext,
  );
});

class AiCopilotState {
  const AiCopilotState({
    required this.roleContext,
    required this.language,
    required this.conversations,
    required this.activeConversationId,
    this.searchQuery = '',
    this.isStreaming = false,
    this.isLoadingHistory = false,
    this.lastError,
    this.pendingAttachment,
  });

  final AiRoleContext roleContext;
  final AiCopilotLanguage language;
  final List<AiCopilotConversation> conversations;
  final String activeConversationId;
  final String searchQuery;
  final bool isStreaming;
  final bool isLoadingHistory;
  final AiRequestError? lastError;
  final AiAttachmentDraft? pendingAttachment;

  AiCopilotConversation get activeConversation {
    return conversations.firstWhere(
      (conversation) => conversation.id == activeConversationId,
      orElse: () => conversations.first,
    );
  }

  List<AiCopilotMessage> get messages => activeConversation.messages;

  List<AiCopilotConversation> get visibleConversations {
    final query = searchQuery.trim().toLowerCase();
    final active =
        conversations.where((conversation) => !conversation.archived);
    if (query.isEmpty) return active.toList(growable: false);
    return active
        .where(
          (conversation) =>
              conversation.title.toLowerCase().contains(query) ||
              conversation.messages.any(
                (message) => message.content.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  List<AiQuickAction> get quickActions {
    return quickActionsForRole(roleContext);
  }

  AiCopilotState copyWith({
    AiRoleContext? roleContext,
    AiCopilotLanguage? language,
    List<AiCopilotConversation>? conversations,
    String? activeConversationId,
    String? searchQuery,
    bool? isStreaming,
    bool? isLoadingHistory,
    AiRequestError? lastError,
    bool clearLastError = false,
    AiAttachmentDraft? pendingAttachment,
    bool clearPendingAttachment = false,
  }) {
    return AiCopilotState(
      roleContext: roleContext ?? this.roleContext,
      language: language ?? this.language,
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      searchQuery: searchQuery ?? this.searchQuery,
      isStreaming: isStreaming ?? this.isStreaming,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      pendingAttachment: clearPendingAttachment
          ? null
          : pendingAttachment ?? this.pendingAttachment,
    );
  }

  static AiCopilotState initial(AiRoleContext roleContext) {
    final conversation = _newConversation();
    return AiCopilotState(
      roleContext: roleContext,
      language: AiCopilotLanguage.english,
      conversations: [conversation],
      activeConversationId: conversation.id,
    );
  }

  static AiCopilotConversation _newConversation() {
    final now = DateTime.now();
    return AiCopilotConversation(
      id: 'local-${now.microsecondsSinceEpoch}',
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
    );
  }
}

class AiCopilotNotifier extends StateNotifier<AiCopilotState> {
  AiCopilotNotifier({
    required AiService aiService,
    required AiRoleContext initialRoleContext,
  })  : _aiService = aiService,
        super(AiCopilotState.initial(initialRoleContext));

  final AiService _aiService;
  int _generationToken = 0;

  void setRoleContext(AiRoleContext roleContext) {
    if (state.roleContext.rawRole == roleContext.rawRole &&
        state.roleContext.societyId == roleContext.societyId) {
      return;
    }
    state = state.copyWith(roleContext: roleContext);
  }

  void setLanguage(AiCopilotLanguage language) {
    state = state.copyWith(language: language);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void newChat() {
    final conversation = AiCopilotState._newConversation();
    state = state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
      clearLastError: true,
    );
  }

  void selectConversation(String id) {
    if (state.conversations.any((conversation) => conversation.id == id)) {
      state = state.copyWith(activeConversationId: id, clearLastError: true);
    }
  }

  void renameConversation(String id, String title) {
    final normalized = title.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(
      conversations: state.conversations
          .map(
            (conversation) => conversation.id == id
                ? conversation.copyWith(
                    title: normalized,
                    updatedAt: DateTime.now(),
                  )
                : conversation,
          )
          .toList(growable: false),
    );
  }

  void archiveConversation(String id) {
    state = state.copyWith(
      conversations: state.conversations
          .map(
            (conversation) => conversation.id == id
                ? conversation.copyWith(
                    archived: true, updatedAt: DateTime.now())
                : conversation,
          )
          .toList(growable: false),
    );
  }

  void deleteConversation(String id) {
    final remaining = state.conversations
        .where((conversation) => conversation.id != id)
        .toList(growable: false);
    final conversations =
        remaining.isEmpty ? [AiCopilotState._newConversation()] : remaining;
    state = state.copyWith(
      conversations: conversations,
      activeConversationId: conversations.first.id,
    );
  }

  void setPendingAttachment(AiAttachmentDraft attachment) {
    state = state.copyWith(pendingAttachment: attachment);
  }

  void clearPendingAttachment() {
    state = state.copyWith(clearPendingAttachment: true);
  }

  void stopGeneration() {
    _generationToken++;
    final messages = state.messages;
    if (messages.isEmpty) {
      state = state.copyWith(isStreaming: false);
      return;
    }
    final last = messages.last;
    if (last.role != AiCopilotMessageRole.assistant ||
        last.status != AiCopilotMessageStatus.streaming) {
      state = state.copyWith(isStreaming: false);
      return;
    }
    _replaceMessage(
      last.copyWith(
        content: last.content.trim().isEmpty
            ? 'Generation stopped.'
            : '${last.content}\n\nGeneration stopped.',
        status: AiCopilotMessageStatus.complete,
      ),
      isStreaming: false,
    );
  }

  Future<void> sendQuickAction(AiQuickAction action) {
    return sendMessage(
      action.prompt,
      intentKey: action.key,
      context: {
        'quickAction': action.key,
        if (action.key == 'financials' ||
            action.key == 'dues_overview' ||
            action.key == 'outstanding_ageing' ||
            action.key == 'collection_summary')
          'groundingInstruction':
              'Use authorized backend finance aggregates only. Do not rely on client-provided totals.',
      },
    );
  }

  Future<void> sendMessage(
    String text, {
    String? intentKey,
    Map<String, dynamic>? context,
  }) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && state.pendingAttachment == null) ||
        state.isStreaming) {
      return;
    }

    final requestId = _requestId();
    final generationToken = ++_generationToken;
    final attachment = state.pendingAttachment;
    final previousHistory = state.messages
        .where((message) => message.status == AiCopilotMessageStatus.complete)
        .map((message) => message.toApiHistoryMap())
        .toList(growable: false);
    final userMessage = AiCopilotMessage(
      id: _messageId('user'),
      role: AiCopilotMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
      requestId: requestId,
      attachment: attachment,
    );
    final assistantMessage = AiCopilotMessage(
      id: _messageId('assistant'),
      role: AiCopilotMessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: AiCopilotMessageStatus.streaming,
      requestId: requestId,
    );

    _appendMessages(
      [userMessage, assistantMessage],
      isStreaming: true,
      clearPendingAttachment: true,
    );
    _maybeAutotitle(trimmed);

    var streamedContent = '';
    var responseType = 'text_answer';
    var metadata = <String, dynamic>{};
    final attachmentToken = attachment?.token;

    try {
      final stream = _aiService.sendMessageStream(
        trimmed,
        history: previousHistory,
        conversationId: state.activeConversationId,
        language: state.language.apiValue,
        requestId: requestId,
        attachmentTokens:
            attachmentToken == null ? const [] : <String>[attachmentToken],
        context: {
          ...?context,
          'intentKey': intentKey,
          'roleContext': state.roleContext.toApiMap(),
          'language': state.language.apiValue,
          if (attachment != null) 'attachment': attachment.toApiMap(),
        }..removeWhere((_, value) => value == null),
      );

      await for (final chunk in stream) {
        if (generationToken != _generationToken) return;
        metadata = {...metadata, ...?chunk.metadata};
        responseType =
            chunk.type ?? metadata['type']?.toString() ?? responseType;
        if (chunk.isComplete) {
          if (chunk.text.trim().isNotEmpty &&
              chunk.text.length >= streamedContent.length) {
            streamedContent = chunk.text;
          }
        } else {
          streamedContent += chunk.text;
        }
        _replaceMessage(
          assistantMessage.copyWith(
            content: streamedContent,
            status: AiCopilotMessageStatus.streaming,
            type: responseType,
            metadata: metadata,
          ),
          isStreaming: true,
        );
      }

      if (generationToken != _generationToken) return;
      _replaceMessage(
        assistantMessage.copyWith(
          content: streamedContent.trim().isEmpty
              ? 'No response from SERO Copilot.'
              : streamedContent.trim(),
          status: responseType == 'error'
              ? AiCopilotMessageStatus.error
              : AiCopilotMessageStatus.complete,
          type: responseType,
          metadata: metadata,
        ),
        isStreaming: false,
      );
    } catch (error) {
      if (generationToken != _generationToken) return;
      final structuredError = AiRequestError(
        requestId: requestId,
        message: 'SERO Copilot could not complete this request.',
        code: error.runtimeType.toString(),
      );
      _replaceMessage(
        assistantMessage.copyWith(
          content: structuredError.message,
          status: AiCopilotMessageStatus.error,
          type: 'system_unavailable',
          metadata: structuredError.toMap(),
        ),
        isStreaming: false,
        error: structuredError,
      );
    }
  }

  void _appendMessages(
    List<AiCopilotMessage> messages, {
    required bool isStreaming,
    bool clearPendingAttachment = false,
  }) {
    final now = DateTime.now();
    final active = state.activeConversation;
    final updated = active.copyWith(
      messages: [...active.messages, ...messages],
      updatedAt: now,
    );
    state = state.copyWith(
      conversations: _replaceConversation(updated),
      isStreaming: isStreaming,
      clearLastError: true,
      clearPendingAttachment: clearPendingAttachment,
    );
  }

  void _replaceMessage(
    AiCopilotMessage message, {
    required bool isStreaming,
    AiRequestError? error,
  }) {
    final active = state.activeConversation;
    final updatedMessages = active.messages
        .map((existing) => existing.id == message.id ? message : existing)
        .toList(growable: false);
    state = state.copyWith(
      conversations: _replaceConversation(
        active.copyWith(messages: updatedMessages, updatedAt: DateTime.now()),
      ),
      isStreaming: isStreaming,
      lastError: error,
      clearLastError: error == null,
    );
  }

  List<AiCopilotConversation> _replaceConversation(
    AiCopilotConversation updated,
  ) {
    return state.conversations
        .map(
          (conversation) =>
              conversation.id == updated.id ? updated : conversation,
        )
        .toList(growable: false);
  }

  void _maybeAutotitle(String text) {
    final active = state.activeConversation;
    if (active.title != 'New chat') return;
    final title = text.length <= 36 ? text : '${text.substring(0, 33)}...';
    renameConversation(active.id, title);
  }

  String _messageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _requestId() {
    return 'ai-${DateTime.now().microsecondsSinceEpoch}';
  }
}

List<AiQuickAction> quickActionsForRole(AiRoleContext roleContext) {
  final role = roleContext.normalizedRole;
  if (role == 'super_admin') {
    return const [
      AiQuickAction(
        key: 'platform_health',
        title: 'Platform Health',
        subtitle: 'Explain support and uptime signals',
        prompt: 'Summarize platform health, support risks, and rollout status.',
        iconName: 'hub',
      ),
      AiQuickAction(
        key: 'society_onboarding',
        title: 'Onboarding',
        subtitle: 'Review society setup progress',
        prompt: 'Summarize society onboarding progress and setup blockers.',
        iconName: 'domain_add',
      ),
      AiQuickAction(
        key: 'subscription_revenue',
        title: 'Revenue',
        subtitle: 'Subscription and billing view',
        prompt: 'Explain subscription revenue trends and pending renewals.',
        iconName: 'payments',
      ),
      AiQuickAction(
        key: 'audit_search',
        title: 'Audit Search',
        subtitle: 'Find platform audit signals',
        prompt: 'Help me search platform audit events for unusual activity.',
        iconName: 'policy',
      ),
    ];
  }

  if (role == 'treasurer') {
    return const [
      AiQuickAction(
        key: 'collection_summary',
        title: 'Collections',
        subtitle: 'Authorized aggregate summary',
        prompt: 'Show an authorized collection summary for this society.',
        iconName: 'account_balance_wallet',
      ),
      AiQuickAction(
        key: 'outstanding_ageing',
        title: 'Ageing',
        subtitle: 'Outstanding dues risk',
        prompt: 'Explain outstanding dues ageing and collection risks.',
        iconName: 'pending_actions',
      ),
      AiQuickAction(
        key: 'expense_analysis',
        title: 'Expenses',
        subtitle: 'Review spend patterns',
        prompt: 'Analyze expense patterns and budget variance.',
        iconName: 'receipt_long',
      ),
      AiQuickAction(
        key: 'reconciliation',
        title: 'Reconcile',
        subtitle: 'Payment matching guidance',
        prompt: 'Guide me through bank reconciliation exceptions.',
        iconName: 'sync_alt',
      ),
    ];
  }

  if (role == 'guard' || role == 'security_manager') {
    return const [
      AiQuickAction(
        key: 'visitor_verification',
        title: 'Visitors',
        subtitle: 'Verify entry workflow',
        prompt: 'Guide me through visitor verification and entry workflow.',
        iconName: 'verified_user',
      ),
      AiQuickAction(
        key: 'parcel_workflow',
        title: 'Parcels',
        subtitle: 'Delivery handoff steps',
        prompt: 'Explain the approved parcel handling workflow.',
        iconName: 'inventory_2',
      ),
      AiQuickAction(
        key: 'incident_report',
        title: 'Incident',
        subtitle: 'Draft report safely',
        prompt: 'Help me draft an incident report with the required details.',
        iconName: 'report',
      ),
      AiQuickAction(
        key: 'sos_procedure',
        title: 'SOS',
        subtitle: 'Emergency response',
        prompt: 'Show the society emergency and SOS procedure.',
        iconName: 'sos',
      ),
    ];
  }

  if (role == 'staff' || role == 'facility_manager') {
    return const [
      AiQuickAction(
        key: 'assigned_tasks',
        title: 'My Tasks',
        subtitle: 'Assigned work guidance',
        prompt: 'Summarize my assigned tasks and next steps.',
        iconName: 'task_alt',
      ),
      AiQuickAction(
        key: 'complaint_work',
        title: 'Complaint Work',
        subtitle: 'Resolution guidance',
        prompt: 'Guide me through the approved complaint work process.',
        iconName: 'engineering',
      ),
      AiQuickAction(
        key: 'facility_schedule',
        title: 'Facilities',
        subtitle: 'Timing and rules',
        prompt: 'Show facility schedules, rules, and service instructions.',
        iconName: 'event_available',
      ),
      AiQuickAction(
        key: 'asset_instructions',
        title: 'Assets',
        subtitle: 'Maintenance instructions',
        prompt: 'Find approved maintenance instructions for an asset.',
        iconName: 'home_repair_service',
      ),
    ];
  }

  if (role == 'secretary' || role == 'committee_member') {
    return const [
      AiQuickAction(
        key: 'draft_notice',
        title: 'Draft Notice',
        subtitle: 'Member communication',
        prompt: 'Draft a clear society notice for members.',
        iconName: 'campaign',
      ),
      AiQuickAction(
        key: 'meeting_agenda',
        title: 'Agenda',
        subtitle: 'Meeting preparation',
        prompt: 'Prepare a committee meeting agenda.',
        iconName: 'event_note',
      ),
      AiQuickAction(
        key: 'minutes_draft',
        title: 'Minutes',
        subtitle: 'Resolution draft',
        prompt: 'Draft meeting minutes and resolutions from my notes.',
        iconName: 'article',
      ),
      AiQuickAction(
        key: 'rule_lookup',
        title: 'Rules',
        subtitle: 'Find bylaw references',
        prompt: 'Find the relevant society rule and cite the source.',
        iconName: 'gavel',
      ),
    ];
  }

  if (roleContext.isAdminLike) {
    return const [
      AiQuickAction(
        key: 'society_summary',
        title: 'Society Summary',
        subtitle: 'Operations snapshot',
        prompt: 'Summarize society operations, risks, and pending actions.',
        iconName: 'dashboard',
      ),
      AiQuickAction(
        key: 'draft_notice',
        title: 'Draft Notice',
        subtitle: 'Announcements',
        prompt: 'Help me draft a professional society notice for members.',
        iconName: 'campaign',
      ),
      AiQuickAction(
        key: 'sla_risks',
        title: 'SLA Risks',
        subtitle: 'Complaint escalation',
        prompt: 'Summarize complaint SLA risks and suggested assignments.',
        iconName: 'warning',
      ),
      AiQuickAction(
        key: 'financials',
        title: 'Financials',
        subtitle: 'Backend-grounded finance view',
        prompt:
            'Provide an authorized high-level summary of treasury, collections, dues, and recent expenditures.',
        iconName: 'insert_chart',
      ),
    ];
  }

  return const [
    AiQuickAction(
      key: 'explain_bill',
      title: 'Explain Bill',
      subtitle: 'Dues and receipts',
      prompt: 'Explain my latest society bill and any outstanding dues.',
      iconName: 'receipt_long',
    ),
    AiQuickAction(
      key: 'rule_lookup',
      title: 'Find Rule',
      subtitle: 'Society rules',
      prompt: 'Find the society rule for visitor parking and renovation.',
      iconName: 'gavel',
    ),
    AiQuickAction(
      key: 'facility_timings',
      title: 'Facilities',
      subtitle: 'Timings and booking',
      prompt: 'Show facility timings and booking guidance.',
      iconName: 'event_available',
    ),
    AiQuickAction(
      key: 'raise_complaint',
      title: 'Complaint',
      subtitle: 'Raise or track issue',
      prompt: 'Help me raise or track a maintenance complaint.',
      iconName: 'engineering',
    ),
  ];
}
