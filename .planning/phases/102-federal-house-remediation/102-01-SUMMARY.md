---
phase: 102-federal-house-remediation
plan: 01
subsystem: database
tags: [postgres, pg, triage, inform, sources, data-quality, house, candidates]

# Dependency graph
requires:
  - phase: 101-candidate-profiles
    provides: deferred-items.md with Dooley/Shoffner/Alme candidates and their weak topic lists; 101-VERIFICATION.md V2=19 finding
  - phase: 100-source-coverage-audit
    provides: locked sourced definition (SOURCED_CASE/UNSOURCED_CASE/HOMEPAGE_ONLY_REGEX constants)
  - phase: 101-candidate-profiles
    provides: run-senator-source-triage.ts as direct template for the house triage script

provides:
  - run-house-source-triage.ts: dual-scope triage script (NATIONAL_LOWER + NATIONAL_UPPER_DEFERRED)
  - 102-TRIAGE-REPORT.md: human-readable confirmation — 0 flagged NATIONAL_LOWER, 3 flagged deferred candidates (19 weak stances)
  - 102-HOUSE-TARGETS.csv: machine-readable CSV with 3 rows (Dooley/Shoffner/Alme) + politician_ids + affected_topic_keys for Plan 02 dispatch

affects:
  - 102-02 (remediation plan reads 102-HOUSE-TARGETS.csv to drive research-stances agent dispatches)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-scope triage: NATIONAL_LOWER + NATIONAL_UPPER is_incumbent=false queried separately via two CTEs"
    - "DISTINCT ON (p.id) prevents Cartesian inflation when politicians have multiple office rows"
    - "Six pool.query() calls (A+B+C × 2 scopes) — inform schema never via PostgREST"
    - "scope literal column ('NATIONAL_LOWER' | 'NATIONAL_UPPER_DEFERRED') tags combined CSV rows"

key-files:
  created:
    - backend/scripts/run-house-source-triage.ts
    - .planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md
    - .planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv

key-decisions:
  - "NATIONAL_LOWER triage omits is_incumbent filter — all 122 active NATIONAL_LOWER politicians are is_incumbent=true per live DB; omitting is robust to future flips"
  - "Deferred candidates captured via NATIONAL_UPPER is_incumbent=false CTE — same locked SOURCED_CASE/HOMEPAGE_ONLY_REGEX definition as Phase 101"
  - "Plan 02 batching: 1 research plan (3 deferred candidates <= 10 threshold per D-03)"
  - "FEDX-02 V1 trivially passes: NATIONAL_LOWER unsourced_count = 0, weak_count = 0"

patterns-established:
  - "Dual-scope triage pattern: run two CTEs with different district_type filters, combine results in memory, tag rows with scope literal"

requirements-completed:
  - FEDX-02

# Metrics
duration: 18min
completed: 2026-06-06
---

# Phase 102 Plan 01: House + Deferred-Candidate Source Triage Summary

**Dual-scope triage script confirms 0 flagged NATIONAL_LOWER stances and 3 deferred Senate candidates (Dooley/Shoffner/Alme) with 19 homepage-only weak stances — Plan 02 scoped to 1 research plan**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-06T02:10:00Z
- **Completed:** 2026-06-06T02:28:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Built `run-house-source-triage.ts` adapting the Phase 101 senator script for dual scope (NATIONAL_LOWER + NATIONAL_UPPER deferred candidates). SOURCED_CASE/UNSOURCED_CASE/HOMEPAGE_ONLY_REGEX copied verbatim (locked definition).
- Dry-run confirmed expected counts before writing files: NATIONAL_LOWER 0 unsourced/0 weak; NATIONAL_UPPER_DEFERRED 19 weak stances.
- Ran script against live DB — produced `102-TRIAGE-REPORT.md` and `102-HOUSE-TARGETS.csv` with 3 data rows.

## NATIONAL_LOWER Finding (FEDX-02 V1)

