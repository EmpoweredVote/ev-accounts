---
phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
plan: 02
subsystem: backend
tags: [fec, rate-limit, incremental, bulk-data, backend-reliability]

requires:
  - phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
    provides: prior-wave FEC 429 limiter/backoff (174-01/174-03) as the pacing backstop this root-cause fix layers under
provides:
  - "buildCandidateCommitteeMap(cycle) in fecBulkLoader.ts — bulk CAND_ID -> committee[] map, cached 7 days"
  - "resolveCommitteeIds in fecAdapter.ts refactored bulk-first (API is fallback-only on a miss)"
  - "getFecLoadCursor(psId, cycle) — date-only incremental watermark derived from ingestion_runs"
  - "min_load_date threaded through the full Schedule A streaming chain (streamAllPages -> streamAllPagesForCommittee -> streamWindowAdaptive -> streamPagesForWindow)"
affects: [fec-ingestion, campaign-finance, cron-jobs]

tech-stack:
  added: []
  patterns:
    - "Bulk-first + rate-limited-API-fallback for FEC committee resolution (never cache an empty fallback result)"
    - "Incremental min_load_date cursor derived from ingestion_runs audit rows, with a 2-day safety lookback, instead of a dedicated cursor table"

key-files:
  created:
    - backend/src/lib/adapters/fecAdapter.test.ts
  modified:
    - backend/src/lib/adapters/fecBulkLoader.ts
    - backend/src/lib/adapters/fecAdapter.ts

key-decisions:
  - "getFecLoadCursor reuses transparent_motivations.ingestion_runs (no new migration/schema) — the current in-flight run row is inserted with status='running' before fetchStream runs, so the status IN ('completed','completed_with_warning') filter correctly excludes it and only ever reads a prior run's watermark."
  - "minLoadDate is threaded through both the fast (whole-cycle-in-one-query) path AND the windowed 504-fallback path, so a mega-committee still gets the incremental filter rather than reverting to full volume."
  - "Bulk-map miss result from the FEC candidates-search fallback is never cached as authoritative — a miss is re-checked on every call, matching the 'never suppress a newly-filing candidate' pitfall from RESEARCH."

requirements-completed: [FEC-01, FEC-02]

coverage:
  - id: D1
    description: "Committee resolution reads the free bulk ccl linkage on a normal run; the API candidate-search survives only as the miss/stale fallback (zero FEC API calls on a bulk hit)."
    requirement: "FEC-01"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter committee resolution (FEC-01) > committee bulk-map hit returns mapped committees with zero FEC API calls for candidate lookup"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter committee resolution (FEC-01) > committee bulk-map miss falls through to the candidate-search fetch fallback"
        status: pass
    human_judgment: false
  - id: D2
    description: "A normal daily run fetches only Schedule A rows loaded since the last successful run via min_load_date (date-only); the whole-cycle pull only runs for pairs with no prior successful run."
    requirement: "FEC-02"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter incremental min_load_date cursor (FEC-02) > load_date: a prior successful run sets min_load_date to the watermark minus 2 days"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter incremental min_load_date cursor (FEC-02) > load_date: no prior successful run omits min_load_date (whole-cycle initial backfill)"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-07-23
status: complete
---

# Phase 174 Plan 02: FEC 429 Root-Cause Redesign (Bulk Committee Resolution + Incremental min_load_date) Summary

