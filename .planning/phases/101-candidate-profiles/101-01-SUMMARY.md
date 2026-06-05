---
phase: 101-candidate-profiles
plan: 01
subsystem: database
tags: [postgres, pg, audit, inform, senate, triage, sources, data-quality]

# Dependency graph
requires:
  - phase: 100-source-coverage-audit
    provides: "Locked sourced definition (SOURCED_CASE/UNSOURCED_CASE), weak-source homepage-only regex, Deb Fischer as the single Federal unsourced senator baseline"
provides:
  - "run-senator-source-triage.ts — senator-specific triage script (FEDX-01 scoping step)"
  - "101-TRIAGE-REPORT.md — human-readable report: 100 senators, 1 flagged (Deb Fischer, ai-regulation, unsourced_only)"
  - "101-SENATOR-TARGETS.csv — machine-readable per-senator target list with affected_topic_keys"
  - "Plan 02 scope confirmed: 1 senator, 1 plan (per D-03 threshold ≤10)"
affects: [101-candidate-profiles plan 02, FEDX-01, QUAL-01, QUAL-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Senator scope filter: DISTINCT ON (p.id) + is_incumbent=true + district_type='NATIONAL_UPPER' produces exactly 100 senator rows (excludes 43 candidates who also have NATIONAL_UPPER districts)"
    - "SOURCED_CASE/UNSOURCED_CASE copied verbatim from run-source-coverage-audit.ts — locked per D-01"
    - "Weak-source: Postgres ~ operator with '^https?://[^/]+/?$' against every non-blank element of pc.sources"

key-files:
  created:
    - backend/scripts/run-senator-source-triage.ts
    - .planning/phases/101-candidate-profiles/101-TRIAGE-REPORT.md
    - .planning/phases/101-candidate-profiles/101-SENATOR-TARGETS.csv
  modified: []

key-decisions:
  - "Added is_incumbent=true filter to senate_politicians CTE: 143 politicians have NATIONAL_UPPER offices (100 sitting senators + 43 2026 candidates). Without is_incumbent=true, the CTE returns 143. The plan requires exactly 100."
  - "No weak-source senators found: all 107 weak-source rows from Phase 100 are in State/Local tier, none federal."
  - "Plan 02 batching: 1 plan (1 senator flagged, well within ≤10 threshold per D-03)."

patterns-established:
  - "is_incumbent=true in senate scope CTE: always required when filtering to sitting US Senators vs all NATIONAL_UPPER politicians (which includes 2026 candidates)"

requirements-completed: [FEDX-01]

# Metrics
duration: 25min
completed: 2026-06-05
---

# Phase 101 Plan 01: Senator Source Triage Summary

**Senator triage script producing 1-senator target list: only Deb Fischer (NE, ai-regulation) is unsourced; zero weak-source senators; Plan 02 is 1-plan scope**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-05T22:39:57Z
- **Completed:** 2026-06-05T22:45:00Z
- **Tasks:** 2
- **Files modified:** 3 created

## Accomplishments

- Built `run-senator-source-triage.ts` with senate_politicians CTE (DISTINCT ON, is_incumbent=true, NATIONAL_UPPER), SOURCED_CASE/UNSOURCED_CASE copied verbatim from Phase 100, weak-source regex, and three queries (summary, per-senator targets, topic detail)
- Ran against live DB: 100 senators, 2321 stances, 1 unsourced stance (Deb Fischer / ai-regulation), 0 weak-source stances
- Produced 101-TRIAGE-REPORT.md and 101-SENATOR-TARGETS.csv confirming Plan 02 scope is 1 senator / 1 plan

## Task Commits

1. **Task 1: Build senator-specific triage script** - `2ff3ed0` (feat)
2. **Task 2: Run triage script and commit artifacts** - `d6c58c3` (feat)

## Files Created/Modified

- `backend/scripts/run-senator-source-triage.ts` - Senator triage script using pg.Pool; SOURCED_CASE/UNSOURCED_CASE locked per D-01; NATIONAL_UPPER+is_incumbent=true scope; outputs .md + .csv via writeFileSync; --dry-run flag
- `.planning/phases/101-candidate-profiles/101-TRIAGE-REPORT.md` - Human-readable report with executive summary (total_senators=100), methodology, Deb Fischer unsourced section, combined target list, Plan 02 scoping note
- `.planning/phases/101-candidate-profiles/101-SENATOR-TARGETS.csv` - Machine-readable per-senator targets; header: full_name,politician_id,state,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification; 1 data row (Deb Fischer)

## Decisions Made

**is_incumbent=true added to senate_politicians CTE (deviation from plan spec):**
The plan spec says "district_type = 'NATIONAL_UPPER'" will produce 100 rows. In practice, 143 active politicians have NATIONAL_UPPER office links — 100 sitting senators (is_incumbent=true) plus 43 2026 Senate candidates (is_incumbent=false). Added `AND p.is_incumbent = true` to the CTE to scope correctly to the 100 senators. This aligns with plan intent ("This must produce exactly 100 senator rows").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added is_incumbent=true to senate scope — NATIONAL_UPPER returns 143 not 100**
- **Found during:** Task 1 (dry-run verification)
- **Issue:** The senate_politicians CTE using only `district_type = 'NATIONAL_UPPER'` returned 143 politicians (100 senators + 43 2026 candidates who also have NATIONAL_UPPER offices). Dry-run printed `total_senators: 143`. Plan acceptance criteria requires `total_senators: 100`.
- **Fix:** Added `AND p.is_incumbent = true` to the CTE WHERE clause. Dry-run re-confirmed `total_senators: 100`.
- **Files modified:** `backend/scripts/run-senator-source-triage.ts`
- **Verification:** Dry-run output `total_senators: 100` ✓
- **Committed in:** `2ff3ed0` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — data scoping bug)
**Impact on plan:** Fix required for correctness. Without is_incumbent=true, the triage would incorrectly include 43 2026 Senate candidates in the senator target list, inflating counts and misscoping Plan 02 work.

## Senator Triage Results

| Metric | Value |
|--------|-------|
| Total senators | 100 |
| Total stances | 2321 |
| Unsourced stances | 1 |
| Weak-source stances | 0 |
| Senators flagged | 1 |

**Flagged senator:** Deb Fischer (NE, Republican)
- `politician_id`: 3149d855-8d85-4080-b0d6-fb83be500533
- Classification: unsourced_only
- Affected topic: `ai-regulation` (current value: 3.0, no source URL)

**Plan 02 recommended batching:** 1 plan (1 senator flagged — well within ≤10 threshold per D-03)

**CSV for Plan 02:** `.planning/phases/101-candidate-profiles/101-SENATOR-TARGETS.csv`

## Issues Encountered

None beyond the is_incumbent scoping fix documented above.

## Next Phase Readiness

- Plan 02 can read `101-SENATOR-TARGETS.csv` for exact scope: 1 senator (Deb Fischer), 1 topic (ai-regulation), classification unsourced_only
- Recommend single research-stances pass for Deb Fischer / ai-regulation, then UPDATE inform.politician_context.sources with a real primary source URL or DELETE the stance row and log it per QUAL-02
- No blockers

---
*Phase: 101-candidate-profiles*
*Completed: 2026-06-05*
