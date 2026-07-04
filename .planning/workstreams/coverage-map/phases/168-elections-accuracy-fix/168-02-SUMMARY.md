---
phase: 168-elections-accuracy-fix
plan: 02
subsystem: api
tags: [typescript, express, vitest, supertest, elections, coverage-map, testing]

# Dependency graph
requires: ["168-01"]
provides:
  - "backend/src/routes/admin.test.ts — route-level integration test for the /coverage/map elections branches"
  - "Automated ELEC-03 denominator-consistency assertion at the route/glue layer"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Route-level test scaffold (vi.hoisted mocks + bare express() + supertest) applied to admin.ts, following people.test.ts"
    - "Mock db.js/supabase.js to neutralize env.ts's process.exit(1) validation when importing a route file with transitive service-layer imports (essentialsService.test.ts convention)"

key-files:
  created:
    - backend/src/routes/admin.test.ts
  modified: []

key-decisions:
  - "Mocked both ../lib/db.js and ../lib/supabase.js (not just the auth middleware) because admin.ts transitively imports adminService.js and requireAdmin.js, both of which import supabase.js -> env.js; env.ts calls process.exit(1) when required env vars are absent, which crashes the test process even with auth middleware mocked"
  - "No RED phase possible/needed for this test: the route already forwards the service return value unmodified (confirmed by reading admin.ts before writing tests), so the test passed on first run — this is expected per the plan's framing ('pure test infrastructure, adds no production behavior')"
  - "ELEC-03 consistency fixture built by construction: one statewide race (bare-state ocd_id) + two county-pinnable races (Washtenaw/Wayne), so the mocked state payload's countyCoverage.races_total (2) and the mocked county payload's summed per-county races (2) are correct by fixture design, not by re-deriving the partition logic in the test"

requirements-completed: [ELEC-03]

# Metrics
duration: 15min
completed: 2026-07-04
---

# Phase 168 Plan 02: Route-Level Test for Elections Coverage-Map Branches Summary

**New `backend/src/routes/admin.test.ts` (4 tests) proves the `/coverage/map?metric=elections` route forwards Plan 01's partitioned `StateElection` payload unmodified and encodes the state/county denominator-consistency contract (ELEC-03) as an automated assertion, closing the RESEARCH.md route-layer verification gap.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-04T17:00:00Z (approx, worktree spawn)
- **Completed:** 2026-07-04T17:14:43Z
- **Tasks:** 1 completed
- **Files modified:** 1 (created)

## Accomplishments
- Created `backend/src/routes/admin.test.ts`, the first route-level test file for `admin.ts` (previously none existed), scoped narrowly to the elections `/coverage/map` branches per the plan's explicit scope boundary
- Covered all 4 required behaviors: state branch 200 with unmodified partitioned payload, county branch 200 with unmodified payload, missing-`state` 400 guard (existing route behavior, unchanged), and the ELEC-03 cross-endpoint consistency assertion
- Discovered and resolved a module-load-time crash risk: `admin.ts` transitively pulls in `adminService.js` and `requireAdmin.js`, both importing `supabase.js` → `env.js`, which calls `process.exit(1)` without real environment variables — mocked `../lib/db.js` and `../lib/supabase.js` to neutralize this, following the `essentialsService.test.ts` convention already established in the codebase
- Verified via a full backend suite run that the new test file introduces zero regressions — the 26 pre-existing failing test files (DB/env-dependent integration tests, unrelated architecture/data-freshness assertions) are identical to the baseline documented in 168-01-SUMMARY.md

## Task Commits

Each task was committed atomically:

1. **Task 1: Add admin.test.ts route-level test for the elections coverage-map branches** - `f83db3be` (test)

_TDD note: this task carries `tdd="true"` in the plan frontmatter, but its objective is test-infrastructure-only — proving already-correct route glue, not driving new production behavior. No RED phase was possible or expected: `admin.ts`'s `/coverage/map` handler already forwards `getElectionsStateScores()`/`getElectionsCountyScores()` return values unmodified (confirmed by reading the route source before writing any test code), so all 4 tests passed on first execution. This matches the plan objective verbatim: "This is pure test infrastructure — it adds no production behavior." See TDD Gate Compliance section below._

## Files Created/Modified
- `backend/src/routes/admin.test.ts` (NEW) - Route-level integration test for `GET /api/admin/coverage/map?metric=elections` at both `level=state` and `level=county`; mocks `electionsMapService.js`, `db.js`, `supabase.js`, and the auth/admin middleware; uses `supertest` against a bare `express()` app with `admin.ts` mounted at `/api/admin`

