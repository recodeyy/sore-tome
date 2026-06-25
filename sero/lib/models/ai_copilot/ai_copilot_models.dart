enum AiCopilotLanguage {
  english('english', 'English', 'EN'),
  hindi('hindi', 'हिन्दी', 'HI'),
  hinglish('hinglish', 'Hinglish', 'HG');

  const AiCopilotLanguage(this.apiValue, this.label, this.shortLabel);

  final String apiValue;
  final String label;
  final String shortLabel;

  static AiCopilotLanguage fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'hindi':
      case 'hi':
        return AiCopilotLanguage.hindi;
      case 'hinglish':
      case 'hg':
        return AiCopilotLanguage.hinglish;
      case 'english':
      case 'en':
      default:
        return AiCopilotLanguage.english;
    }
  }
}

enum AiCopilotMessageRole { user, assistant, system }

enum AiCopilotMessageStatus { sending, streaming, complete, error }

class AiRoleContext {
  const AiRoleContext({
    required this.rawRole,
    required this.normalizedRole,
    required this.societyId,
    this.permissions = const <String>{},
  });

  final String rawRole;
  final String normalizedRole;
  final String societyId;
  final Set<String> permissions;

  bool get isAdminLike {
    return {
      'super_admin',
      'main_admin',
      'admin',
      'secretary',
      'treasurer',
      'committee_member',
      'facility_manager',
      'security_manager',
      'auditor',
    }.contains(normalizedRole);
  }

  bool hasPermission(String permission) => permissions.contains(permission);

  Map<String, dynamic> toApiMap() {
    return {
      'role': normalizedRole,
      'rawRole': rawRole,
      'societyId': societyId,
      'permissions': permissions.toList(growable: false),
    };
  }

  static AiRoleContext fromRole(String role, {String societyId = ''}) {
    return AiRoleContext(
      rawRole: role,
      normalizedRole: normalizeRole(role),
      societyId: societyId,
    );
  }

  static String normalizeRole(String role) {
    final cleaned = role.trim().toLowerCase().replaceAll('-', '_');
    switch (cleaned) {
      case 'mainadmin':
      case 'main_admin':
      case 'owner_admin':
        return 'main_admin';
      case 'superadmin':
      case 'super_admin':
        return 'super_admin';
      case 'resident':
        return 'resident_owner';
      case 'resident_owner':
      case 'owner':
        return 'resident_owner';
      case 'resident_tenant':
      case 'tenant':
        return 'resident_tenant';
      case 'committee':
      case 'committee_member':
        return 'committee_member';
      case 'facility':
      case 'facility_manager':
        return 'facility_manager';
      case 'security':
      case 'security_manager':
        return 'security_manager';
      case 'guard':
      case 'staff':
      case 'admin':
      case 'secretary':
      case 'treasurer':
      case 'auditor':
        return cleaned;
      default:
        return cleaned.isEmpty ? 'resident_owner' : cleaned;
    }
  }
}

class AiQuickAction {
  const AiQuickAction({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.iconName,
    this.requiredPermission,
  });

  final String key;
  final String title;
  final String subtitle;
  final String prompt;
  final String iconName;
  final String? requiredPermission;
}

class AiAttachmentDraft {
  const AiAttachmentDraft({
    required this.localPath,
    required this.fileName,
    required this.mimeHint,
    this.token,
    this.uploadStatus = 'local_preview_only',
  });

  final String localPath;
  final String fileName;
  final String mimeHint;
  final String? token;
  final String uploadStatus;

  Map<String, dynamic> toApiMap() {
    return {
      'fileName': fileName,
      'mimeHint': mimeHint,
      'token': token,
      'uploadStatus': uploadStatus,
    };
  }
}

class AiRequestError {
  const AiRequestError({
    required this.message,
    required this.requestId,
    this.code = 'AI_REQUEST_FAILED',
    this.retryable = true,
  });

  final String message;
  final String requestId;
  final String code;
  final bool retryable;

  Map<String, dynamic> toMap() {
    return {
      'type': 'error',
      'reply': message,
      'code': code,
      'requestId': requestId,
      'retryable': retryable,
    };
  }
}

class AiCopilotMessage {
  const AiCopilotMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = AiCopilotMessageStatus.complete,
    this.type = 'text_answer',
    this.requestId,
    this.metadata = const <String, dynamic>{},
    this.attachment,
  });

  final String id;
  final AiCopilotMessageRole role;
  final String content;
  final DateTime createdAt;
  final AiCopilotMessageStatus status;
  final String type;
  final String? requestId;
  final Map<String, dynamic> metadata;
  final AiAttachmentDraft? attachment;

  AiCopilotMessage copyWith({
    String? content,
    AiCopilotMessageStatus? status,
    String? type,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) {
    return AiCopilotMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      type: type ?? this.type,
      requestId: requestId ?? this.requestId,
      metadata: metadata ?? this.metadata,
      attachment: attachment,
    );
  }

  Map<String, dynamic> toApiHistoryMap() {
    return {
      'role': role == AiCopilotMessageRole.user ? 'user' : 'assistant',
      'content': content,
      if (type.isNotEmpty) 'type': type,
      if (requestId != null) 'requestId': requestId,
    };
  }

  Map<String, dynamic> toBubbleMap() {
    return {
      'role': role == AiCopilotMessageRole.user ? 'user' : 'assistant',
      'content': content,
      'reply': role == AiCopilotMessageRole.assistant ? content : null,
      'type': _legacyType(type),
      'requestId': requestId,
      'status': status.name,
      if (attachment != null) 'imagePath': attachment!.localPath,
      ...metadata,
    }..removeWhere((_, value) => value == null);
  }

  static String _legacyType(String type) {
    switch (type) {
      case 'draft_notice':
      case 'draft_complaint':
      case 'draft_expense':
      case 'draft_event':
      case 'draft_poll':
        return 'draft';
      case 'action_proposal':
      case 'action_confirmation':
      case 'action_progress':
      case 'action_success':
      case 'action_failure':
        return 'action';
      case 'rate_limit':
      case 'system_unavailable':
        return 'error';
      default:
        return type;
    }
  }
}

class AiCopilotConversation {
  const AiCopilotConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.messages = const <AiCopilotMessage>[],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final List<AiCopilotMessage> messages;

  AiCopilotConversation copyWith({
    String? title,
    DateTime? updatedAt,
    bool? archived,
    List<AiCopilotMessage>? messages,
  }) {
    return AiCopilotConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      messages: messages ?? this.messages,
    );
  }
}
