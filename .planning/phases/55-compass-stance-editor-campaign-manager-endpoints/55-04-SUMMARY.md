---
phase: 55-compass-stance-editor-campaign-manager-endpoints
plan: 04
subsystem: testing
tags: [vitest, typescript, getMatchingGrant, stanceService, roleService, compass_stance_editor, campaign_manager]

# Dependency graph
requires:
  - phase: 55-01
    provides: "getMatchingGrant pure function in stanceService.ts; UserRoleGrant.id field added"
  - phase: 55-02
    provides: "stance write routes using getMatchingGrant for authorization"
  - phase: 55-03
    provides: "GET /contributors/politicians endpoint"
provides:
  - "Unit test suite for getMatchingGrant (10 test cases)"
  - "Two-jurisdiction scenario explicitly tested (criterion 5)"
  - "campaign_manager resource_id gating tested"
  - "requireRole.test.ts grant() helper updated to include id: string field"
affects: [56, future phases using stanceService.ts or requireRole patterns]

# Tech tracking
tech-stack:
  added: []
  patterns: [
    "Dynamic import in test files for ESM env setup ordering (consistent with Phase 53 pattern)",
    "Pure function tests require no mocking — construct inputs directly"
  ]

key-files:
  created:
    - tests/integration/compassContributor.test.ts
  modified:
    - tests/integration/requireRole.test.ts

key-decisions:
  - "getMatchingGrant is a pure function — no DB mocking needed, just construct UserRoleGrant inputs"
  - "Two-jurisdiction scenario validated by calling same grant with two different politician geoids"

patterns-established:
  - "Pure function unit tests: set env vars, dynamic import, construct test objects, call directly"

# Metrics
duration: 1min
completed: 2026-04-03
---

# Phase 55 Plan 04: getMatchingGrant Test Coverage Summary

**10-test unit suite covering getMatchingGrant jurisdiction enforcement, campaign_manager resource gating, and the two-jurisdiction pass/fail scenario; requireRole.test.ts grant() helper updated with id: string to match current UserRoleGrant interface**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-04T01:39:53Z
- **Completed:** 2026-04-04T01:41:38Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `tests/integration/compassContributor.test.ts` with 10 test cases for `getMatchingGrant`
- Explicitly tested the two-jurisdiction scenario from success criterion 5: same editor grant matches politician A (geoid 18105), rejects politician B (geoid 06037)
- Tested campaign_manager resource_id gating: matching resource_id returns grant, mismatched returns null, geoid is irrelevant for campaign_manager
- Fixed `grant()` helper in `requireRole.test.ts` to include `id: 'test-grant-id'` — satisfies the `UserRoleGrant` interface added in Phase 55-01

## Task Commits

Each task was committed atomically:

1. **Task 1: Create compassContributor.test.ts with getMatchingGrant unit tests** - `fb6d641` (test)
2. **Task 2: Fix grant() helper in requireRole.test.ts — add missing id field** - `3efec70` (fix)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `tests/integration/compassContributor.test.ts` — 10 getMatchingGrant unit tests covering jurisdiction match/mismatch, fail-open for null geoid, unrestricted grants, two-jurisdiction scenario, campaign_manager resource gating, and mixed grant array
- `tests/integration/requireRole.test.ts` — Added `id: 'test-grant-id'` to grant() helper to satisfy UserRoleGrant interface

## Decisions Made

- Tests for `getMatchingGrant` placed in `tests/integration/` (alongside requireRole.test.ts) following established pattern, not a separate unit test directory
- No mocking required — getMatchingGrant is pure, DB-free; construct inputs directly
- grant() helper in compassContributor.test.ts accepts optional `id` param (default `'grant-1'`) so individual test cases can assert on specific grant identity

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `npx vitest run` from repo root failed because vitest is installed in `backend/node_modules`, not root. Resolved by running from `backend/` directory: `cd backend && npx vitest run ../tests/integration/...`. This is consistent with how all other test runs work (backend/package.json test script uses `vitest run` with the config's `include: ['../tests/**/*.test.ts']`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 55 is now fully complete: schema (55-01), stance write routes (55-02), GET politicians endpoint (55-03), and test coverage (55-04) all done
- All 22 tests pass: 10 getMatchingGrant + 12 checkRole
- Ready for Phase 56

---
*Phase: 55-compass-stance-editor-campaign-manager-endpoints*
*Completed: 2026-04-03*
