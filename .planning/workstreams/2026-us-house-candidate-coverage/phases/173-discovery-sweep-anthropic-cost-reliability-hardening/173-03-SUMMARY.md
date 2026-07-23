---
phase: 173-discovery-sweep-anthropic-cost-reliability-hardening
plan: 03
subsystem: testing
tags: [vitest, node-cron, discovery-sweep, anthropic, cost-hardening]

requires:
  - phase: 173-01
    provides: "runDiscoveryAgent returns zero-candidate result instead of throwing when Anthropic is unavailable"
provides:
  - "Regression test locking the OPS-03 caller contract (zero candidates -> completed run, never failed)"
  - "OPS-04 cost-rationale comment on the discovery-sweep cron registration"
affects: [173-04, discoveryService, discoverySweep]

tech-stack:
  added: []
  patterns:
    - "discoveryService test mocking convention: vi.mock db.js/emailService.js/fetchPageContent.js/discoveryAgentRunner.js, sequenced pool.query mockResolvedValueOnce chain matching query order"

key-files:
  created:
    - backend/src/lib/discoveryService.test.ts
  modified:
    - backend/src/cron/discoverySweep.ts

key-decisions:
  - "No source change to discoveryService.ts — its zero-candidate path was already correct (RESEARCH Pattern 3); this plan adds only a regression test."
  - "Cron cadence (0 2 * * 0, UTC) left unchanged — OPS-04 was confirm-and-document, not adjust."

requirements-completed: [OPS-03, OPS-04]

coverage:
  - id: D1
    description: "runDiscoveryForJurisdiction returns status:'completed' with candidatesFound:0 (not 'failed', no throw) when the agent returns zero candidates"
    requirement: "OPS-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryService.test.ts#zero candidates is not a failure"
        status: pass
    human_judgment: false
  - id: D2
    description: "Discovery-sweep cron expression documents the weekly Sunday-02:00-UTC cadence as a deliberate bounded-cost choice, cross-referencing SWEEP_HORIZON_DAYS"
    requirement: "OPS-04"
    verification:
      - kind: other
        ref: "npx tsc --noEmit (clean, comment-only change verified by manual read of backend/src/cron/discoverySweep.ts)"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-07-23
status: complete
---

# Phase 173 Plan 03: OPS-03 Regression Lock + OPS-04 Cron Documentation Summary

**Added a focused vitest regression test that locks the zero-candidate-is-not-a-failure caller contract in `discoveryService.ts`, and documented the weekly discovery-sweep cron cadence as a deliberate bounded-cost decision.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-07-23T07:24:00Z (approx, per first task commit)
- **Completed:** 2026-07-23T07:25:06Z
- **Tasks:** 2 completed
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Created `backend/src/lib/discoveryService.test.ts` with a test titled "zero candidates is not a failure" that mocks `runDiscoveryAgent` to resolve `{ candidates: [], stopReason: 'end_turn' }` and asserts the resulting `DiscoveryRunSummary` has `status: 'completed'` and `candidatesFound: 0` — never `'failed'` or a thrown error. Also asserts the `discovery_runs` row is finalized via a `status = 'completed'` UPDATE (never `status = 'failed'`), and that no email fires when `ADMIN_EMAIL` is unset.
- Test is GREEN immediately against the existing `discoveryService.ts` — no source change was needed, confirming RESEARCH Pattern 3 (the zero-candidate completed path was already correct after the 173-01 runner change).
- Added an OPS-04 comment on the `cron.schedule('0 2 * * 0', ...)` expression in `discoverySweep.ts` explaining that the weekly (not daily) cadence deliberately bounds recurring Anthropic spend, proportional to `discovery_jurisdictions` within `SWEEP_HORIZON_DAYS` (defined in `discoveryCron.ts`). Comment-only — cron string, timezone, and behavior unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author discoveryService.test.ts — OPS-03 regression lock** - `5a472ea5` (test)
2. **Task 2: OPS-04 — document the weekly cron cadence as a deliberate cost choice** - `25730b14` (docs)

_Note: Task 1 was marked `tdd="true"` in the plan but is explicitly a regression lock expected GREEN on first run (not a RED/GREEN cycle) — per the plan's own instruction: "This test is expected GREEN immediately — discoveryService.ts is already correct; the test is a regression lock, not RED." No separate RED commit was made._

## Files Created/Modified
- `backend/src/lib/discoveryService.test.ts` - New vitest suite for `runDiscoveryForJurisdiction`'s zero-candidate caller contract (OPS-03)
- `backend/src/cron/discoverySweep.ts` - Added OPS-04 cost-rationale comment on the cron expression; no behavior change

## Decisions Made
- Kept the mock query chain minimal: since the test's known-races query returns `rows: []`, the `existingCandidates` and `aliasRows` queries are skipped entirely (guarded by `knownRaces.length ? ... : []` in `discoveryService.ts`), reducing the mock sequence to 4 `pool.query` calls (config load, races load, run INSERT, completed UPDATE) instead of 6+.
- Unset `process.env.ADMIN_EMAIL` in the test's `beforeEach` so the zero-candidate regression-alert and review-email branches (both gated on `ADMIN_EMAIL` being set) are not exercised, avoiding the need to mock a 5th "prior completed run" lookup query for this particular test's scope.

## Deviations from Plan

None - plan executed exactly as written. No source change to `discoveryService.ts` (prohibited by the plan and unnecessary per RESEARCH Pattern 3). Cron cadence/timezone unchanged (prohibited by the plan).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
OPS-03 caller contract is now regression-locked (green test in `discoveryService.test.ts`); any future change to `discoveryService.ts` that regresses the zero-candidate path back to `'failed'`/throw will fail this test loudly. OPS-04 cadence rationale is now visible in code at the cron registration site for the next reader/operator. Ready for 173-04 (the remaining wave-1/2 plan(s) in this phase).

---
*Phase: 173-discovery-sweep-anthropic-cost-reliability-hardening*
*Completed: 2026-07-23*

## Self-Check: PASSED
All created/modified files verified present on disk; all task commits (5a472ea5, 25730b14) and the summary commit (b208eae9) verified present in git log.
