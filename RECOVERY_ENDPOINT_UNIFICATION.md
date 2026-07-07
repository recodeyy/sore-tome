# RECOVERY — Legacy ↔ v2 Endpoint Unification (status)

> Date: 2026-06-25 · Prompt §10. Canonical = Postgres v2 routers. Legacy routers kept temporarily with **deprecation logging** added (warn on hit). Update: complaints + polls fully migrated; channels write-paths migrated (see table).

## Backend (done)
- Deprecation middleware added to legacy routers: `notices.js`, `events.js`, `polls.js`, `rules.js`, `channels.js`, `issues.js`, `staff.js` → each logs `DEPRECATED legacy route hit — use v2` on every request. Behavior unchanged (safe compatibility window).

## Flutter consumer migration

| Domain | Legacy → Canonical | Status | Notes |
|---|---|---|---|
| Notices | `/notices` → `/notices-v2` | ✅ migrated | `firestore_service.dart` getNotices/postNotice + `ai_notice_writer_screen.dart`. Fixed `postNotice` to send valid `type:'general'` (v2 enum) instead of legacy display tag. |
| Rules | `/rules` → `/rules-v2` | ✅ migrated | `rules_provider.dart` fetch/add + `Rule.fromMap` now reads `body` (v2) with `content` fallback; category normalized to v2 enum. |
| Events | `/events-v2` | ✅ already canonical | No change needed. |
| Staff | `/staff-v2` | ✅ already canonical | Admin staff service already on v2. |
| Complaints | `/issues` → `/complaints` | ✅ migrated | `Issue.fromMap` now reads v2 snake_case (`created_by`→postedBy, `created_at`→createdAt) with camelCase fallback. Provider `issues_provider.dart` + `firestore_service.dart` REST calls + `voice_mode_screen.dart` now hit `/complaints`. List reads `{complaints}`. Create drops the free-text `category` (v2 schema is strict — only `categoryId` UUID). Status via `PATCH /complaints/:id/status`; resolve→resolved, assign→in_progress, delete→closed (v2 has no hard-delete). |
| Polls | `/polls/{id}/vote` → `/polls-v2` | ✅ migrated | `pollsProvider` (resident) is now an HTTP `FutureProvider` over `/polls-v2` (list `?status=open` → per-poll `/polls-v2/:id` for option labels+`hasVoted` → `/polls-v2/:id/results` for tallies). New `PollOption{id,label,count}` + `Poll.fromV2`; `Poll` keeps legacy fields for back-compat. Vote in `polls_screen.dart` now `POST /polls-v2/:id/vote {optionId:UUID}` (201). |
| Channels | `/channels` → `/channels-v2` | ◑ partially migrated | Clean v2 counterparts cut over: send message (`chat_service.dart` → `/channels-v2/:id/messages {body,isOfficial?}`), mark-read (`channel_chat_screen.dart` → `/channels-v2/:id/read`), create channel (`create_channel_screen.dart` → `/channels-v2`). `Channel.fromMap`/`ChatMessage.fromMap` now parse v2 snake_case (`is_read_only`, `body`, `author_id/name`, `created_at`, `is_official`, `deleted_at`). See "stays on legacy" below for the rest. |

### Intentionally NOT migrated (no v2 equivalent)
- `/notices/ai-generate`, `/ai/rules` — AI endpoints exist only on the legacy/AI router.
- **Channels — features with no v2 counterpart (left on legacy, unbroken):** `/channels/admin/briefing` (AI briefing), `/channels/:id/typing` (presence), `/channels/:id/media` + media-upload message create (`clientId/status:uploading` not in v2 strict schema), `/messages/:id/join-deal`, `/stamp`, `/convert-to-issue`, `/delivered`, DELETE `/messages/:id`, PATCH `/channels/:id`, `/channels/:id/clear`, DELETE `/channels/:id`.
- **Channels — realtime reads stay on Firestore:** `channelsListProvider`, `channelMessagesProvider`, `paginatedMessagesProvider`, `mergedMessagesProvider` are live Firestore streams powering the chat UI (optimistic send, presence, pagination). v2 `GET /channels-v2` + `/messages` are cursor-paginated REST, not streams; swapping them would require rewriting the entire realtime/optimistic-UI architecture and would break the working chat screen — out of scope for a safe model+endpoint cutover.

## Result
- 6 of 7 domains fully canonical (notices, rules, events, staff, complaints, polls); channels partially canonical (write paths on v2; realtime reads + niche features remain on Firestore/legacy where no clean v2 equivalent exists). No regressions; `flutter analyze` = 0 errors (38 pre-existing info/warning lints unchanged).
