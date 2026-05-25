# Production Readiness Audit
**Date:** May 25, 2026  
**Scope:** Core Architecture, System Scalability, and Concurrency Auditing  
**Mode:** Analysis Only

---

## 1. Core Architecture & Stack Integrity

### Current State
The backend operates as a Node.js/Express application utilizing a polyglot database layer: Firebase Firestore manages real-time chat, notifications, and transactions, while PostgreSQL (accessed via a raw `pg` pool in `Database.ts`) stores embeddings and vector data for RAG document chunking. Redis is leveraged as a rate limiter, semantic cache, and session store.

### What is Good
- Decoupling real-time features (chat channels) using Firestore streams keeps Express servers lightweight.
- PostgreSQL `pg` pool has automated heartbeats and wrapper overrides that automatically inject tenant contexts in all queries.
- Redis acts as a fast rate-limiter and semantic cache to prevent costly LLM over-indexing.

### What is Missing
- **TypeScript Migration Incompletion:** The backend contains mixed JS and TS files. TS routes are compiled using `tsx` on the fly, while core routers like `/routes/users.js` and `/routes/funds.js` remain written in JavaScript.
- **Unified Error Serialization:** Runtime exceptions in JS files are handled via basic Express `res.status(500).json({ error: err.message })` blocks rather than a standardized structural response pattern.

### What Can Break
- **Type Mismatches:** Sending missing fields from the Flutter client will cause runtime exceptions (e.g., trying to execute `.replace()` on undefined fields) because the JS endpoints lack static compilation checks.

### Real-World Risk
- **High:** Backend runtime crashes, leading to random 500 errors experienced by real residents, especially on payload boundaries.

### Priority
- **P1** (Must fix before pilot launch)

### Recommended Fix
- Complete the TypeScript migration by converting all `.js` files in `/routes` and `/middleware` to `.ts`. Define strict payload interfaces validated via Zod at compile time.

### Files Affected
- All files in `society-backend/routes/*.js`
- All files in `society-backend/middleware/*.js`

---

## 2. Financial Ledger Concurrency & ACID Compliance

### Current State
The backend endpoints (`POST /funds/transactions`, `/payments/verify`, and `/payments/webhook`) utilize Firestore transactions (`db.runTransaction()`) to record ledger items. It atomically increments balances and totals inside a `society_funds_summary` collection.

### What is Good
- Using `db.runTransaction()` is excellent because it guarantees ACID compliance on concurrent ledger updates (e.g., multiple residents paying maintenance at the same time).
- Razorpay webhook verifications are idempotent; event IDs are logged inside a transactional check in a `processed_webhooks` collection to prevent double credits.

### What is Missing
- **PostgreSQL Ledger Partitioning:** While Firestore has transaction controls, the long-term historical ledger scales poorly in Firestore since querying years of double-entry data is highly expensive.

### What Can Break
- **Firestore Hotspots:** Firestore document updates are rate-limited to 1 write per second per document. If thousands of residents attempt to pay maintenance during the same hour, `runTransaction()` will throw contention errors and fail, causing client-side timeouts.

### Real-World Risk
- **Medium:** Transaction dropouts and UI load failures under high concurrent user billing peaks.

### Priority
- **P2** (Should fix after MVP launch)

### Recommended Fix
- Keep transactional logs in Firestore for the immediate MVP, but prepare a schema migration strategy to move accounting ledgers to the PostgreSQL database, where standard relational locks handle high write volume natively.

### Files Affected
- `society-backend/routes/funds.js`
- `society-backend/firestore.rules`

---

## 3. Polyglot Database Load & Pool Management

### Current State
The Raw PostgreSQL pool in `src/shared/Database.ts` hardcodes `max: 10` connections with a keep-alive periodic heartbeat.

### What is Good
- Establishing periodic heartbeats every 60 seconds ensures stale connections are cleaned and the singleton instance is maintained.

### What is Missing
- **Connection Pooling Broker:** There is no intermediate proxy (e.g., PgBouncer) deployed between Node.js and PostgreSQL.
- **Redis Outage Circuit Breaker:** There is a custom `CircuitBreaker.ts` and `LockService.ts`, but if Redis drops, endpoints that rely on rate limiting might fail or default to throwing generic 500 crashes instead of falling back gracefully.

### What Can Break
- **Database Connection Starvation:** As the Express backend scales horizontally to multiple runtime containers (e.g., under Railway or Google Cloud Run autoscaling), the number of concurrent Postgres connections will multiply. If it exceeds the database instance's hard ceiling, the database will refuse new client setups.

### Real-World Risk
- **High:** Complete database lockouts and app outage under sudden traffic spikes.

### Priority
- **P1** (Must resolve before scaling beyond 1 pilot society)

### Recommended Fix
- Set up PgBouncer in transaction mode as an intermediary. Modify `DATABASE_URL` in `.env` to point to the PgBouncer port. Enforce low-overhead fallback strategies inside `Redis.ts` so that if Redis disconnects, the rate limiter falls back to an in-memory storage buffer.

### Files Affected
- `society-backend/src/shared/Database.ts`
- `society-backend/src/shared/Redis.ts`