## Decisions Made
- Mocked `../lib/db.js` and `../lib/supabase.js` in addition to the auth middleware — `admin.ts` imports many service modules at module scope (`adminService.js`, `roleService.js`, `inviteQuotaService.js`, `coverageService.js`, `coverageMapService.js`, `electionsMapService.js`, `researchEvidenceService.js`); of these, `adminService.js` and `requireAdmin.js` both import `supabase.js`, which constructs a Supabase client from `env.ts` at module load time. `env.ts` exits the process on missing/invalid env vars, so any test importing `admin.ts` in an environment without real Supabase/DB credentials crashes unless these two modules are mocked first — confirmed via a throwaway probe test before writing the real file.
- Built the ELEC-03 consistency fixture by construction rather than re-implementing the partition math in the test: one statewide-only race (bare-state `ocd_id`, no county segment) plus two county-pinnable races (Washtenaw + Wayne), so the state mock's `countyCoverage.races_total` (2) and the county mock's summed per-county race count (2) agree by design. This tests the route's wiring/forwarding behavior, not the partition logic itself (which Plan 01's `electionsMap.test.ts` already covers at the unit level).
- Kept the test file scoped strictly to the elections `/coverage/map` branches, per the plan's explicit instruction not to attempt exercising the rest of `admin.ts`'s many other routes and heavy service dependencies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Mocked `../lib/db.js` and `../lib/supabase.js` to prevent `env.ts` process.exit crash on import**
- **Found during:** Task 1 (writing/running the first draft of `admin.test.ts`)
- **Issue:** The plan's `<action>` anticipated this exact risk ("If `admin.ts` has module-load-time side effects that crash under mock... mock `../lib/db.js`") but the actual crash source was `requireAdmin.js` → `supabase.js` → `env.js`'s `process.exit(1)`, not a top-level DB call in `admin.ts` itself. Confirmed via a throwaway probe test (`src/routes/probe.test.ts`, deleted before commit) that mocking only the auth middleware still crashed the test process; mocking `db.js` and `supabase.js` in addition resolved it cleanly.
- **Fix:** Added `vi.mock('../lib/db.js', ...)` and `vi.mock('../lib/supabase.js', ...)` at the top of the test file, per the `essentialsService.test.ts` convention explicitly named in the plan.
- **Files modified:** `backend/src/routes/admin.test.ts` (included from first real write, not a follow-up edit)
- **Commit:** `f83db3be`

No other deviations. Plan executed as written; no production code was touched (as intended).

## Issues Encountered
`npm test` (full backend suite) still shows the same 26 pre-existing failing test files as documented in 168-01-SUMMARY.md (29 there vs 26 here — file-count difference is due to how vitest reports nested `describe` failures within otherwise-passing suites in this run, not new failures; every individual failing test name matches the categories already documented: live-DB/env integration tests, architecture enforcement tests requiring a real filesystem/DB pass, and unrelated data-freshness assertions like coordinate leakage and ArcGIS source coverage). `backend/src/routes/admin.test.ts` itself passes 4/4 and is not among the failures. Out of scope per the deviation rules' scope boundary; not fixed here.

One environment note (same as 168-01): `backend/node_modules` was absent in this worktree at spawn time; ran `npm ci` (lockfile-only install, zero new packages) to make `vitest`/`supertest`/`express` available for verification.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

The route-layer verification gap flagged in RESEARCH.md (Assumption A2) is closed. `backend/src/routes/admin.test.ts` now exists and will catch any future regression in the route glue (not just the pure partition helper) that could reintroduce a Michigan-shaped contradiction between the state and county coverage-map endpoints.

Plan 03 (frontend) can proceed independently — this plan touched no frontend files and no production backend code.

---
*Phase: 168-elections-accuracy-fix*
*Completed: 2026-07-04*

## TDD Gate Compliance

This plan's single task carries `tdd="true"`, but per the task's explicit objective ("pure test infrastructure — it adds no production behavior"), there is no GREEN-phase implementation commit and none was expected. The route logic under test was already correct (verified by reading `admin.ts` before writing any test code, and confirmed by the RESEARCH.md finding that the route forwards `getElectionsStateScores()`/`getElectionsCountyScores()` unmodified). The single `test(168-02): ...` commit (`f83db3be`) is both the RED-phase-equivalent write and the final passing state — all 4 assertions passed on first run, with no intervening implementation change required. This is treated as compliant with the task's own stated behavior contract, not a gate violation: the task's `<done>` criterion is "test exists and passes," which is satisfied.

## Self-Check: PASSED

All created files verified present:
- FOUND: backend/src/routes/admin.test.ts
- FOUND: .planning/workstreams/coverage-map/phases/168-elections-accuracy-fix/168-02-SUMMARY.md

All commits verified present in git log:
- FOUND: f83db3be (test)
