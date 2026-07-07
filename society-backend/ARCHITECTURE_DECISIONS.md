# SERO Backend — Architecture Decision Record

Decisions taken 2026-06-15 to guide phased implementation. These resolve conflicts between the prompt's mandates and the existing codebase.

## ADR-001 — Data store: Hybrid (Postgres for finance, Firestore for the rest)

**Decision.** PostgreSQL becomes the authoritative source of truth for **finance, billing, payments, invoices, and the double-entry ledger**. Firestore remains the store for **realtime/offline-friendly content** (notices, channels/messages, complaints, presence, events) so the mobile app keeps fast reads and **offline persistence on the phone**.

**Why.** Requirement is a fast, networked, offline-capable mobile app. Firestore's offline cache + realtime sync deliver that directly; rewriting everything to Postgres would lose it. But money must never be float/Firestore-eventual — finance moves to Postgres with `numeric` money, transactions, and (later) RLS.

**Implications.**
- New Postgres schema + migrations for finance (Phase 3).
- Firestore stays but its **security rules must enforce role-based authorization** (see ADR-002), and **privileged writes go through the API**, not the client.
- Outbox/event bridge between Postgres finance and any Firestore projection is deferred to a later phase.

## ADR-002 — Identity: Firebase Auth

**Decision.** Migrate API authentication to **verify Firebase ID tokens server-side**. Application profile/roles stay in our DB. Custom JWT/bcrypt path is retired after migration.

**Why.** Because the client keeps Firestore access (ADR-001), the phone already authenticates to Firestore via Firebase Auth, and `firestore.rules` already trust `request.auth.token`. The current custom-JWT API uses a *different* identity, so the Firestore rules can never be enforced as intended (audit P0/P1). One identity (Firebase) unifies API + Firestore + offline.

**Implications.**
- Server verifies `Authorization: Bearer <Firebase ID token>`; sets `req.user` from decoded token + DB membership.
- Roles published as Firebase **custom claims** (`society_id`, `role`) so rules and API agree.
- Flutter login flow updated to use Firebase Auth and send the ID token.
- Migration must be staged so the running app is not broken mid-flight.

## ADR-003 — Secrets: deferred (owner choice)

**Decision.** No git-history rewrite this session. Committed keys (`sero-73976-...json`, `config/serviceAccountKey.json`, `.env`) remain an **open P0**. Rotate keys in Firebase when ready, then purge history.

**Implications.** Do not add new secrets to git. `.env.example` is the only committed env template.

---

## Role model (canonical, to standardize on)

`super_admin`, `main_admin`, `admin`, `secretary`, `treasurer`, `committee_member`, `facility_manager`, `security_manager`, `guard`, `staff`, `resident_owner`, `resident_tenant`, `auditor`.

Legacy code uses `superadmin`/`resident`; these map to `super_admin`/`resident_owner` during the RBAC migration (Phase 1/2).
