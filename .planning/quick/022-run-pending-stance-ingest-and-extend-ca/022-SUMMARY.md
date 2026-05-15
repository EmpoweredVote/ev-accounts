---
phase: quick-022
plan: "022"
subsystem: database, api
tags: [postgres, compassService, politician_answers, stance-ingest, typescript]

# Dependency graph
requires:
  - phase: quick-021
    provides: getCandidates/getCandidateAnswers functions + /candidates/:id/answers endpoint
provides:
  - Corrected Malik stances in inform.politician_answers (no value inversion)
  - 255 rows upserted across inform.politician_answers for 24 researched candidates
  - getCandidates() dual-path: empowered_profiles OR politician_answers, with stance_source field
  - getCandidateAnswers() fallback: Path A (compass_responses) then Path B (politician_answers)
affects: [compass compare, GET /compass/politicians?include_candidates=true, GET /candidates/:id/answers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-path SQL CASE: empowered_profiles EXISTS → compass_responses subquery, else politician_answers subquery"
    - "OR EXISTS WHERE clause to include both empowered + researched candidates in single query"
    - "getCandidateAnswers early-return on Path A hit; fall-through to Path B on miss"

key-files:
  created: []
  modified:
    - backend/scripts/apply-malik-stances.ts
    - backend/src/lib/compassService.ts

key-decisions:
  - "Malik CSV values are stored as-is (not inverted); the 3-parseInt subtraction was erroneous"
  - "stance_source field added to getCandidates() return so callers can distinguish empowered vs. researched"
  - "getCandidateAnswers falls through Path A even when empowered_profile exists but has zero responses"

patterns-established:
  - "Politician data dual-path: empowered_profiles/compass_responses (live) vs. politician_answers (researched)"

# Metrics
duration: 15min
completed: 2026-05-15
---

# Quick Task 022: Run Pending Stance Ingest and Extend CA Summary

**255 rows upserted across 24 LA County candidates via politician_answers; compassService extended with dual-path fallback so researched candidates appear in compass compare alongside empowered ones**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-15
- **Completed:** 2026-05-15
- **Tasks:** 3 / 3
- **Files modified:** 2

## Accomplishments

- Fixed value-inversion bug in apply-malik-stances.ts (was computing `3 - parseInt(r.value)` instead of `parseInt(r.value)`)
- Ran all 24 pending stance ingest scripts — 255 rows upserted to inform.politician_answers, 0 errors
- Extended getCandidates() with CASE-based SQL for answer_count/answered_topic_ids/stance_source and OR EXISTS WHERE clause
- Extended getCandidateAnswers() with Path A → Path B fallback; researched stances returned when no empowered_profile exists
- TypeScript compiles clean (tsc --noEmit exits 0)

## Task Commits

1. **Task 1: Fix value-inversion bug in apply-malik-stances.ts** - `82c4013` (fix)
2. **Task 2: Run all 24 pending ingest scripts** - `46b2643` (feat/data — empty commit, DB-only)
3. **Task 3: Extend getCandidates + getCandidateAnswers with politician_answers fallback** - `01b3bfe` (feat)

## Script Results (Task 2)

| Script | Upserted | Skipped |
|--------|----------|---------|
| apply-calanche-stances | 9 | 0 |
| apply-carlisle-stances | 9 | 0 |
| apply-cd1-challengers-stances | 16 | 0 |
| apply-celona-stances | 7 | 0 |
| apply-feldstein-soto-stances | 9 | 0 |
| apply-gaspar-stances | 9 | 0 |
| apply-girvan-stances | 6 | 0 |
| apply-hahn-stances | 24 | 0 |
| apply-hernandez-rosas-stances | 7 | 0 |
| apply-horvath-stances | 12 | 0 |
| apply-kendall-stances | 8 | 0 |
| apply-malik-stances | 19 | 0 |
| apply-mantel-stances | 9 | 0 |
| apply-mazariegos-stances | 10 | 0 |
| apply-mejia-stances | 13 | 0 |
| apply-nuno-stances | 7 | 0 |
| apply-oyler-stances | 8 | 0 |
| apply-prang-stances | 7 | 0 |
| apply-rivers-stances | 5 | 0 |
| apply-roldan-stances | 12 | 0 |
| apply-sanchez-stances | 6 | 0 |
| apply-sarian-stances | 6 | 0 |
| apply-solis-stances | 31 | 0 |
| apply-ugarte-stances | 6 | 0 |
| **TOTAL** | **255** | **0** |

## Files Created/Modified

- `backend/scripts/apply-malik-stances.ts` - Removed erroneous `3 - parseInt(r.value)` inversion; now stores raw CSV value
- `backend/src/lib/compassService.ts` - getCandidates() dual-path SQL + stance_source field; getCandidateAnswers() Path A → Path B fallback

## Decisions Made

- Malik ingest was the only script with value inversion; all others used raw parseInt. The `3 -` subtraction was confirmed erroneous by comparing against the other 23 scripts.
- `stance_source: 'empowered' | 'researched'` added to getCandidates() return type so downstream callers can render source badges if needed.
- Path A early-return in getCandidateAnswers() only triggers when rows.length > 0, so an empowered_profile with zero responses still falls through to Path B.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- GET /compass/politicians?include_candidates=true now returns all 24 researched candidates alongside empowered ones
- GET /candidates/:id/answers returns researched stances for candidates without empowered_profile
- Compass compare is unblocked for the full set of 2026 LA County candidates

---
*Phase: quick-022*
*Completed: 2026-05-15*
