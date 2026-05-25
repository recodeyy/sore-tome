# Multi-Tenant Isolation Audit
**Date:** May 25, 2026  
**Scope:** Multi-Society Isolation, Tenant Isolation Boundaries, and Data Leakage Vectors  
**Mode:** Analysis Only

---

## 1. Tenant Scoping at the Gateway Routing Layer

### Current State
The backend implements multi-tenant isolation by extracting `society_id` from the authenticated user's JWT inside the global `tenantMiddleware.ts` and injecting it as `req.societyId` for downstream handlers.

### What is Good
- **Zero Bypass Risk:** Since `tenantMiddleware.ts` runs globally for all versioned routes mounted under `/api/v1` (with specific paths explicitly bypassed), developers are blocked from writing endpoints that accidentally expose data cross-society.
- Tenant identity is cryptographically tied to the JWT claims created by `/auth/login` and cannot be altered by modifying HTTP header parameters or request body parameters.

### What is Missing
- **Tenant Context Verification:** There is no check to verify if a user's society registration has been disabled or if the society itself has been suspended at the gateway layer.

### What Can Break
- **Suspended Tenant Access:** If a society's subscription expires or is suspended by a superadmin, residents and admins can still call API routes and perform mutations because the token is verified cryptographically without checking real-time tenant status in the DB.

### Real-World Risk
- **Medium:** Loss of billing enforcement capabilities and business operations risk where suspended societies continue using free services.

### Priority
- **P1** (Must fix before beta launch)

### Recommended Fix
- Implement a quick cache-lookup step inside `tenantMiddleware.ts` (using Redis) to check if the `societyId` is in an active, approved state. If the tenant status is "suspended" or "expired", reject the request with a 403 Forbidden response.

### Files Affected
- `society-backend/middleware/tenantMiddleware.ts`

---

## 2. NoSQL Multi-Tenant Security & Firestore Isolation

### Current State
Firestore uses custom security rules matching the token's society ID (`request.auth.token.society_id`).

### What is Good
- **Database Enforcement:** Even if a bug in the Express app queries without the `where("society_id", "==", req.societyId)` filter, Firebase itself will block the query and throw an error because the request payload doesn't match the strict security rules. This is a very strong defense.

### What is Missing
- **Admin Cross-Society Action Limits:** Standard society admins have a role of `main_admin` or `treasurer`. If a standard admin makes a direct Firebase SDK request bypassing the backend, rules allow write access to any document as long as they match the `society_id`.

### What Can Break
- **Database Impersonation:** While standard residents are locked, standard society admins possess significant control within their tenant boundary. If their private API keys are compromised, they can execute bulk database deletions or modifications within their own tenant.

### Real-World Risk
- **Medium:** Risk of data corruption or sabotage inside a society if an admin's account is compromised.

### Priority
- **P2** (Should fix after pilot launch)

### Recommended Fix
- Keep Firebase database rules strict. Require multi-factor authentication (MFA) for administrative credentials. Log all admin edits in a tamper-proof audit log inside Postgres.

### Files Affected
- `society-backend/firestore.rules`

---

## 3. SQL Data Isolation & PostgreSQL RLS Policies

### Current State
PostgreSQL isolates data by enabling Row-Level Security (RLS) policies on `document_chunks` and `ai_audit_logs`. The connection pool wrapper override in `Database.ts` executes `set_config('app.current_tenant', $1, false)` using `AsyncLocalStorage` tenant contexts.

### What is Good
- **Cryptographically Isolated Vector Store:** This prevents the AI model from fetching legal notices or rulebook vectors from Society B and sharing them with a resident in Society A, eliminating the primary multi-tenant security concern of RAG (Retrieval-Augmented Generation) applications.

### What is Missing
- **Bypass Safety Assertions:** There are no automated regression unit tests that attempt to execute database queries with a mismatched tenant context to ensure that RLS policies reject them.

### What Can Break
- **Silent Misconfiguration:** If a developer alters the database migrations or drops policies by mistake, there is no automated build step that will catch the isolation failure, leading to a silent security regression.

### Real-World Risk
- **High:** Critical data leaks of private society rulebooks, complaints, and visitor logs across societies.

### Priority
- **P1** (Must verify with tests before pilot launch)

### Recommended Fix
- Add explicit integration test cases in the Jest suite (`__tests__`) that:
  1. Set a tenant context for Society A.
  2. Attempt to query or write records belonging to Society B.
  3. Assert that PostgreSQL throws an isolation violation error.

### Files Affected
- `society-backend/__tests__/rls.test.js` (Create this test)
- `society-backend/src/shared/Database.ts`
