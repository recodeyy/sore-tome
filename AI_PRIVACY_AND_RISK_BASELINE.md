# AI Privacy and Risk Baseline

**Date:** 2026-06-16
**Privacy Engineer:** Chief AI Product Officer

This document establishes the privacy and security risk baseline for all AI algorithms in SERO.

## 1. Core Invariants & Boundaries
- **Cross-Society Data Sharing:** Strict **NO** policy. Models and data embeddings are isolated using Row-Level Security (RLS) based on the active `society_id` tenant parameter.
- **Autonomous Write Operations:** High-risk actions (e.g., money movements, account suspensions, invoice edits) are programmatically blocked from autonomous execution. They **must** route through a human-in-the-loop confirmation workflow.
- **Data Minimization:** AI endpoints only query fields necessary to compute the specific insight. No scanning of private resident message boards or camera feeds is permitted.
- **Surveillance Prohibitions:** No hidden behavioral tracking or employee performance ranking is allowed.

## 2. Risk Matrix

| Risk Scenario | Likelihood | Impact | Mitigation Plan |
|---|---|---|---|
| **Cross-tenant Data Leakage** | Low | Critical | Strict RLS verification via database unit tests (`rls_isolation.integration.test.ts`). |
| **Model Hallucination / Bad Alert** | Medium | Medium | Include confidence score indicators in UI; add explicit disclaimer that recommendations require human review. |
| **AI Action Hijacking (Prompt Injection)** | Medium | High | Inputs sanitized using strict system instructions and role-gated API endpoints. |
| **Exposure of PII in Embeddings** | Low | High | Strip emails, phone numbers, and resident names from RAG vector indexes before generation. |
