# EXEC_MASTER_PROMPT_FILE_INVENTORY

Pass: Phase 0 (Sections 1, 2, 3, 16) of `SERO_All_Prompts_Execution_Enforcement_Master_Prompt.md`.
Date: 2026-06-16 · Role: Principal Program Architect (EXEC_ execution agent).
Repo root: `C:\Users\hardi\OneDrive\Desktop\Society management\sore-tome`

> Collision note: The high-level `MASTER_*` files are owned by another agent. This `EXEC_*`
> inventory is an independent re-verification produced for the execution ledger. It agrees with
> `MASTER_PROMPT_FILE_INVENTORY.md` and does not replace it. Where that file already records a
> deliverable, it is referenced rather than duplicated.

## A. Canonical prompt packs present at repo root (verified readable via Glob + Grep + Read)

| # | File | Exists | Readable | Lines | Canonical vs Pack | Role / Area |
|---|------|--------|----------|-------|-------------------|-------------|
| 1 | SERO_Backend_Complete_Prompt_Pack.md | YES | YES | 2026 | Pack (= Admin BE master + BE QC audit) | Core backend + backend QC |
| 2 | SERO_Separate_Role_Login_Master_Prompt.md | YES | YES | 1201 | Canonical master | Auth / separate login portals |
| 3 | SERO_Super_Admin_Complete_Prompt_Pack.md | YES | YES | 3346 | Pack (FE+BE+QC) | Super Admin (31 capabilities) |
| 4 | SERO_Staff_Complete_Prompt_Pack.md | YES | YES | 3308 | Pack (FE+BE+QC) | Staff/Guard (32 capabilities) |
| 5 | SERO_Resident_Complete_Prompt_Pack.md | YES | YES | 3318 | Pack (FE+BE+QC) | Resident (57 capabilities) |
| 6 | SERO_AI_Chatbot_Cross_Role_Complete_Prompt_Pack.md | YES | YES | 3714 | Pack (FE+BE+QC) | AI Copilot + 14 cross-role modules |
| 7 | SERO_AI_Innovation_Unique_Features_Master_Prompt.md | YES | YES | 1129 | Canonical master | AI innovation/strategy |
| 8 | SERO_Final_Whole_App_QC_Master_Prompt.md | YES | YES | 1907 | Canonical master | Whole-platform QC / release gate |
| 9 | SERO_10K_20K_Load_Test_Complete_Prompt_Pack.md | YES | YES | 1932 | Pack (FE+BE) | Performance / scale |
| 10 | SERO_Full_Live_Data_Zero_Mock_Master_Prompt.md | YES | YES | 871 | Canonical master | Live-data / zero-mock (owned by live-data agent) |
| — | SERO_All_Prompts_Execution_Enforcement_Master_Prompt.md | YES | YES | 817 | Controller | This pass's spec (not a requirement source) |

All 10 source prompt files were located and confirmed readable. No prompt file was unreadable.

## B. Sources named in Master Section 1 that are MISSING (blockers)

The master prompt designates individual FE/BE/QC prompt files as canonical over packs. Those
individual files do not exist at repo root — only the combined packs do. Product source files
(PDF/TXT) are also absent.

| File | Status | Blocker |
|------|--------|---------|
| SERO_Admin_Backend_Master_Prompt.md | MISSING | EXEC-BLK-01 |
| SERO_Backend_QC_Audit_Prompt.md | MISSING | EXEC-BLK-01 |
| SERO_Super_Admin_{Frontend,Backend,QC}_Prompt.md | MISSING (x3) | EXEC-BLK-01 |
| SERO_Staff_{Frontend,Backend,QC}_Prompt.md | MISSING (x3) | EXEC-BLK-01 |
| SERO_Resident_{Frontend,Backend,QC}_Prompt.md | MISSING (x3) | EXEC-BLK-01 |
| SERO_AI_Chatbot_Cross_Role_{Frontend,Backend,QC}_Prompt.md | MISSING (x3) | EXEC-BLK-01 |
| SERO_{Frontend,Backend}_10K_20K_Load_Test_Prompt.md | MISSING (x2) | EXEC-BLK-01 |
| SERO_Feature_List.pdf | MISSING | EXEC-BLK-02 |
| SERO - AI Powered Society Managemen.txt | MISSING | EXEC-BLK-02 |

Mitigation: Each pack embeds the corresponding FE/BE/QC master prompts as sub-headings
(verified by Grep — e.g. pack #1 contains "SERO Admin Backend — Master Implementation Prompt"
at line 10 and "SERO Backend — QA/QC ... Audit Prompt" at line 1119). Packs are therefore an
acceptable canonical substitute for this pass; pack↔individual fidelity is unprovable (EXEC-BLK-01, P2).

## C. Cross-reference
- Agrees with `MASTER_PROMPT_FILE_INVENTORY.md` (other agent). Differences: that file lists 9 packs;
  this adds `SERO_Full_Live_Data_Zero_Mock_Master_Prompt.md` (owned by live-data agent) for completeness.
