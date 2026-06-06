---
phase: 103-state-remediation-ca-md
plan: "03"
subsystem: inform
tags:
  - inform
  - sources
  - md
  - state-executives
  - research-stances
  - migration
  - fresh-research
requirements:
  - STAX-02
  - QUAL-01
dependency_graph:
  requires: []
  provides:
    - STAX-02 (MD fresh research — all 5 MD executive officials now have > 0 sourced stances)
    - Migration 279 applied to live DB
  affects:
    - inform.politician_answers
    - inform.politician_context
tech_stack:
  added: []
  patterns:
    - INSERT-only migration (no DELETE, no ARRAY_CAT — plain overwrite ON CONFLICT for officials with zero prior stances)
    - Chair methodology research (OnTheIssues + Wikipedia; no party-affiliation inference)
    - SKILL.md city-tier skip rule applied fresh (existing-stance exception does NOT apply when prior count = 0)
key_files:
  created:
    - backend/data/stance-research/2026-06-06-md-officials.csv
    - supabase/migrations/20260606000004_279_md_officials_stances.sql
    - .planning/phases/103-state-remediation-ca-md/103-MD-RESEARCH-NOTES.md
    - .planning/phases/103-state-remediation-ca-md/103-MD-VERIFICATION.md
  modified: []
decisions:
  - Migration number 279 chosen (Plan 02 reserves 278; MAX(version) was 277 at pre-flight time)
  - City-tier skip rule applied fresh for MD (25 applicable topics of 44; 19 excluded)
  - QUAL-02 deletion log NOT produced (MD had zero prior stances — CONTEXT.md D-04)
  - Davis same-sex-marriage stance skipped (no specific confirming URL found; SKILL.md no-inference rule)
metrics:
  duration: "< 1 hour (Task 4 continuation only)"
  completed_date: "2026-06-06"
  total_stance_rows_added: 23
  migration_number: 279
---

# Phase 103 Plan 03: MD Officials Fresh Stances Summary

Fresh stance research and migration for 5 Maryland executive branch officials (Wes Moore, Aruna Miller, Anthony G. Brown, Brooke Lierman, Dereck E. Davis) — 23 stances added across 8 topics via INSERT-only migration 279, all sourced from specific non-homepage URLs; STAX-02 and QUAL-01 fully satisfied with zero deletion log entries (MD had no prior stances to delete).

---

## What Was Built

Migration 279 (`supabase/migrations/20260606000004_279_md_officials_stances.sql`) INSERTs 23 stance rows into `inform.politician_answers` and 23 paired context rows into `inform.politician_context` for 5 Maryland executive branch officials. Research was conducted sequentially (one agent per official per MEMORY.md rate-limit rule and CONTEXT.md D-04). No DELETE statements. No ARRAY_CAT. Plain overwrite ON CONFLICT (MD officials had zero prior stances so no merging was needed).

---

## Per-Official Final Stance Counts

| Full Name (DB-canonical) | UUID | stance_count | topics_skipped | topics_with_value |
|--------------------------|------|-------------|----------------|-------------------|
| Wes Moore | 21e534c8-c0c0-42f5-b52b-5eb2f246d632 | 8 | 17 | abortion, childcare, civil-rights, climate-change, fossil-fuels, immigration, tariffs, taxes |
| Aruna Miller | ea9fc2d6-3b26-469a-978c-e8c846d2d49a | 5 | 20 | civil-rights, climate-change, fossil-fuels, healthcare, same-sex-marriage |
| Anthony G. Brown | 60329719-1d5b-4bb4-8295-38ea18f6f378 | 3 | 22 | abortion, civil-rights, immigration |
| Brooke Lierman | b26fb5d2-90eb-4108-8ce5-838df719473d | 5 | 20 | abortion, civil-rights, climate-change, immigration, school-vouchers |
| Dereck E. Davis | 75378a96-8886-46eb-b0c1-37cbe2579265 | 2 | 23 | civil-rights, taxes |
| **TOTAL** | | **23** | **102** | |

Applicable topics per official: 25 (44 live total minus 19 city/judicial-tier topics excluded per SKILL.md).

---

## Total MD Stance Rows Added

**23 rows** in `inform.politician_answers` + **23 rows** in `inform.politician_context` = 46 total DB rows inserted.

---

## Migration Number Applied

**279** — verified at both pre-flight (Task 1) and write-time (Task 3). MAX(version) was 277 when pre-flight ran; Plan 02 reserved 278. Migration filename: `supabase/migrations/20260606000004_279_md_officials_stances.sql`. Applied 2026-06-06 via psql session pooler.

---

## STAX-02 V3 Verification Result

**PASS** — Query V3 (every MD official has > 0 stances) run post-migration:

| full_name | stance_count |
|-----------|-------------|
| Dereck E. Davis | 2 |
| Anthony G. Brown | 3 |
| Aruna Miller | 5 |
| Brooke Lierman | 5 |
| Wes Moore | 8 |

