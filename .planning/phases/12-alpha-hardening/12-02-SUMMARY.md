---
phase: 12-alpha-hardening
plan: 02
subsystem: testing
tags: [jwt, revocation, vitest, supertest, jose, redis, integration-tests]

# Dependency graph
requires:
  - phase: 02-auth-routes
    provides: logout route with recordLogout writing to cache, requireAuth checking isTokenRevoked
  - phase: 01-foundation
    provides: auth middleware (auth.ts), authService.ts, cache.ts with in-memory fallback
provides:
  - JWT revocation integration test proving logout + immediate reuse returns 401
  - Clean test suite with zero skipped tests and zero skip stubs
  - Honest test count (90 real tests, all passing)
affects:
  - 12-03-PLAN (clean baseline for further hardening)
  - Any phase that adds integration tests (pattern established)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HS256 test JWT pattern: set SUPABASE_JWT_SECRET before dynamic import to activate symmetric path"
    - "iat offset pattern: set iat to now-1s to guarantee iat < lastLogout in strict comparison"
    - "Skip stub removal: delete entire it.skip/describe.skipIf blocks, never convert to .todo"

key-files:
  created:
    - tests/integration/revocation.test.ts
  modified:
    - tests/integration/auth.test.ts
    - tests/integration/account.test.ts
    - tests/integration/connect.test.ts
    - tests/integration/compass.test.ts
    - tests/integration/invites.test.ts
    - tests/integration/candidates.test.ts
    - tests/integration/empower.test.ts

key-decisions:
  - "HARD-03: JWT revocation proven via in-memory cache fallback — no live Supabase needed"
  - "HARD-04: Skip stubs deleted entirely (not converted to .todo — vitest 2.x counts both as skipped)"
  - "iat set to now-1s: isTokenRevoked uses strict less-than, same-second collision would break test"
  - "describe.skipIf blocks in auth.test.ts deleted — those tests require live Supabase and can never run in CI"

patterns-established:
  - "Revocation test pattern: env vars set at file top before dynamic import, HS256 path activated by SUPABASE_JWT_SECRET"
  - "Clean test suite policy: no it.skip, no describe.skipIf, no .todo — only passing or absent tests"

# Metrics
duration: 4min
completed: 2026-03-06
---

# Phase 12 Plan 02: Test Suite Hardening Summary

**JWT revocation security guarantee proven by HS256 integration test; 97 it.skip stubs and 2 describe.skipIf blocks deleted — test suite now reports 90 honest passing tests with 0 skipped**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-06T15:55:41Z
- **Completed:** 2026-03-06T16:00:03Z
- **Tasks:** 2
- **Files modified:** 8 (1 created, 7 cleaned)

## Accomplishments

- New `revocation.test.ts` proves the JWT revocation security guarantee end-to-end: logout writes `last_logout:{userId}` to in-memory cache, and the same token is immediately rejected with 401 "Token has been revoked" on the next request
- Deleted all 97 `it.skip()` stubs and 2 `describe.skipIf(!hasRealSupabase)` blocks from 7 test files — test count drops from 189 reported (89 passing + 100 skipped) to 90 (all passing)
- Established HS256 test JWT signing pattern for use in future integration tests that need auth without live Supabase

## Task Commits

Each task was committed atomically:

1. **Task 1: Write JWT revocation integration test (HARD-03)** - `cd918cc` (test)
2. **Task 2: Delete all skip stubs and skipIf blocks (HARD-04)** - `82c8f90` (refactor)

**Plan metadata:** _(final docs commit — see below)_

## Files Created/Modified

- `tests/integration/revocation.test.ts` - New integration test: signs HS256 JWT, calls logout, asserts immediate 401 "Token has been revoked" on next request
- `tests/integration/auth.test.ts` - Removed 2 `describe.skipIf(!hasRealSupabase)` blocks (signup success, login wrong credentials, login success), removed `hasRealSupabase` constant
- `tests/integration/account.test.ts` - Removed 3 inner `describe('(requires Supabase connectivity)')` blocks containing 14 it.skip stubs
- `tests/integration/connect.test.ts` - Removed 27 it.skip stubs, collapsed 5 describe blocks to single passing tests
- `tests/integration/compass.test.ts` - Removed 18 it.skip stubs, deleted 2 empty describe blocks (public access, calibration)
- `tests/integration/invites.test.ts` - Removed 14 it.skip stubs, collapsed 3 describe blocks to single passing tests
- `tests/integration/candidates.test.ts` - Removed 10 it.skip stubs, deleted entire `describe('Candidate routes: DB-dependent tests')` block
- `tests/integration/empower.test.ts` - Removed 10 it.skip stubs, deleted 4 empty Supabase-dependent describe blocks

## Decisions Made

- **iat offset:** Token `iat` is set to `now - 1s` so that `tokenIat < lastLogout` (strict less-than in `isTokenRevoked`) is guaranteed. If `iat === lastLogout` (same second), the check returns false (not revoked) and the test would fail.
- **SUPABASE_JWT_SECRET must be set before dynamic import:** The auth middleware reads `env.SUPABASE_JWT_SECRET` at module evaluation time to select HS256 vs JWKS. Setting it after import would leave the middleware on the JWKS path, causing JWT verification to fail against the test URL for the wrong reason.
- **Deleted, not converted:** Skip stubs were deleted entirely. Converting to `.todo` would still count as skipped in vitest 2.x and would not satisfy HARD-04.
- **describe blocks emptied by removals were also deleted:** An empty describe block adds noise and implies intent that isn't there.

## Deviations from Plan

None — plan executed exactly as written. The revocation test implementation matched the plan spec after reading the actual source files.

## Issues Encountered

None. The `signOutUser` fetch failure against `test.supabase.co` is expected behavior logged to stderr — not an error. The logout route swallows it and calls `recordLogout` regardless, which is exactly the behavior being tested.

## Next Phase Readiness

- HARD-03 and HARD-04 are both satisfied
- Test suite is in a clean, honest state: 90 tests, all passing, 0 skipped
- The HS256 test JWT signing pattern in `revocation.test.ts` can be used as a reference for any future integration test that needs an authenticated request without live Supabase
- Ready for 12-03 (remaining hardening tasks)

---
*Phase: 12-alpha-hardening*
*Completed: 2026-03-06*
