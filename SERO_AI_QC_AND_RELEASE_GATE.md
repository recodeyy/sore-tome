# SERO AI QC and Release Gate

**Date:** 2026-06-16
**Author:** QA Director / Release Manager

This document defines the strict quality check (QC) and release gate criteria for all AI components in SERO.

## 1. Release Quality Gates (P0/P1 Criteria)
A release containing AI components will immediately fail the release gate if any of the following occur:
- **Tenant Leakage:** Any RAG query or analytical calculation that retrieves data from a different `society_id`.
- **Mock Flag On:** `dev_config.dart` has `kUseMockData = true`.
- **Autonomous Write:** AI triggering money movements or user suspensions without explicit user approval.
- **Test Failures:** Any of the 4 integration AI test suites failing (`ai_chat`, `ai_innovation`, `ai_multilingual`, `ai_tool_authorization`).

## 2. Pre-release Validation Checklist
1. Verify `dev_config.dart` has `kUseMockData = false`.
2. Run `npm test` inside `society-backend/` and verify all tests pass.
3. Validate API response envelope shape matches `{ success: true, data: [...] }`.
4. Ensure explanation disclaimers are visible on all AI screens.