All 5 officials have stance_count > 0. Zero officials remain at 0.

---

## STAX-02 Sourced-Check Result

**PASS** — `md_unsourced_count = 0`. Every MD politician_answer row has a paired politician_context row with at least one non-blank source URL.

---

## STAX-02 Homepage-Only Check Result

**PASS** — `md_weak_source_count = 0`. No MD context row has only homepage-pattern sources. All sources are specific pages (OnTheIssues governor profile pages, Wikipedia politician articles with detailed policy sections).

---

## Requirements Closure

**STAX-02:** Satisfied. All 5 MD executive branch officials added in the Phase 103 scope now have > 0 stances. Research conducted fresh using Chair methodology (FIVE-CHAIRS framing, stance scale embedded per MEMORY.md feedback rule). Every value matched to specific documented position.

**QUAL-01:** Satisfied. Every value verified against the specific Chair text at Task 2 human-verify checkpoint. Three source URLs spot-checked. No party-affiliation inference applied. Notable cross-party-direction values flagged for audit (see below).

**QUAL-02:** Does NOT apply to this plan. Per CONTEXT.md D-04, MD officials had zero existing stances before migration 279. There were no incorrect rows to delete. No deletion log was produced. QUAL-02 for Phase 103 overall is satisfied by Plan 02's CA deletion log.

---

## Notable Values Flagged for Future Audit Spot-Check

These values may surprise reviewers because they differ from simple party-direction assumptions:

1. **Wes Moore / tariffs = 3** (not 1 or 2): Moore explicitly called tariffs "a tool, not an ideology" and expressed support for selective protective tariffs. He does not support blanket free trade (values 1-2) nor broad across-the-board tariffs (values 4-5). Source: OnTheIssues/CBS Face the Nation citations.

2. **Wes Moore / climate-change = 3** (not 2): Despite pledging bold climate action, Moore has not declared a climate emergency or pledged to phase out fossil fuels by 2030. His approach is investment in clean energy while maintaining current production levels. Distinguishing factor: "phase out by 2030" (value 2) vs "gradually reducing reliance" (value 3).

3. **Aruna Miller / fossil-fuels = 2** (stop new permits): Co-sponsoring Maryland's fracking ban from inception (Marcellus Shale Act 2011) maps to value 2 — stopping new permits is the practical effect of a fracking ban.

4. **Dereck E. Davis / taxes = 3** (centrist): Wikipedia explicitly describes Davis as a centrist. Despite being a Democrat, his fiscal record is moderate — supporting targeted investments but not broadly raising taxes on the wealthy. Value 3 (keep current system with small loophole fixes) is the most defensible match.

5. **Dereck E. Davis / same-sex-marriage: SKIPPED** — Wikipedia mentions he "opposed bills to legalize same-sex marriage in Maryland" (pre-2012 bills) but insufficient specific evidence found to assign a current value. Per SKILL.md no-inference rule: skipped rather than assumed.

---

## Research Methodology Notes

- **Skip reason for high skip rates (Davis: 23 skipped, Brown: 22 skipped):** These officials have limited public record on national-tier compass topics beyond their core roles. Davis (Treasurer) and Brown (AG since 2023) have minimal documented positions on topics like ai-regulation, ukraine-support, trans-athletes. Single-pass rule (CONTEXT.md D-06) applied — no retry loops. Skipped topics simply have no row.

- **Source quality:** OnTheIssues governor profile pages used for Wes Moore (detailed policy sections with source citations). Wikipedia politician articles used for Miller, Brown, Lierman, Davis (all confirmed fetched with policy-specific content). All sources are specific pages, not homepages.

- **Sequential research:** All 5 officials researched ONE at a time per MEMORY.md rate-limit feedback and CONTEXT.md D-04. No batching into single agent prompts.

---

## Deviations from Plan

**1. Migration SQL committed in Task 4 (not Task 3)**

The continuation agent prompt stated "Task 3 committed the migration file" but `git log` showed the Task 3 commit (`3e643fc`) only included the CSV and research notes — the SQL file was untracked. The migration SQL was committed as part of the Task 4 verification commit. This is a minor deviation — the file content was correct and unchanged; only the commit timing differed. No plan deliverable was affected.

---

## Self-Check

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| 103-MD-VERIFICATION.md exists | yes | yes | ✓ |
| 103-03-SUMMARY.md exists | yes | yes | ✓ |
| supabase/migrations/20260606000004_279_md_officials_stances.sql exists | yes | yes | ✓ |
| MAX(version) post-migration | 279 | 279 | ✓ |
| V3 query: all 5 officials > 0 stances | yes | yes | ✓ |
| md_unsourced_count = 0 | 0 | 0 | ✓ |
| md_weak_source_count = 0 | 0 | 0 | ✓ |

## Self-Check: PASSED
