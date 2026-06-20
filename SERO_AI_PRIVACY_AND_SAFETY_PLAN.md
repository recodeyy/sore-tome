# SERO AI Privacy and Safety Plan

**Date:** 2026-06-16
**Author:** Chief AI Product Officer / Privacy Engineer

This plan defines the security and safety guardrails applied to all SERO AI models.

## 1. Safety Tiers
- **Read-Only Insights:** Analytics indicators (e.g., collection efficiency, MTBF trends) require no confirmation.
- **Low-Risk Suggestions:** Suggestions that can be dismissed (e.g., optional work order rescheduling).
- **Medium-Risk Proposals:** Proposals that show detailed impact summaries before confirmation.
- **High-Risk Actions:** All payments, ledger entries, access list edits, and KYC approvals are blocked from autonomous execution and must be explicitly approved via step-up MFA challenge.

## 2. Privacy Safeguards
- **Data Minimization:** No personal phone numbers or email addresses are passed to LLM prompts.
- **Database Context Enforcement:** Queries are run using a connection context scoped strictly to the current tenant's `society_id` via PostgreSQL RLS policies.
- **Explainability Center:** Residents can view active algorithms, data sources used, and opt out of matching features.
