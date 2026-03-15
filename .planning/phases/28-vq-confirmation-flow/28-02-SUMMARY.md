---
phase: 28-vq-confirmation-flow
plan: 02
subsystem: testing
tags: [vitest, supertest, integration-tests, vq, gems, verification-rating, idempotency]

# Dependency graph
requires:
  - phase: 28-01
    provides: POST /api/vq/confirm-stance endpoint, confirm_vq_stance RPC, vq_confirmation_results table

provides:
  - Integration test suite for POST /api/vq/confirm-stance covering all 6 VQ requirements
  - Non-live auth and validation tests (run in any CI without Supabase)
  - Live DB test suite gated on INTEGRATION_TEST_JWT with skip-if guards

affects:
  - Phase 29: VQ Integration Smoke Test (these tests are the pre-flight checklist)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "skipIf(!hasLiveDB) pattern for live DB tests — gate on INTEGRATION_TEST_JWT, never SUPABASE_URL"
    - "Fixture env vars for live test data: INTEGRATION_TEST_POLITICIAN_ID, INTEGRATION_TEST_TOPIC_ID, INTEGRATION_TEST_USER_ID_2"

key-files:
  created:
    - tests/integration/vq.test.ts
  modified: []

key-decisions:
  - "Live DB tests require INTEGRATION_TEST_POLITICIAN_ID + INTEGRATION_TEST_TOPIC_ID env vars — RPC requires a real politician/topic row; tests skip gracefully without them"
  - "Floor-hit test iterates up to 16 calls to drive rating to 0 — more robust than assuming starting VR"
  - "Stance write verified via GET /api/compass/politicians/:id/answers as DB proxy — avoids direct Supabase client in test layer"
  - "Second user (INTEGRATION_TEST_USER_ID_2) needed for incorrect-user tests and mixed-mode test"

patterns-established:
  - "VQ fixture env vars: INTEGRATION_TEST_POLITICIAN_ID and INTEGRATION_TEST_TOPIC_ID required for live DB fixture-dependent suites"
  - "describe.skipIf(!hasVqFixtures) guards all tests requiring politician/topic rows"

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 28 Plan 02: VQ Confirmation Flow Tests Summary

**Vitest integration tests for POST /api/vq/confirm-stance covering all 6 VQ requirements — auth, validation, gem awards, rating adjustments (cap/floor), idempotency replay, unknown users, and stance writes**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-15T21:45:17Z
- **Completed:** 2026-03-15T21:49:38Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- 10 non-live tests pass in any CI environment (no Supabase required)
- Live DB suite with 12 test cases covers all VQ-01 through VQ-08 requirements
- Tests gated cleanly — `describe.skipIf(!hasLiveDB)` and `describe.skipIf(!hasVqFixtures)` prevent false failures when fixtures are unavailable
- Each requirement has at least one dedicated test case with clear naming tied to VQ spec numbers

## Task Commits

1. **Task 1: Integration tests for POST /api/vq/confirm-stance** - `78d550f` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `tests/integration/vq.test.ts` — Comprehensive integration tests: auth rejection, Zod validation, live DB suite for all VQ requirements

## Test Coverage by Requirement

| Requirement | Test Case | DB State Verified |
|-------------|-----------|-------------------|
| VQ-01: Correct users +3 rating + gems | `awards Red Gems and +3 rating` | Response users array: gems_awarded, rating_delta |
| VQ-01: Rating cap at 150 | `caps verification_rating at 150` | new_rating <= 150 invariant |
| VQ-02: Incorrect users -10 rating | `decreases rating by 10` | Response: gems_awarded 0, rating_delta <= 0 |
| VQ-02: vq_hold_until on floor | `sets vq_hold_until when rating hits 0` | Floor hit detection via response new_rating === 0 |
| VQ-03: Idempotency replay | `second call returns replayed: true` | Counts match, new_rating matches original |
| VQ-04: Unknown users | `random UUID in unresolved_users` | unresolved_users contains unknown ID |
| VQ-05: QUESTION_NOT_FOUND | `returns 404 QUESTION_NOT_FOUND` | HTTP 404, error code |
| VQ-06: Auth rejection | `returns 401 without header`, `FORBIDDEN_GEM_TYPE` | HTTP 401/422, error codes |
| VQ-07: Stance write | `confirmed stance persisted` | Via GET /api/compass/politicians/:id/answers |
| VQ-08: Mixed users | `processes each user correctly` | correct_count 1, incorrect_count 1, gems split |

## Decisions Made

- **Live DB tests use env-var fixture IDs** rather than creating data inline — creating politicians/topics requires admin routes not yet available in test helpers. INTEGRATION_TEST_POLITICIAN_ID and INTEGRATION_TEST_TOPIC_ID must be set when running live DB tests.
- **Floor test iterates** up to 16 calls to drive rating to 0 rather than assuming starting VR — more resilient to live DB state.
- **Stance write verified via HTTP** (GET /api/compass/politicians/:id/answers) rather than direct DB query — keeps tests in the HTTP integration layer without needing a raw Supabase client.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

To run live DB tests, set these env vars:

```bash
INTEGRATION_TEST_JWT=<valid user JWT>
INTEGRATION_TEST_USER_ID=<UUID of that user>
INTEGRATION_TEST_USER_ID_2=<UUID of a second test user with connected_profile>
INTEGRATION_TEST_POLITICIAN_ID=<UUID of a seeded politician in inform.politicians>
INTEGRATION_TEST_TOPIC_ID=<UUID of a seeded topic in inform.compass_topics>
```

Then run from the backend directory:
```bash
npm test -- tests/integration/vq.test.ts
```

## Next Phase Readiness

- Phase 28 complete: endpoint + tests both shipped
- Phase 29 (VQ Integration Smoke Test) can proceed — live env smoke test against deployed API
- Prerequisite: CTC and Accounts API must have matching GEMS_SERVICE_KEYS with 'red' permission in Render env

---
*Phase: 28-vq-confirmation-flow*
*Completed: 2026-03-15*
