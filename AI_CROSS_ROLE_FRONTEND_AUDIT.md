# AI Cross-Role Frontend Audit

Scope: frontend AI Copilot paths only. Backend/admin integration files were not edited.

## Evidence

- `sero/lib/screens/shared/ai_chat/ai_chat_screen.dart` previously kept `_messages` and `_loading` in a local `StatefulWidget`.
- The screen called `AiService.sendMessage`, while `AiService.sendMessageStream` and `SseManager` already existed.
- Role context was limited to `widget.userRole` values such as `resident`/`admin`.
- The screen directly called `FirestoreService.getFundSummary()` for the `financials` quick action.
- Picked images were read into memory and converted to `data:image/png;base64,...`.
- Action proposal cards execute `/ai/execute-tool` through `AiService.executeAction`.

## Implemented Frontend Corrections

- Added Riverpod-owned AI Copilot conversation state under `sero/lib/providers/ai_copilot`.
- Added typed AI Copilot models under `sero/lib/models/ai_copilot`.
- Switched the chat screen to the streaming path.
- Removed direct Firestore finance reads from `AiChatScreen`.
- Added role-normalized quick actions for resident, admin, secretary, treasurer, staff, guard, and super admin contexts.
- Added English/Hindi/Hinglish language selection.
- Added local conversation history, new chat, rename/archive/delete, and search UI state.
- Added structured frontend request IDs and error rendering.
- Replaced base64 attachment sending with local preview plus metadata/token placeholder.

## Remaining Backend Dependencies

- Durable conversation CRUD/search/sync APIs.
- Signed upload/token APIs plus scan/index lifecycle.
- True SSE cancellation endpoint or abortable client path.
- Server-authored role permissions and field-level redaction in AI responses.
- AI feedback persistence endpoint.
