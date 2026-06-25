# MASTER_PROMPT_FILE_INVENTORY

Audit date: 2026-06-16 · Auditor role: Principal Program Architect / QA Director
Repo root: `C:\Users\hardi\OneDrive\Desktop\Society management\sore-tome`

This inventory satisfies Master Prompt Sections 1, 2, and 16 (locate + confirm readable + record blockers).

## A. Canonical prompt packs present and readable (9/9)

| File | Lines | Readable | Notes |
|---|---|---|---|
| SERO_Backend_Complete_Prompt_Pack.md | 2026 | YES | Core backend pack |
| SERO_Separate_Role_Login_Master_Prompt.md | 1201 | YES | Auth / login portals |
| SERO_Super_Admin_Complete_Prompt_Pack.md | 3346 | YES | Super Admin (31 capabilities) |
| SERO_Staff_Complete_Prompt_Pack.md | 3308 | YES | Staff (32 capabilities) |
| SERO_Resident_Complete_Prompt_Pack.md | 3318 | YES | Resident (57 capabilities) |
| SERO_AI_Chatbot_Cross_Role_Complete_Prompt_Pack.md | 3714 | YES | AI copilot + cross-role |
| SERO_AI_Innovation_Unique_Features_Master_Prompt.md | 1129 | YES | AI strategy/innovation |
| SERO_Final_Whole_App_QC_Master_Prompt.md | 1907 | YES | Whole-app QC |
| SERO_10K_20K_Load_Test_Complete_Prompt_Pack.md | 1932 | YES | Scale/load |
| SERO_All_Prompts_Execution_Enforcement_Master_Prompt.md | 818 | YES | Master controller (this audit's spec) |

The master prompt states (line 87) that combined packs may duplicate individual prompts and that **individual prompt files are the canonical implementation source**. Since the individual files are absent (below), the packs are the only available canonical source — a precedence/coverage risk recorded as a blocker.

## B. Missing sources named by the master prompt — BLOCKERS

These are referenced in Master Prompt Section 1 but do **not** exist at repo root.

### B1. Missing individual prompt files (master designates these as canonical over packs)
| File | Status |
|---|---|
| SERO_Admin_Backend_Master_Prompt.md | MISSING |
| SERO_Backend_QC_Audit_Prompt.md | MISSING |
| SERO_Super_Admin_Frontend_Prompt.md | MISSING |
| SERO_Super_Admin_Backend_Prompt.md | MISSING |
| SERO_Super_Admin_QC_Prompt.md | MISSING |
| SERO_AI_Chatbot_Cross_Role_Frontend_Prompt.md | MISSING |
| SERO_AI_Chatbot_Cross_Role_Backend_Prompt.md | MISSING |
| SERO_AI_Chatbot_Cross_Role_QC_Prompt.md | MISSING |
| SERO_Staff_Frontend_Prompt.md | MISSING |
| SERO_Staff_Backend_Prompt.md | MISSING |
| SERO_Staff_QC_Prompt.md | MISSING |
| SERO_Resident_Frontend_Prompt.md | MISSING |
| SERO_Resident_Backend_Prompt.md | MISSING |
| SERO_Resident_QC_Prompt.md | MISSING |
| SERO_Frontend_10K_20K_Load_Test_Prompt.md | MISSING |
| SERO_Backend_10K_20K_Load_Test_Prompt.md | MISSING |

### B2. Missing product source files
| File | Status |
|---|---|
| SERO_Feature_List.pdf | MISSING |
| SERO - AI Powered Society Managemen.txt | MISSING |
| project-sero-master.zip | PRESENT (extracted repo assumed = `sero/` + `society-backend/`) |

## C. Blocker IDs (carried into MASTER_BLOCKER_REGISTER.md)
- **SRC-BLOCK-01**: 16 individual canonical prompt files missing. Coverage extracted from packs only; cannot prove pack==individual fidelity. Severity P2 (process).
- **SRC-BLOCK-02**: Product feature sources (PDF + TXT) missing. Authoritative feature counts (31/32/57) taken from packs, unverifiable against product source. Severity P2.

## D. Pre-existing audit artifacts found at root (context, not authoritative)
LOGIN_*, RESIDENT_*, AI_*, CROSS_ROLE_* markdown files and backend `QC_*`/`BACKEND_AUDIT.md` already exist from prior passes. They were treated as informational, not as proof.