- **122** active NATIONAL_LOWER politicians (is_active=true)
- **830** total stances in inform.politician_answers
- **0** unsourced stances
- **0** weak-sourced stances
- **FEDX-02 V1 trivially passes** — no remediation required for House representatives

## Deferred Candidate Targets (Plan 02 Input)

| Politician | State | politician_id | weak_count | Affected Topics |
|------------|-------|---------------|------------|-----------------|
| Derek Dooley | GA (R) | b841a475-41b4-4f19-9ad1-13769b1f4eef | 6 | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights |
| Hallie Shoffner | AR (D) | a7307f34-90ca-4d29-8698-4898ed3de05c | 5 | campaign-finance, climate-change, economic-development, housing, taxes |
| Kurt Alme | MT (R) | 0f8bb5ea-8d89-4cfb-9291-04b54c128b82 | 8 | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights |

**Total weak stances: 19** (Dooley 6 + Shoffner 5 + Alme 8)
All three classified as `weak_only` (no unsourced stances — each has a homepage URL that fails the homepage-only regex).

## Plan 02 Batching

- **Batching tier:** 1 research plan (3 candidates ≤ 10 threshold per D-03)
- **Dispatch order:** Dooley → Shoffner → Alme (one research-stances agent at a time per Memory.md rule)
- **CSV input for Plan 02:** `.planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv`

## Task Commits

Each task was committed atomically:

1. **Task 1: Build house-and-candidate triage script** — `1748f3b` (feat)
2. **Task 2: Run triage script against live DB and commit artifacts** — `4bd56b3` (feat)

## Files Created/Modified

- `backend/scripts/run-house-source-triage.ts` — Dual-scope triage script (1036 lines); adapts senator script with HOUSE_POLITICIANS_CTE + DEFERRED_CANDIDATES_CTE, 6 pool.query() calls, scope-tagged CSV output
- `.planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md` — Human-readable report: two exec summary tables, four detail sections, combined target list, Plan 02 scoping note
- `.planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv` — Machine-readable: 1 header + 3 data rows; columns: full_name, politician_id, scope, state, party, total_stances, unsourced_count, weak_count, affected_topic_keys, classification

## Decisions Made

- Omitted `is_incumbent = true` filter from HOUSE_POLITICIANS_CTE — all 122 active NATIONAL_LOWER politicians are is_incumbent=true per live DB; removing the filter makes the script robust to future is_incumbent state changes.
- Used two independent CTEs (HOUSE_POLITICIANS_CTE and DEFERRED_CANDIDATES_CTE) rather than a UNION to keep query logic readable and independently verifiable.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Self-Check

- [x] `backend/scripts/run-house-source-triage.ts` exists (1036 lines)
- [x] `.planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md` exists
- [x] `.planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv` exists — 4 lines (1 header + 3 data rows)
- [x] CSV header matches locked column shape including `scope` column
- [x] NATIONAL_LOWER unsourced_count = 0, weak_stance_count = 0
- [x] Deferred candidates: Dooley (6), Shoffner (5), Alme (8) — total 19
- [x] All 3 CSV rows have scope = NATIONAL_UPPER_DEFERRED
- [x] Report contains "Plan 02 Scoping" section with "1 research plan"
- [x] Task 1 commit: 1748f3b
- [x] Task 2 commit: 4bd56b3

## Self-Check: PASSED

## Next Phase Readiness

Plan 02 can read `102-HOUSE-TARGETS.csv` immediately:
- 3 rows: Dooley, Shoffner, Alme — with politician_ids and pipe-delimited affected_topic_keys
- Research-stances agents dispatch one at a time (per Memory.md rule): Dooley first (6 topics), then Shoffner (5), then Alme (8)
- Migration target: 269 (verified at research time; re-verify before writing migration in Plan 02 Task 3)
- V2 goal: homepage-only count for NATIONAL_UPPER active politicians drops from 19 to 0 after Plan 02 remediation

---
*Phase: 102-federal-house-remediation*
*Completed: 2026-06-06*
