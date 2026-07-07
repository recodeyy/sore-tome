# SERO Admin Web — Security Report

## Authentication & session
- Login proxies backend `/auth/login`; the backend enforces lockout, progressive delay, and a
  **5-login / 15-min** rate limiter (observed live).
- Access + refresh tokens are stored in **httpOnly, SameSite=Lax** cookies — **unreadable by JS**,
  mitigating token theft via XSS. `Secure` is set automatically in production.
- Silent refresh: the proxy rotates the refresh token once on `401` and retries.
- Logout revokes the refresh token server-side and clears cookies.

## Authorization (backend is the authority)
- Role-based sidebar hides unpermitted modules, but **every** backend call is re-authorized by
  `authMiddleware`, `tenantMiddleware`, and role guards (`canManageFunds`, `canManageContent`,
  `superAdminOnly`). Hide-only is never the security boundary.
- **Verified**: an unauthenticated request to `/api/proxy/finance/invoices` returns **401**.
- **Tenant isolation**: tokens are society-scoped; the web app never sends a society id the token
  doesn't carry, and the backend rejects cross-tenant access.

## Secrets / no keys in browser
- AI and voice keys are read only from **non-`NEXT_PUBLIC_` server env**; they exist solely inside
  Next.js route handlers. Confirmed no key path reaches the client bundle.
- `.env.local` is git-ignored; only `.env.example` (placeholders) is committed. AWS uses Secrets
  Manager / SSM (see deployment plan).

## Transport / headers / CORS
- `next.config.mjs` emits `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: microphone=(self)`.
- Same-origin BFF design means the browser never issues cross-origin calls to the backend or
  providers — reduces CORS surface. Backend CORS + Helmet remain in force.

## AI / voice safety
- **Prompt-injection**: the assistant only *proposes*; writes traverse authorized endpoints, so a
  malicious prompt cannot exceed the user's RBAC.
- **High-impact confirmation**: destructive/expensive intents require an explicit confirm gate
  before execution (verified in UI logic).
- **Voice**: TTS requires an authenticated session (anonymous → 401); audio is not stored.

## Payments
- No simulated success — online payments confirmed only by backend/Razorpay **webhook** status;
  manual entries carry an idempotency key and are audited. Payment totals reconcile to the ledger
  (trial balance balanced).

## MFA / impersonation (P2/P3)
- Super-admin **MFA** and **impersonation-with-audit** are backend capabilities
  (`super-admin/impersonation/*`, audit logs). The web exposes audit logs today; enabling the MFA
  challenge screen + impersonation UI is a P2 item. No P0/P1 security gate is open.

## Automatic-fail checklist (Section 16) — status
| Fail condition | Status |
|---|---|
| Page uses fake data | **None** — all live |
| Admin action doesn't update app | **Refuted** — shared-DB read-back verified |
| Exports not live | **Refuted** — exports serialize live rows |
| AI accesses unauthorized data | **Prevented** — backend authz + no key in browser |
| Voice acts without confirmation | **Prevented** — confirm gate |
| Payment report mismatches ledger | **Refuted** — trial balance balanced |
| Tenant isolation fails | **Prevented** — token-scoped + 401 verified |
| Website cannot deploy | **Refuted** — build passes, AWS plan ready |
