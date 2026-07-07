# SERO Admin Web — Architecture

## 1. Stack

| Layer | Choice |
|---|---|
| Framework | **Next.js 14.2 (App Router)** + React 18 |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS (custom green-white design system) |
| Data | **TanStack Query** (server state) + TanStack Table |
| Charts | Recharts |
| Icons | lucide-react |
| Exports | jsPDF + jspdf-autotable (PDF), native CSV writer |
| i18n | Custom lightweight dictionary provider (en/hi/mr/gu/kn) |
| Tests | Playwright (API + UI E2E) |

Runs on **:3005**; canonical backend on **:3001** (unchanged, shared with mobile).

## 2. The BFF (Backend-for-Frontend) boundary

The browser **never** talks to the backend or any AI/voice provider directly. All traffic
goes through Next.js **route handlers**, so tokens and API keys stay server-side.

```
Browser (React) ──HTTPS──> Next.js server (BFF, :3005) ──Bearer JWT──> SERO backend (:3001)
                             ├─ /api/session/login|logout|me   (auth, sets httpOnly cookies)
                             ├─ /api/proxy/[...path]           (authed passthrough + token refresh)
                             ├─ /api/ai/chat                   (Groq/Gemini — server key)
                             └─ /api/voice/tts                 (ElevenLabs — server key)
```

- **Auth tokens** (`sero_token`, `sero_refresh`) are stored in **httpOnly, SameSite=Lax**
  cookies — unreadable by client JS (XSS-resistant). A display-only `sero_user` cookie holds
  non-sensitive fields (name/role/portal) for the shell.
- **`/api/proxy/[...path]`** attaches the Bearer token server-side, forwards the request, and
  on `401` transparently **rotates the refresh token once** and retries.
- **AI/voice keys** are read only from server env (`GROQ_API_KEY`, `ELEVENLABS_API_KEY`, …)
  and are **never** prefixed `NEXT_PUBLIC_`, so they cannot enter the client bundle.

## 3. Directory map (`sero-admin-web/src`)

```
app/
  layout.tsx, providers.tsx, globals.css     # root shell + React Query/i18n/toast providers
  page.tsx                                    # session-aware redirect
  login/page.tsx                              # portal-select login
  (portal)/layout.tsx                         # authed shell: Sidebar + Topbar + AIAssistant
  (portal)/dashboard | billing | payments | reconciliation | expenses | reports
           | members | notices | polls | events | complaints | staff | visitors
           | parking | assets | ai | settings
  (portal)/super-admin/{dashboard,societies,applications,revenue,support,
                        announcements,health,audit}
  api/session/{login,logout,me}/route.ts
  api/proxy/[...path]/route.ts
  api/ai/chat/route.ts
  api/voice/tts/route.ts
components/
  shell/{Sidebar,Topbar,LanguageSelector}.tsx
  ui/{primitives,states,toast}.tsx            # Card, StatCard, Modal, chips, skeletons, toasts
  data/ResourceList.tsx                       # generic live table + CSV/PDF export
  ai/AIAssistant.tsx                          # floating chat + TTS + mic + confirm gate
lib/
  backend.ts (server) · session.ts (server)   # backend fetch + cookie session
  api-client.ts · hooks.ts                     # client fetch + React Query hooks
  nav.ts                                        # role-based navigation model
  format.ts · export.ts                         # minor-unit money/date fmt, CSV/PDF
  i18n/{dictionaries,provider}.ts(x)
middleware.ts                                   # route protection (redirect to /login)
```

## 4. Auth & role model

- Login proxies backend `POST /auth/login {phone,password,portal}`; portal is `admin` or
  `super-admin`. Backend resolves the workspace/role and returns a scoped JWT.
- **Role-based sidebar** (`lib/nav.ts`): Treasurer → finance modules; Secretary → comms/
  governance; Security/Facility manager → visitor/security/staff; Super Admin → platform.
  The sidebar hides unpermitted modules, but **the backend re-authorizes every request**
  (`canManageFunds`, `canManageContent`, `superAdminOnly`, tenant middleware) — hide-only is
  never the security boundary.

## 5. Data & money invariants

- All amounts are integer **minor units (paise)** from the backend; formatted to ₹ only at the
  display edge via `formatMoneyMinor`. No floating-point rupee math.
- No local JSON, no random counters, no static cards — every widget is a live query. Demo data
  originates solely from `society-backend/scripts/seed_hubtown_sunkist*.js`.

## 6. Notable platform note

Node 24 on Windows throws `EISDIR` from `fs.readlink` on regular files, which aborts webpack
resolution during `next build`. A preload shim (`scripts/patch-readlink.cjs`, wired into the
`build` script) normalizes `EISDIR → EINVAL` so the build succeeds. It is a no-op on Linux/AWS.
