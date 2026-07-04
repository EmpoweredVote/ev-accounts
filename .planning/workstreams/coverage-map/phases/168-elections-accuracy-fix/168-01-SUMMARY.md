---
phase: 168-elections-accuracy-fix
plan: 01
subsystem: api
tags: [typescript, express, elections, coverage-map, vitest]

# Dependency graph
requires: []
provides:
  - "classifyRaces pure partition helper in backend/src/lib/electionsMap.ts"
  - "getElectionsStateScores now returns two separately-computed numbers per state (statewide/legislative coverage + county/local-pinnable countyCoverage)"
  - "Extended StateElection payload contract (countyCoverage, statewideRaces) — authoritative shape for Plans 02 and 03"
affects: [168-02-route-test, 168-03-frontend]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single shared classifier (resolveRaceCountyFips) called from both getElectionsStateScores and getElectionsCountyScores — partition boundary can never drift between the two numbers"
    - "N/A vocabulary via status: 'unknown'|'scored' (never a numeric sentinel like -1) for denominator-zero states"

key-files:
  created: []
  modified:
    - backend/src/lib/electionsMap.ts
    - backend/src/lib/electionsMap.test.ts
    - backend/src/lib/electionsMapService.ts

key-decisions:
  - "classifyRaces reuses resolveRaceCountyFips in place (single-pass loop, non-null -> countyPinnable, null -> statewide) rather than writing a second classifier, per D-04"
  - "countyCoverage is a nested status-tagged object (status/coverage/races_total/races_covered) mirroring ClassifiedCounty's existing vocabulary, not flat sibling fields or a numeric sentinel"
  - "Cache key unchanged ('elections:us') — payload shape extended only, no second cache key added"

requirements-completed: [ELEC-01, ELEC-03]

# Metrics
duration: 12min
completed: 2026-07-04
---

# Phase 168 Plan 01: Elections State/County Split Accuracy Fix Summary

**Partitioned `getElectionsStateScores` into two separately-computed coverage numbers (statewide/legislative vs county-pinnable) using the existing `resolveRaceCountyFips` classifier, fixing the Michigan bug where county-less states showed a false 100% coverage.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-04T16:56:00Z (approx, worktree spawn)
- **Completed:** 2026-07-04T17:03:47Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments
- Added `classifyRaces` pure partition helper to `electionsMap.ts`, reusing `resolveRaceCountyFips` with zero duplicate logic
- Rewrote `getElectionsStateScores` to fetch `countyOcdToFips`/`placeSlugToFips` inside the per-state loop (mirroring the already-correct `getElectionsCountyScores`) and partition races before computing coverage
- Extended `StateElection` with `countyCoverage` (N/A-safe via `status`) and `statewideRaces` (for the ELEC-02 panel), with zero new DB queries and zero new cache keys
- A state whose races are all cd/sldu/sldl/bare-state (the Michigan case) now reports its real statewide coverage in `coverage` and `countyCoverage.status === 'unknown'` — never a lumped 100%, never a fake 0%

## Task Commits

Each task was committed atomically:

1. **Task 1: Add classifyRaces pure partition helper + tests (Wave 0 scaffold)** - `a95d13a2` (test, RED) + `9c7670c6` (feat, GREEN)
2. **Task 2: Partition getElectionsStateScores into two numbers + extend StateElection payload** - `a0985672` (feat)

_TDD note: Task 1 followed RED/GREEN (test commit confirmed failing on `classifyRaces is not a function`, then implementation commit turned all 14 tests green). Task 2's behavior is fully exercised by Task 1's `classifyRaces` unit tests plus the plan's `tsc --noEmit` verification gate; no additional test file was required since the service function is a thin composition of already-tested pure helpers._

## Files Created/Modified
- `backend/src/lib/electionsMap.ts` - Added exported `classifyRaces(races, countyOcdToFips, placeSlugToFips)` pure partition helper beside `classifyCounty`
- `backend/src/lib/electionsMap.test.ts` - Added `describe('classifyRaces', ...)` covering empty, all-statewide, mixed, place/nested-county, and legislative-only cases
- `backend/src/lib/electionsMapService.ts` - Rewrote `getElectionsStateScores` body to partition races via `classifyRaces`; extended `StateElection` interface with `countyCoverage` and `statewideRaces`

## Decisions Made
- `classifyRaces` calls `resolveRaceCountyFips` in a single-pass loop rather than being a second/parallel classifier — guarantees the state split and county drill-down can never disagree on which bucket a race belongs to (ELEC-03 requirement)
- `countyCoverage` shape is `{ status: 'unknown' | 'scored'; coverage: number; races_total: number; races_covered: number }` — chosen to mirror the existing `ClassifiedCounty` vocabulary already consumed correctly by the frontend, rather than inventing a new N/A convention
- Kept the single existing cache key `'elections:us'` — extended the payload shape only, per RESEARCH.md's explicit anti-pattern warning against a second cache key

## Deviations from Plan

None - plan executed exactly as written. Both `must_haves.artifacts` and `must_haves.key_links` from the plan frontmatter are satisfied:
- `classifyRaces` exported from `electionsMap.ts`, calling `resolveRaceCountyFips` (verified via grep and passing tests)
- `getElectionsStateScores` fetches `countyOcdToFips`/`placeSlugToFips` inside the per-state loop via `Promise.all`, calls `classifyRaces`, and pushes `countyCoverage` on every `StateElection`

One environment note (not a plan deviation): `backend/node_modules` was absent in this worktree at spawn time; ran `npm ci` (lockfile-only install, zero new packages) to make `vitest`/`tsc` available for verification.

## Issues Encountered
`npm test` (full backend suite) shows 29 pre-existing failing test files unrelated to this plan — all are integration tests requiring live DB/env vars (`ERR_MODULE_NOT_FOUND`/`process.exit` from `env.ts`/`db.ts` validation) or unrelated architecture/data-freshness assertions (coordinate leakage, ArcGIS source coverage, tribal-land). Verified by running the full suite against the pre-Task-2 base commit (`9c7a95f8`) — identical 29 failing files present before any of this plan's changes. Confirmed via `git stash show -p` diff-and-reapply (not `git stash pop`, per the shared-`refs/stash` hazard) that no regression was introduced. This is out of scope per the deviation rules' scope boundary and is not fixed here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The `StateElection` contract is now final for this phase:

```typescript
export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  coverage: number;          // statewide/legislative only (D-01 — colors the map)
  races_total: number;       // statewide/legislative race count
  races_covered: number;     // statewide/legislative races with >=1 candidate
  countyCoverage: {
    status: 'unknown' | 'scored';  // 'unknown' = no county-pinnable races (N/A, never a fake 0%)
    coverage: number;              // 0..100, one decimal, 0 when unknown
    races_total: number;
    races_covered: number;
  };
  statewideRaces: RaceRow[];  // full statewide/legislative race list for the ELEC-02 panel
}
```

`RaceRow` is unchanged: `{ race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null }`.

Plans 02 (route test) and 03 (frontend) can consume this shape directly — no further backend changes anticipated. The `/coverage/map?level=state&metric=elections` route (`backend/src/routes/admin.ts`) forwards `getElectionsStateScores()`'s return value unmodified, so it already serves the new fields with zero route code changes.

Ready for Plan 02 to add route-level test coverage and Plan 03 to consume `countyCoverage`/`statewideRaces` in the admin UI.

---
*Phase: 168-elections-accuracy-fix*
*Completed: 2026-07-04*
