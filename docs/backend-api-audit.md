# Backend API Audit
**Date:** May 25, 2026  
**Scope:** Express Routing, Endpoint Validations, and Security Middlewares  
**Mode:** Analysis Only

---

## 1. Global Route Protection & Tenant Enforcement

### Current State
Backend endpoints are mounted under `v1Router` in `server.js`. A global middleware runs immediately after `/auth` routes to authenticate requests and inject tenant contexts using both `authMiddleware` and `tenantMiddleware` for all sub-routers (e.g. `/users`, `/notices`, `/funds`, etc.).

### What is Good
- **Bulletproof Default Security:** The routing architecture enforces authentication and tenant isolation at the router mounting level rather than relying on developers to manually place middleware variables on every individual controller. This completely mitigates typical IDOR (Insecure Direct Object Reference) leaks.
- Excluded routes (like `/auth/login`, `/auth/register`) are restricted to public access safely.

### What is Missing
- **Route Whitelist Overrides:** The routing configuration in `server.js` hardcodes custom route bypass exclusions as string-matching path checks (`path === "/users/register" || path === "/users/me"`). This is error-prone.

### What Can Break
- **Exclusion Bypass:** If a new public path is added and the developer typos the string matching block or forgets to add it, standard authenticated users will not be able to register, or conversely, public paths could accidentally run tenant checks before login.

### Real-World Risk
- **Medium:** Operational friction and registration blockages if whitelists are misconfigured during new endpoint rollouts.

### Priority
- **P2** (Should fix after pilot launch)

### Recommended Fix
- Refactor the global router interceptor to use an array of structured regex matches or custom configuration maps to declare public, authenticated-only, and tenant-isolated endpoints clearly.

### Files Affected
- `society-backend/server.js`

---

## 2. Input Validation & Zod Schema Enforcement

### Current State
Routes use a `validate()` middleware (defined in `middleware/validate.js`) mapped to schemas imported from `src/shared/schemas.ts` (e.g., `RegisterSchema`, `LoginSchema`, `CreateTransactionSchema`).

### What is Good
- **Strict Data Sanitization:** Implementing schema validation at the router level ensures invalid datatypes, malformed inputs, or SQL injection vectors are caught and rejected *before* they reach database handlers or services.
- Clean validation error reports (detailing missing fields) are returned to the client.

### What is Missing
- **Sanitization of Deep Nested Payloads:** While schemas are validated, nested JSON payloads in rich AI contexts or complex ledger adjustments are not fully mapped to deep Zod schemas.

### What Can Break
- **Type Casting Errors:** Unexpected properties or invalid parameter structures inside non-validated fields can slip through, causing PostgreSQL queries to fail with casting errors or causing Firestore to store corrupt data types.

### Real-World Risk
- **Low:** Minor database schema pollution or unhandled 500 error responses on custom parameters.

### Priority
- **P3** (Future improvement)

### Recommended Fix
- Audit all remaining endpoints (e.g., Rules, Events, Polls) and ensure that every route has a matching Zod schema validator configured.

### Files Affected
- `society-backend/src/shared/schemas.ts`
- All files in `society-backend/routes/`

---

## 3. Rate Limiting & Denial of Service Protection

### Current State
`server.js` configures dedicated rate-limiters using `express-rate-limit`:
- `standardLimiter`: 100 requests per 15 minutes.
- `authLimiter`: 5 requests per 15 minutes for `/auth/login` and `/auth/register`.
- `aiLimiter`: 10 requests per minute for `/ai`.

### What is Good
- Standard rate limit settings are robust and prevent API flooding or brute force attempts on login/signup channels.
- `app.set("trust proxy", 1)` is enabled, ensuring IP sensing works correctly behind cloud load balancers.

### What is Missing
- **Distributed Rate Limiting:** The current configuration is stored in Express memory. If multiple Express instances run concurrently, memory limits are partitioned, making it easier for a coordinated attack to bypass restrictions.

### What Can Break
- **Memory Overhead & Limits Abuse:** High traffic or brute-force scripts hitting distinct nodes will reset limiters, letting attackers bypass the 5-attempt boundary on auth endpoints.

### Real-World Risk
- **Medium:** Brute force authentication cracking or AI API billing spikes if the memory-based limiters are circumvented.

### Priority
- **P2** (Fix after pilot launch)

### Recommended Fix
- Configure `express-rate-limit` to use a Redis store backend (leveraging the already existing Redis connection in the project) so that rate limit states are synchronized globally across all runtime containers.

### Files Affected
- `society-backend/server.js`
- `society-backend/package.json`
