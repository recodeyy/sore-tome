# Database & Data Model Audit
**Date:** May 25, 2026  
**Scope:** Firestore NoSQL, PostgreSQL Relational Schemas, and DB Indexing  
**Mode:** Analysis Only

---

## 1. Firestore Schema & Security Rules Integrity

### Current State
Firestore stores user collections, ledger transactions, noticeboards, and chat channel messages. Database security rules are defined in `firestore.rules` and enforce multi-tenancy checking via `isSameSociety()` comparing claims (`request.auth.token.society_id`).

### What is Good
- **Immutability of Transactions:** The transaction rules are extremely secure:
  ```javascript
  match /transactions/{docId} {
    allow read: if isAuthenticated() && isSameSociety(resource.data);
    allow create: if isAuthenticated() && isSameSociety(request.resource.data) && (request.auth.token.role in ['main_admin', 'treasurer'] || request.auth.token.role == 'superadmin');
    allow update, delete: if false;
  }
  ```
  This guarantees that financial history cannot be modified or deleted by anyone once committed.
- Sub-collections inherit tenant isolation perfectly.

### What is Missing
- **Soft Delete for Audits:** While transactions are immutable, other entities like `notices` or `issues` can be deleted entirely, which erases historical evidence for committee actions.

### What Can Break
- **Silent Data Loss:** If a compromised admin deletes rule channels or notices, there is no backup history in Firestore, and the society suffers data loss.

### Real-World Risk
- **Medium:** Loss of historical records or operational data tampering due to lack of soft deletes on non-ledger entities.

### Priority
- **P2** (Should fix after pilot launch)

### Recommended Fix
- Enforce soft delete patterns at the application level on `/routes/notices` and `/routes/issues` by setting `deletedAt` and `isDeleted: true` flags instead of firing raw Firestore `.delete()` actions. Update query filters to exclude soft-deleted documents.

### Files Affected
- `society-backend/routes/notices.js`
- `society-backend/routes/issues.js`
- `society-backend/firestore.rules`

---

## 2. PostgreSQL Vector Storage & Schema Scaling

### Current State
PostgreSQL stores `document_chunks` (using `pgvector` for RAG embeddings), `ai_audit_logs`, and `ai_costs`. Tables are partitioned and indexes are managed via Knex migrations.

### What is Good
- pgvector indexing handles search operations efficiently on high-dimensional vectors.
- RLS policies are enabled on all active tables based on `app.current_tenant`.

### What is Missing
- **Foreign Key Integration:** Users and flat relationships are managed entirely in Firestore. There is no mapping in PostgreSQL, which makes it impossible to perform relational vector search constraints based on user data.

### What Can Break
- **Relational Desync:** If a user is deleted or changes societies in Firestore, their corresponding AI logs and vector uploads remain floating in PostgreSQL without active constraints, creating orphan records.

### Real-World Risk
- **Low:** minor database overhead and data leakage of orphan logs, which remain unassigned to active societies.

### Priority
- **P3** (Future improvement)

### Recommended Fix
- Build a user sync webhook or background queue that automatically mirrors basic tenant user mappings (UID, role, society_id) to a PostgreSQL mirror table (`users`) to enforce foreign key constraints on RAG audit logs.

### Files Affected
- `society-backend/src/shared/Database.ts`
- PostgreSQL Migrations

---

## 3. Database Indexes & Query Bottlenecks

### Current State
Firestore indexes are registered in `firestore.indexes.json`. PostgreSQL utilizes B-Tree indexes on `society_id` and custom index types for vector distances.

### What is Good
- Key queries in Firestore (e.g., fetching notices, transactions, and visitors filtered by `society_id` and sorted by `createdAt`) are pre-indexed, preventing "Missing Index" query failures at runtime.

### What is Missing
- **Query Performance Observability:** While slow queries are logged in `Database.ts` when they exceed 500ms, there is no automated telemetry tool (e.g., pg_stat_statements) configured to analyze database query execution plans.

### What Can Break
- **Slow Down at Scale:** As vector chunks grow into hundreds of thousands of records, searching vectors without strict index updates will cause CPU spikes and slow down the AI assistant response times significantly.

### Real-World Risk
- **Medium:** Degraded AI response performance as the resident population scales.

### Priority
- **P2** (Fix after pilot launch)

### Recommended Fix
- Enable `pg_stat_statements` on the PostgreSQL instance. Monitor indexing performance and tune vector index lists (e.g., using IVF-Flat or HNSW index types) once document volumes exceed 50,000 vectors.

### Files Affected
- `society-backend/firestore.indexes.json`
- `society-backend/src/shared/Database.ts`
