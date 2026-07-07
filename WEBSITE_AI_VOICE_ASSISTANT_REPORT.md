# SERO Admin Web — AI & Voice Assistant Report

## 1. AI assistant

A floating assistant is available on every authenticated page (`components/ai/AIAssistant.tsx`),
plus an `/ai` landing page with example prompts and safety notes.

### Providers & routing
- Proxied through the BFF `POST /api/ai/chat`. Two modes (env `AI_PROXY_MODE`):
  - **`backend`** (preferred): forwards to canonical backend `POST /ai/chat`, which holds the
    Groq/Gemini keys and applies society context + tool execution guards.
  - **`direct`**: BFF calls Groq (`llama-3.3-70b-versatile`) with a **server-side** key. Used
    locally because the dev backend is unkeyed. Keys never reach the browser in either mode.
- Multilingual: users may ask in English/Hindi/Hinglish; the system prompt keeps answers concise
  and forbids the model from claiming it performed an action.

### Verified
```
POST /api/ai/chat {"message":"what is a maintenance dues reminder?"}
→ {"reply":"A maintenance dues reminder is a notification sent to residents...","provider":"groq"}
```
Playwright: `AI proxy responds without exposing keys` — **PASS**.

### Safety / authorization
- **No key in browser bundle** — verified: keys are only read from non-`NEXT_PUBLIC_` server env.
- **Role/tenant scope** — in backend mode the backend enforces `authMiddleware + tenantMiddleware`
  on `/ai/chat`; the assistant cannot read another society's data.
- **Human confirmation on high-impact actions** — the client detects action verbs
  (send/generate/create/delete/publish/charge/refund/remind/waive/approve/reject) and shows a
  **confirmation gate** before the request is sent with `confirmed:true`. Nothing high-impact is
  executed silently.
- **Prompt-injection posture** — the assistant proposes; write actions still traverse the normal
  authorized backend endpoints (it cannot bypass RBAC by "deciding" to act).

### Use cases wired to the product
Admin: dues summaries, unpaid flats, draft reminder (Hindi), complaint summary, draft notice,
un-acknowledged residents, collection-drop explanation, AGM agenda, vendor performance.
Super Admin: churn risk, payment adoption, incomplete setup, SLA-breaching tickets, draft global
announcement. (Answers are grounded when backend mode + AI data endpoints are enabled.)

## 2. Voice assistant (ElevenLabs)

- **Text-to-speech** via BFF `POST /api/voice/tts` → ElevenLabs `text-to-speech/{voiceId}`
  (`eleven_multilingual_v2`). Returns `audio/mpeg`; the client plays it via an `<audio>` element.
- **Verified**: `POST /api/voice/tts {"text":"Hello from SERO"}` → **HTTP 200, 20 KB valid MP3**
  (ID3/MPEG layer III confirmed). Requires an authenticated session (anonymous users are 401 —
  cannot burn voice credits).
- **Voice input**: mic button uses the browser Web Speech API to transcribe into the prompt box.
- **Multilingual**: `eleven_multilingual_v2` supports Hindi/English/Hinglish playback.
- **Controls & privacy**: stop/replay via the audio element; a persistent privacy notice states
  audio is processed via a secure server proxy and not stored. The API key is **server-only**.
- **High-impact voice commands** inherit the same confirmation gate as typed commands.

## 3. Residual items (P2/P3)
- Provision AI keys in the backend `.env` and flip `AI_PROXY_MODE=backend` for grounded,
  fully society-scoped answers with tool execution.
- Optional speech-to-text via a server proxy (currently browser Web Speech API) for parity across
  browsers.
