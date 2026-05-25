# Security Audit
**Date:** May 25, 2026  
**Scope:** Identity Management, Secrets Auditing, and Backend Access Controls  
**Mode:** Analysis Only

---

## 1. Secrets Management & Repository Credentials Exposure

### Current State
The backend contains a committed file `society-backend/config/serviceAccountKey.json` which holds full Firebase private keys. It also lists an `.env` file containing local configurations and JWT secrets in the workspace directory.

### What is Good
- The Firebase initialization code in `config/firebase.js` is built to prioritize loaded environment variables (`FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) over the local file, indicating that production is designed to run securely.

### What is Missing
- **Vulnerable Git History:** The private Firebase service account key is committed in the active git repository. Anyone with access to the source code repository or any history backups has full root access to the Firestore collections and user databases.

### What Can Break
- **Credential Theft:** Attackers accessing the codebase can extract the service account credentials and programmatically delete, read, or modify all resident databases, chats, and ledger records.

### Real-World Risk
- **Critical:** Full administrative takeover of the Firebase cluster, data leakage, and potential ransomware threats.

### Priority
- **P0** (Must fix before Play Store launch or public staging)

### Recommended Fix
1. **Immediate Revocation:** Go to the Firebase Developer Console, navigate to Project Settings -> Service Accounts, and revoke the compromised key. Generate a new key.
2. **Remove Secrets from Git:** Delete `serviceAccountKey.json` from the codebase, add it to `.gitignore`, and rewrite git history using tools like `git-filter-repo` or `BFG Repo-Cleaner` to purge all traces of the old file from commits.
3. **Environment Setup:** Inject the new service account parameters purely as secure environment variables in the deployment dashboards (Railway/AWS/GCP).

### Files Affected
- `society-backend/config/serviceAccountKey.json`
- `society-backend/.gitignore`

---

## 2. Role Escalation & Self-Modification Protections

### Current State
The profile modification endpoint `PATCH /users/:uid` is protected by `authMiddleware`, `tenantMiddleware`, and `mainAdminOnly`.

### What is Good
- **Bulletproof Protection:** The endpoint uses a Firestore transaction to assert that a user cannot elevate their own role (`if (req.user.uid === req.params.uid) { throw new Error("Cannot change your own role."); }`).
- **Superadmin Safeguards:** It prevents standard main admins from elevating anyone to superadmin: `if (role === 'superadmin' && req.user.role !== 'superadmin') { throw new Error("Cannot assign superadmin role."); }`.

### What is Missing
- **Token Revocation Blacklist Sync:** While changing a user's role updates Firebase Custom Claims and deletes their active refresh tokens in Firestore, the active JWT access token is not immediately blacklisted in Redis.

### What Can Break
- **Lagging Permissions Enforcement:** When an admin downgrades or rejects a user, that user's existing JWT token remains cryptographically valid for up to 1 hour (the JWT expiration time) unless the app restarts. They can still call protected APIs during this timeframe.

### Real-World Risk
- **High:** A rejected or downgraded resident can still read notices, fetch ledger summaries, or view visitor approvals for up to an hour after being removed.

### Priority
- **P1** (Must fix before pilot)

### Recommended Fix
- When updating a user's role or status in `PATCH /users/:uid`, generate a short-lived Redis blacklist entry containing the user's UID and token hash (using the JWT's expiration duration as TTL) and verify this blacklist within `authMiddleware` on every incoming API call.

### Files Affected
- `society-backend/routes/users.js`
- `society-backend/middleware/auth.js`

---

## 3. Row-Level Security (RLS) & Vector Store Isolation

### Current State
The PostgreSQL database utilizes a Knex migration `20260525195400_enable_rls.js` that enables Row-Level Security on `document_chunks`, `ai_audit_logs`, and `ai_costs` tables. The database pool wrapper in `Database.ts` intercepts all queries and injects `SELECT set_config('app.current_tenant', $1, false)` using `AsyncLocalStorage` context.

### What is Good
- **Defense in Depth:** Even if a developer forgets to apply tenant scopes in an Express controller, the Postgres database engine itself will automatically reject vector chunks or audit logs belonging to a different `society_id` because the active session tenant config filters the dataset.
- This is a state-of-the-art multi-tenant security implementation.

### What is Missing
- **Superadmin RLS Bypass Policy:** The current RLS policies do not explicitly check if the executing database session role is a superadmin or running migrations, which can block global stats collection or data indexing tasks.

### What Can Break
- **Migration & Aggregation Failures:** Global cron jobs or migration scripts running without a specific `societyId` context might fail or return empty datasets because the default RLS policy restricts queries when `app.current_tenant` is unset.

### Real-World Risk
- **Medium:** Operational failures in backend aggregation scripts, vector indexing, or database schema migrations.

### Priority
- **P2** (Fix after pilot launch)

### Recommended Fix
- Update PostgreSQL RLS policies to check if the session user is a superadmin database role or if a bypass setting is enabled:
  ```sql
  CREATE POLICY tenant_isolation_policy ON document_chunks 
  USING (current_setting('app.current_tenant', true) = society_id OR current_user = 'postgres');
  ```

### Files Affected
- `society-backend/migrations/20260525195400_enable_rls.js`
- `society-backend/src/shared/Database.ts`
