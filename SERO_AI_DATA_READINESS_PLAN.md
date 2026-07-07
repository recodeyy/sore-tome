# SERO AI Data Readiness Plan

**Date:** 2026-06-16
**Author:** Chief AI Product Officer

This document details the data preparation, minimum datasets, and schema migration plans to support SERO's AI.

## 1. Minimum Viable Dataset (MVD)
AI features degrade gracefully if database tables are empty. The MVD required for full model operation:
- **Complaints:** At least 3 distinct records within 14 days in the same category to trigger clustering.
- **Expenses:** History of at least 5 transactions in a category to detect spikes (> 2x category average).
- **Assets:** Asset age metadata and a minimum of 1 historical completed work order to calculate risk.

## 2. Cold-Start Mitigation
When a new society registers:
- The autopilot uses platform-wide average benchmarks (e.g., standard SLA parameters) as defaults.
- UI components degrade to empty states (with explanations of required data depth) instead of throwing errors.
