---
phase: 57-ctc-civic-spaces-integration
plan: 01
subsystem: testing
tags: [vitest, supertest, jose, roleService, contributor, roles, ctc, civic-spaces, integration-tests]

requires:
  - phase: 56-essentials-data-editor-endpoint
    provides: established endpoint pattern for contributor role exposure
  - phase: 53-roles-endpoints
    provides: GET /api/contributor/me and POST /api/roles/check live endpoints

provides:
  - ROLE_CACHE_TTL_SECONDS env var controlling cache TTL in roleService.ts
  - 10-test HTTP integration suite proving CTC and Civic Spaces endpoint correctness
  - ctc_content_editor jurisdiction exposure verified
  - volunteer NULL-scope semantics verified
  - cache lifecycle (grant-to-revoke state change) verified

affects:
  - phase 57 plans 02+ (smoke scripts, integration guide)
  - CTC integration team (test proof of endpoint behavior)
  - Civic Spaces integration team (test proof of roles/check behavior)

tech-stack:
  added: []
  patterns:
    - "Cache pre-population pattern: set cache.set(CACHE_KEY, grants, ttl) in tests instead of vi.mock to avoid vitest hoisting issues"
    - "ROLE_CACHE_TTL_SECONDS env var read inside function body so tests can override per-process without module re-import"

key-files:
  created:
    - tests/integration/ctcCivicSpaces.test.ts
  modified:
    - backend/src/lib/roleService.ts

key-decisions:
  - "Used cache pre-population (cache.set) instead of vi.mock for roleService mocking — vi.mock is hoisted by vitest before process.env assignments, causing module load failures"
  - "ADMIN_INGEST_TOKEN required by env.ts schema — added to test env vars"
  - "ROLE_CACHE_TTL_SECONDS read inside getCachedUserRoles function body, not at module scope, preserving per-test override ability"

patterns-established:
  - "Cache pre-population for roleService tests: import cache from backend/src/lib/cache.js, call cache.set(roles:uid:{userId}, grants, ttl) before HTTP request"
  - "beforeEach cache.del(CACHE_KEY) prevents test bleed when using pre-population pattern"

duration: 4min
completed: 2026-04-03
---

# Phase 57 Plan 01: CTC + Civic Spaces Integration Tests Summary

**10-test HTTP integration suite proving ctc_content_editor and volunteer grant endpoints are correct, with ROLE_CACHE_TTL_SECONDS env var for configurable cache TTL**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-03T21:52:27Z
- **Completed:** 2026-04-03T21:55:58Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Made roleService cache TTL configurable via `ROLE_CACHE_TTL_SECONDS` env var (default 90s unchanged)
- 10 passing integration tests covering all Phase 57 success criteria 1-3 via 9 static tests and criteria 4 via lifecycle test
- Proved NULL-scope volunteer grants pass any jurisdiction check (key Civic Spaces requirement)
- Proved cache lifecycle correctly reflects post-revocation state without requiring sleeps

## Task Commits

Each task was committed atomically:

1. **Task 1: Make roleService cache TTL configurable via env var** - `813ea67` (feat)
2. **Task 2: Create HTTP-level integration tests for CTC + Civic Spaces endpoints** - `319c2ab` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/lib/roleService.ts` - Added `ROLE_CACHE_TTL_SECONDS` env var read in `getCachedUserRoles`; default 90s
- `tests/integration/ctcCivicSpaces.test.ts` - 272-line integration test file; 10 tests across 3 describe blocks

## Decisions Made

**Cache pre-population instead of vi.mock:** The plan specified using `vi.mock('../../backend/src/lib/roleService.js', ...)` to control `getCachedUserRoles` return values. However, vitest hoists `vi.mock` calls to the top of the file before `process.env` assignments execute — causing `env.ts` to exit early with "Missing env vars". The research doc (57-RESEARCH.md Pattern 5) had already identified this alternative: directly pre-populate the in-memory cache via `cache.set(CACHE_KEY, grants, ttl)`. This approach tests the real code path (including cache hit logic), avoids hoisting issues, and is simpler. Adopted this pattern instead.

**Added ADMIN_INGEST_TOKEN to test env:** `env.ts` requires `ADMIN_INGEST_TOKEN` as a non-optional field. Other test files that load the app (e.g., `requireRole.test.ts`, `gems.test.ts`) include it. Added to this test file's env block.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Switched from vi.mock to cache pre-population pattern**

- **Found during:** Task 2 (first test run attempt)
- **Issue:** `vi.mock` is hoisted by vitest before `process.env` assignments, causing `env.ts` schema validation to fail with "Missing env vars" and `process.exit(1)` before any test runs
- **Fix:** Used `cache.set(CACHE_KEY, grants, ttl)` in each test to pre-populate the in-memory cache, plus `beforeEach(() => cache.del(CACHE_KEY))` to prevent test bleed. Added `ADMIN_INGEST_TOKEN` to the env vars block.
- **Files modified:** tests/integration/ctcCivicSpaces.test.ts
- **Verification:** All 10 tests pass green
- **Committed in:** 319c2ab

---

**Total deviations:** 1 auto-fixed (1 bug — vi.mock hoisting incompatibility)
**Impact on plan:** No scope change. Cache pre-population is equivalent to vi.mock for this use case and tests the real cache hit code path, which is strictly better.

## Issues Encountered

None beyond the vi.mock hoisting issue documented above.

## User Setup Required

None — no external service configuration required. Tests use in-memory cache fallback.

## Next Phase Readiness

- Phase 57 Plan 02 (smoke script) can proceed — endpoints are verified correct
- Integration guide update (Plan 03 or similar) can reference these tests as proof of behavior
- CTC team can be pointed to `tests/integration/ctcCivicSpaces.test.ts` for behavioral specification
- ROLE_CACHE_TTL_SECONDS is documented and live — smoke script can use 1s TTL for lifecycle testing

---
*Phase: 57-ctc-civic-spaces-integration*
*Completed: 2026-04-03*
