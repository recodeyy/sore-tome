# Home-S / Sore-Tome (Society Management App)
Welcome to the housing society management application for Indian residential communities, designed for residents, committee admins, and security guards. This repository is split into two core workspaces:
- `/sero`: Flutter/Dart mobile application.
- `/society-backend`: Express/Node.js backend with hybrid databases (Firestore + PostgreSQL/pgvector + Redis).

---

## Repository Documentation Index
Core architectural documentation, startup plans, and internal notes:
- `PROJECT_DOCUMENTATION.md`: System-wide specifications and deployment plans.
- `society-app-updated-plan.md`: Refined system workflows and module mappings.
- `ai.md`: AI Agent Mesh integration guidelines.

---

## 🚀 Play Store Launch Audit Documents
A comprehensive security and production-readiness audit has been conducted. The full findings are stored in the `docs/` folder:
1. [Play Store Launch Analysis](docs/playstore-launch-analysis.md)
2. [Production Readiness Audit](docs/production-readiness-audit.md)
3. [Security Audit](docs/security-audit.md)
4. [Mobile App Audit](docs/mobile-app-audit.md)
5. [Backend API Audit](docs/backend-api-audit.md)
6. [Database Audit](docs/database-audit.md)
7. [Multi-Tenant Isolation Audit](docs/multi-tenant-isolation-audit.md)
8. [Privacy & Data Safety Audit](docs/privacy-data-safety-audit.md)
9. [QA Test Plan](docs/qa-test-plan.md)
10. [Launch Blockers & Risk Matrices](docs/launch-blockers.md)
11. [Staged Fix Roadmap](docs/fix-roadmap.md)
12. [Master Audit & Final Release Verdict](docs/final-launch-verdict.md)

---

## 📊 Google Play Store Launch Status
```
========================================================================
                      GOOGLE PLAY RELEASE CONSOLE AUDIT
========================================================================
Release Target: Internal Beta Track -> Public Release (Google Play Store)
Overall Grade:  72 / 100
Release Status: HOLD (PASS WITH CONDITIONS)
------------------------------------------------------------------------

CRITICAL P0 RELEASE BLOCKERS IDENTIFIED:
1. Security: Committed Firebase Cert Key File (serviceAccountKey.json)
2. Build Setup: Debug signing certificate configured for release builds.
3. Mobile Setup: Undeclared Android hardware permissions in Manifest.
4. Compliance: Missing In-App Resident Account Deletion flows.
5. Review Pipeline: Missing Mock credentials bypass for Play Reviewers.

IMMEDIATE ACTION STEPS:
1. Purge Git history to revoke and scrub Firebase private keys.
2. Setup key.properties encryption configs inside Gradle files.
3. Inject POST_NOTIFICATIONS, CAMERA, and RECORD_AUDIO permission hooks.
4. Implement a DELETE /users/me endpoint and settings button interface.
5. Add sandbox mock reviewer profiles in auth routing filters.

========================================================================
```
