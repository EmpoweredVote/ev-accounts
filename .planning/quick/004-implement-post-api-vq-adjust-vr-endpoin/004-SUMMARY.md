---
phase: quick
plan: 004
subsystem: api
tags: [vq, verification-rating, yellow-quests, idempotency, service-to-service, pool-query]

# Dependency graph
requires:
  - phase: 28-vq-confirm-stance
    provides: vq_confirmation_results idempotency table, connect.connected_profiles VR fields
provides:
  - POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment
  - adjustVerificationRating service function in vqService.ts
affects: [validation-quests, vq-service-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pool.connect() transaction pattern for multi-step atomic VR adjustment (not SECURITY DEFINER RPC)"
    - "Reuse vq_confirmation_results as a general idempotency cache (not VQ-specific)"
    - "Idempotency pre-check before lock acquisition — cheapest replay path"

key-files:
  created: []
  modified:
    - backend/src/lib/vqService.ts
    - backend/src/routes/vq.ts
    - backend/src/middleware/gemServiceKeyAuth.ts
    - tests/integration/vq.test.ts
    - docs/ONBOARDING-VQ.md

key-decisions:
  - "VR clamped to [0, 100] for Yellow quests (not 150 like Red quest confirm-stance)"
  - "vq_confirmation_results reused as general VQ idempotency cache (not RPC-specific)"
  - "No gem_type permission check on adjust-vr (unlike confirm-stance which checks red)"
  - "Idempotency pre-check before BEGIN/FOR UPDATE lock — cheapest replay path per v1.4 pattern"

patterns-established:
  - "Yellow quest VR path: adjust-vr (no gems, no stance) vs Red quest path: confirm-stance (gems + stance)"

# Metrics
duration: 7min
completed: 2026-03-18
---

# Quick Task 004: Implement POST /api/vq/adjust-vr Summary

**POST /api/vq/adjust-vr endpoint implementing Yellow quest immediate VR grading with idempotency, VR clamping to [0,100], and vq_hold enforcement**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-18T17:33:33Z
- **Completed:** 2026-03-18T17:40:11Z
- **Tasks:** 2 of 2
- **Files modified:** 5

## Accomplishments

- `adjustVerificationRating` service function added to `vqService.ts` using `pool.connect()` transaction (direct postgres, not PostgREST)
- VR clamped to [0, 100] — Yellow quest range distinct from Red quest [0, 150]
- `vq_hold_until = NOW() + 30 days` set when VR hits 0
- Idempotency via `connect.vq_confirmation_results` — pre-check before lock acquisition, returns cached result with `replayed: true`
- `POST /adjust-vr` route added to vq router with `requireGemServiceKey` middleware (X-Service-Key auth)
- Zod validation: `user_id` (UUID), `delta` (int -100..100), `idempotency_key` (max 255), `reason` (optional)
- 5 new integration tests covering auth rejection (no header, bad key) and input validation (empty body, delta > 100, non-UUID user_id)
- ONBOARDING-VQ.md: new "Verification Rating Adjustment" section, updated "What Accounts Provides" table, updated "Two separate keys" note

## Task Commits

1. **Task 1: Implement adjust-vr service function and route** - `738ae17` (feat)
2. **Task 2: Add integration tests and update VQ onboarding doc** - `6f78510` (feat)

## Files Created/Modified

- `backend/src/lib/vqService.ts` - Added `AdjustVrParams`, `AdjustVrResult` types and `adjustVerificationRating` function; added `pool` import
- `backend/src/routes/vq.ts` - Added `AdjustVrBodySchema`, imported `adjustVerificationRating`, added `POST /adjust-vr` route handler
- `backend/src/middleware/gemServiceKeyAuth.ts` - Fixed misleading comment (said "Authorization: Bearer" but code used `x-service-key`)
- `tests/integration/vq.test.ts` - Added 5 new adjust-vr tests; fixed pre-existing bug (existing tests used `Authorization: Bearer` instead of `X-Service-Key`)
- `docs/ONBOARDING-VQ.md` - New "Verification Rating Adjustment" section, updated table and two-keys note

## Decisions Made

- **VR cap 100 not 150** — Yellow quests use [0, 100] range; the 150 cap only applies to Red quest confirm-stance grading. Explicit distinction documented in code and docs.
- **No gem_type permission check on adjust-vr** — this endpoint doesn't award gems, so no per-key type enforcement needed. requireGemServiceKey still provides auth gating.
- **Reuse vq_confirmation_results** — the table is a general VQ idempotency cache, not tightly coupled to confirm-stance. adjust-vr results stored there cleanly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed existing confirm-stance tests using wrong auth header**

- **Found during:** Task 2 (running tests)
- **Issue:** Existing `confirm-stance` tests used `.set('Authorization', 'Bearer ...')` but `gemServiceKeyAuth.ts` middleware reads `req.headers['x-service-key']`. All 8 validation/permission tests were returning 401 instead of expected 422.
- **Fix:** Replaced all `.set('Authorization', Bearer ...)` with `.set('X-Service-Key', ...)` across confirm-stance tests. Also fixed the misleading comment in `gemServiceKeyAuth.ts` (said "uses Authorization: Bearer" but implementation uses X-Service-Key).
- **Files modified:** `tests/integration/vq.test.ts`, `backend/src/middleware/gemServiceKeyAuth.ts`
- **Commit:** `6f78510` (included in Task 2 commit)

## Issues Encountered

- Root-level `vitest.config.ts` fails with `Cannot find module 'vitest/config'` when run via `npx vitest` because vitest is installed only in `backend/node_modules/`. Tests must be run via `cd backend && npm run test -- <path>` with `GOOGLE_MAPS_API_KEY=test-maps-key` env var.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- VQ can now call `POST /api/vq/adjust-vr` with `VQ_SERVICE_KEY` to grade Yellow quests immediately
- Endpoint is fully idempotent — safe to retry on 5xx with same `idempotency_key`
- Yellow VR range [0, 100] is enforced; Red VR range [0, 150] continues via confirm-stance

---
*Phase: quick-004*
*Completed: 2026-03-18*
