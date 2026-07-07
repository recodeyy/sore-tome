# Frontend Backend Contract: AI Cross-Role

## Chat Streaming

Frontend sends `POST /ai/chat` with:

- `message`
- `stream: true`
- `conversationId`
- `requestId`
- `language`: `english`, `hindi`, or `hinglish`
- `history`
- `context.roleContext`: normalized role, raw role, society ID, permissions
- `attachmentTokens`

Expected SSE events should include text deltas and a final event with type/metadata, sources, proposed actions, and request ID.

## Conversations

Required backend APIs:

- List/search conversations with pagination.
- Create/resume/rename/archive/delete conversation.
- Fetch messages by conversation.
- Persist selected language and feedback.

## Attachments

Required backend APIs:

- Create signed upload.
- Return file token.
- Report upload progress/state.
- Report scan, parse, and index state.
- Reject AI ingestion until scan and authorization pass.

## Finance And Cross-Role Grounding

AI finance, visitor, staff, complaint, document, and governance answers must use backend-authorized aggregates/tools. The frontend no longer injects finance totals from Firestore.

## Actions

Every AI write action should return a proposal with:

- `actionId`
- `tool`
- `params`
- `target`
- `permission`
- `approvalRequired`
- `expiresAt`
- `requestId`

Confirming calls `/ai/execute-tool` with `actionId`; backend must bind actor, society, arguments, expiry, approval, and audit log.