**Bulk-first committee resolution (ccl linkage, 7-day cache) plus a `min_load_date` incremental cursor collapse FEC API request volume from tens of thousands/run to an estimated ~1,000–1,500/day, eliminating the two 429-causing hot paths at the root.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-23
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- FEC-01: `resolveCommitteeIds` now consults `buildCandidateCommitteeMap` (new export in `fecBulkLoader.ts`, streams the free `ccl{YY}.zip` bulk file, caches CAND_ID -> principal committee[] for 7 days) before ever calling the rate-limited FEC candidates-search API — a bulk hit issues zero FEC API requests.
- FEC-02: new `getFecLoadCursor(psId, cycle)` derives a date-only watermark from the max `started_at` of prior successful `fec` `ingestion_runs` rows for the pair, minus a 2-day safety lookback; `null` when no prior successful run exists. Threaded as an optional `minLoadDate` through the entire Schedule A streaming chain (`streamAllPages` -> `streamAllPagesForCommittee` -> `streamWindowAdaptive` -> `streamPagesForWindow`), setting `min_load_date` on the request whenever non-null.
- Both changes preserve all existing behavior on a miss/null-cursor: the candidate-search API fallback and the whole-cycle + windowed-504-fallback initial-backfill path are untouched.
- 4 new Vitest cases in `fecAdapter.test.ts` (2 per task) proving: zero `fetch` calls on a bulk-map hit and exactly one candidates-search fallback call on a miss (FEC-01); `min_load_date` set to cursor-minus-2-days on a prior successful run and omitted entirely on a null cursor (FEC-02).

## Task Commits

Each task was committed atomically:

1. **Task 1: FEC-01 — resolve committees from bulk ccl linkage, API only as fallback** - `ef23f6bf` (feat)
2. **Task 2: FEC-02 — incremental min_load_date cursor replaces whole-cycle re-pull** - `d977192c` (feat)

_Both tasks were tdd="true"; each commit bundles the extended `fecAdapter.test.ts` coverage together with the implementation (test infrastructure did not previously exist for this file — first-time creation, not RED/GREEN/REFACTOR against pre-existing failing tests)._

## Files Created/Modified
- `backend/src/lib/adapters/fecBulkLoader.ts` - added exported `buildCandidateCommitteeMap(cycle)` (FEC-01)
- `backend/src/lib/adapters/fecAdapter.ts` - `resolveCommitteeIds` refactored bulk-first; new `getFecLoadCursor`; `minLoadDate` threaded through the streaming chain (FEC-01 + FEC-02)
- `backend/src/lib/adapters/fecAdapter.test.ts` - new file; 4 Vitest cases covering both requirements

## Decisions Made
- Reused `transparent_motivations.ingestion_runs` as the incremental cursor source (no migration) — the plan's `must_haves.key_links` explicitly calls this out and RESEARCH-amendments.md confirms it as the only load-bearing dependency for FEC-02.
- `minLoadDate` is passed to both the fast whole-cycle path and the windowed 504-fallback recursion, so a mega-committee that still needs date-window subdivision also benefits from the incremental filter rather than falling back to full-cycle volume.
- Test infrastructure required an `.gitignore`d `node_modules` symlink into the sibling checkout at `C:\EV-Accounts\backend\node_modules` (worktree has no local `node_modules`; `package.json` verified byte-identical first) so `npx vitest`/`npx tsc` could run inside the isolated worktree — no tracked files affected.

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched their `<action>` specs; no Rule 1-4 auto-fixes were needed.

## Issues Encountered
- The worktree had no `node_modules` (git worktrees don't carry gitignored directories). Verified `backend/package.json` was byte-identical to the main checkout, then symlinked `backend/node_modules` to the main repo's installed dependencies to run `vitest`/`tsc` locally. This is a local dev-environment fix only — `node_modules` remains gitignored and untracked; no project files were affected.

## User Setup Required

None — no external service configuration required. No migration, no schema change (per plan's `<artifacts_this_phase_produces>`).

## Next Phase Readiness
- FEC-01 and FEC-02 are both implemented and unit-tested; `npx tsc --noEmit` is clean for all touched files.
- Per the plan's `<verification>` section, a live/manual sanity check (non-blocking, optional) would confirm the built Schedule A URL for a pair with a prior successful run actually contains `min_load_date=` in production and that committee-resolution logs show a bulk hit — this was not exercised against the live FEC API in this plan (unit-level only, per the plan's scope) and is safe to defer; the other plans in this phase (174-01/174-03, limiter/backoff) remain the pacing backstop regardless.
- No blockers for the rest of Phase 174's waves.

---
*Phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha*
*Plan: 02*
*Completed: 2026-07-23*
