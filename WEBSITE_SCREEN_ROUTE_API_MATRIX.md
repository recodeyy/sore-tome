# SERO Admin Web — Screen / Route / API Matrix

All backend paths are under `http://<backend>/api/v1` and are reached from the browser via the
BFF proxy `GET|POST|… /api/proxy/<backend-path>` (auth attached server-side). Money in minor units.

## Auth / session (BFF)

| Web action | BFF route | Backend | Notes |
|---|---|---|---|
| Login | `POST /api/session/login` | `POST /auth/login` | portals `admin`, `super-admin`; sets httpOnly cookies |
| Logout | `POST /api/session/logout` | `POST /auth/logout` | revokes refresh token |
| Session check | `GET /api/session/me` | — | reads cookie |
| Token refresh | (auto in proxy) | `POST /auth/refresh` | rotates on 401 |

## Society Admin portal

| Screen (route) | Reads | Writes | Min role |
|---|---|---|---|
| Dashboard `/dashboard` | `admin/dashboard/summary`, `/alerts`, `/activity`, `finance/reports/dues` | — | admin/committee |
| Members `/members` | `members-v2` | (import/transition via backend) | admin |
| Billing `/billing` | `finance/invoices`, `members-v2` | `POST finance/invoices`, `…/:id/publish`, `POST finance/payments` | main_admin/treasurer |
| Payments `/payments` | `finance/reports/summary`, `finance/receipts` | — (Razorpay via webhook) | main_admin/treasurer |
| Reconciliation `/reconciliation` | `finance/reconciliation/imports/:id/summary` | `POST …/accounts`, `…/imports`, `…/imports/:id/auto-match` | main_admin/treasurer |
| Expenses `/expenses` | `finance/expenses` | `POST finance/expenses` (`/:id/decision`) | main_admin/treasurer |
| Reports `/reports` | `finance/reports/summary`, `/dues`, `/trial-balance` | CSV/PDF export (client) | main_admin/treasurer |
| Notices `/notices` | `notices-v2` | `POST notices-v2`, `…/:id/publish` | secretary/admin |
| Polls & AGM `/polls` | `polls-v2`, `…/:id/results` | `POST polls-v2`, `…/:id/open`, `…/:id/close` | secretary/admin |
| Events `/events` | `events-v2` | (`POST events-v2`, rsvp on backend) | secretary/admin |
| Complaints `/complaints` | `complaints`, `staff-v2` | `POST complaints/:id/assign`, `PATCH …/:id/status` | admin/committee |
| Staff `/staff` | `staff-v2` | (roster/payroll on backend) | security/facility mgr |
| Visitors `/visitors` | `guard/visitors` | (guard actions from app update live) | security mgr |
| Parking `/parking` | `parking/slots` | (allocations on backend) | security/facility mgr |
| Assets `/assets` | `assets` | (work-orders on backend) | admin |
| AI `/ai` + floating | `POST /api/ai/chat` → `ai/chat` (or Groq direct) | tool proposals require confirm | role-scoped |
| Settings `/settings` | `society/profile`, `society/setup-progress` | `PUT society/profile` | admin |

## Super Admin portal

| Screen (route) | Reads | Writes | Role |
|---|---|---|---|
| Platform Dashboard `/super-admin/dashboard` | `super-admin/dashboard` | — | super_admin |
| Societies `/super-admin/societies` | `super-admin/societies` | approve/suspend on backend | super_admin |
| Approvals `/super-admin/applications` | `super-admin/applications` | `POST …/applications/:id/review` | super_admin |
| Revenue `/super-admin/revenue` | `super-admin/revenue` | — | super_admin |
| Support `/super-admin/support` | `super-admin/support/tickets` | assign/resolve on backend | super_admin |
| Announcements `/super-admin/announcements` | `super-admin/announcements` | `POST super-admin/announcements` | super_admin |
| System Health `/super-admin/health` | `super-admin/system-health` | — | super_admin |
| Audit Logs `/super-admin/audit` | `super-admin/audit-logs` | CSV export (client) | super_admin |

## AI / Voice proxies

| BFF route | Upstream | Key location |
|---|---|---|
| `POST /api/ai/chat` | backend `ai/chat` (mode=backend) **or** Groq `chat/completions` (mode=direct) | server env only |
| `POST /api/voice/tts` | ElevenLabs `text-to-speech/{voiceId}` | server env only |

## Exports (generated client-side from live query results)

Members CSV · Invoices CSV/PDF · Payment collection CSV · Defaulter report CSV/PDF · Complaint
SLA CSV · Visitor register CSV · Staff register CSV/PDF · Parking allocation CSV/PDF · Notices
CSV · Societies CSV · Audit logs CSV. (For very large exports, use the backend `reports/jobs`
background-job endpoints — documented, not yet wired to a download link.)
