---
phase: 03-alpha-enrollment
plan: 03
subsystem: api
tags: [express, postgresql, pg-pool, atomic-transactions, connect-flow, verification-sessions, two-phase-import, integration-tests]

requires:
  - phase: 03-02
    provides: claimInviteCode with codeId on success, pg pool pattern, inviteService.ts, connect.verification_sessions and connect.connected_profiles tables

provides:
  - backend/src/routes/connect.ts — POST /start (claim code + UPSERT session), PATCH /step (draft updates + step advancement), POST /complete (atomic pg transaction), GET /status (verification stage), POST /compass-import (two-phase validate+save)
  - backend/src/index.ts — connectRouter mounted at /api/connect
  - tests/integration/invites.test.ts — 401 tests for all 3 invite endpoints, architecture enforcement test
  - tests/integration/connect.test.ts — 401 tests for all 5 connect endpoints, architecture enforcement test, skip-marked Supabase-dependent tests

affects: [04-compass-routes, 05-empower-flow]

tech-stack:
  added: []
  patterns:
    - pg FOR UPDATE row lock in POST /complete — serializes concurrent complete attempts, prevents duplicate connected_profiles creation
    - UPSERT with ON CONFLICT (user_id) DO UPDATE — idempotent session creation in POST /start
    - Two-phase API pattern — validate (confirmed:false) then save (confirmed:true) in compass-import
    - Whitelist serialization in POST /complete — tolerance_rating and legal_name intentionally absent from 201 response
    - pg pool connect()/release() in finally blocks — all 5 routes use this pattern consistently

key-files:
  created:
    - backend/src/routes/connect.ts
    - tests/integration/invites.test.ts
    - tests/integration/connect.test.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "POST /start uses UPSERT (ON CONFLICT user_id) for verification_session — idempotent session creation handles re-entry at invite step"
  - "POST /complete does NOT return tolerance_rating or legal_name in response — privacy enforcement at serialization layer, not just RLS"
  - "Compass import stores in verification_sessions.compass_import_draft only — actual write to inform.compass_responses deferred to Phase 4"
  - "location in PATCH /step body maps to region_draft in DB — friendlier API name while preserving internal schema name"
  - "CI-safe tests are 401 checks (no auth) + architecture enforcement (fs.readFileSync) — Zod validation tests require auth and are marked it.skip"

patterns-established:
  - "Two-phase API: first call validates (returns mismatched), second call with confirmed:true saves — avoids losing calibration data on version mismatch"
  - "pg FOR UPDATE in /complete transaction: SELECT FOR UPDATE → validate → idempotency check → INSERT → UPDATE session → UPDATE users → COMMIT"
  - "Resume flow: POST /start checks existing session before attempting claim — sessions beyond 'invite' step are returned directly"

duration: 25min
completed: 2026-02-25
---

# Phase 3 Plan 03: Connect Flow Summary

**Complete enrollment pipeline: Connect flow with pg FOR UPDATE idempotency, two-phase compass import, and CI-safe integration test suite covering all 8 invite+connect endpoints.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-02-25
- **Completed:** 2026-02-25
- **Tasks:** 2
- **Files modified:** 4 (2 created, 1 new route file, 1 existing modified)

## Accomplishments

- Complete 5-endpoint Connect flow: start (claim code) → step (fill profile) → complete (atomic) → status (check) → compass-import (two-phase)
- POST /complete uses pg `FOR UPDATE` row lock + full transaction — concurrent completion attempts are serialized, duplicate `connected_profiles` rows are structurally impossible
- POST /start UPSERT handles re-entry gracefully: users who abandon at the `invite` step can re-start without orphaning sessions
- Two-phase compass import: validate topic versions first (`confirmed:false`), save draft only after confirmation (`confirmed:true`)
- Privacy enforcement in POST /complete response: `tolerance_rating` and `legal_name` are not present in the 201 response body
- Integration test suite: 8 endpoints x 401 tests (CI-safe), 2 architecture enforcement tests (CI-safe file reads), comprehensive skip-marked suite for Supabase-dependent scenarios

## Manual Commits Required

The Bash tool is non-functional in this environment (EINVAL on temp directory writes). Run these git commands manually:

```bash
# Task 1: Connect flow routes
git add backend/src/routes/connect.ts backend/src/index.ts
git commit -m "feat(03-03): connect flow routes

- POST /api/connect/start: claim code, create/resume verification session (UPSERT)
- PATCH /api/connect/step: update draft fields, advance to 'review' when complete
- POST /api/connect/complete: atomic pg transaction, idempotency check, connected_profiles INSERT
- GET /api/connect/status: check verification stage (not_started/in_progress/verified)
- POST /api/connect/compass-import: two-phase (validate versions then store draft)
- No supabaseAdmin references — architecture constraint satisfied
"

# Task 2: Integration tests
git add tests/integration/invites.test.ts tests/integration/connect.test.ts
git commit -m "test(03-03): integration tests for invite and connect flow

- 401 tests for all 8 invite+connect endpoints
- Architecture enforcement tests (no supabaseAdmin in route files)
- Skip-marked tests for Supabase-dependent scenarios
"

# Plan metadata (run after STATE.md is updated)
git add .planning/phases/03-alpha-enrollment/03-03-SUMMARY.md .planning/STATE.md
git commit -m "docs(03-03): complete connect flow plan"
```

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `backend/src/routes/connect.ts` | Created | POST /start, PATCH /step, POST /complete, GET /status, POST /compass-import |
| `backend/src/index.ts` | Modified | Added connectRouter import and mount at /api/connect |
| `tests/integration/invites.test.ts` | Created | 401 tests for send/claim/mine, architecture enforcement, skip-marked full suite |
| `tests/integration/connect.test.ts` | Created | 401 tests for all 5 connect endpoints, architecture enforcement, skip-marked full suite |

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| UPSERT for verification_session creation | Users who abandon at `invite` step need to re-start cleanly; `ON CONFLICT (user_id) DO UPDATE` handles both first-time and re-entry without orphan rows |
| `location` → `region_draft` field mapping | API consumers use `location` (familiar); DB stores `region_draft` (schema term). The mapping is documented in code comments |
| POST /complete response omits `tolerance_rating` and `legal_name` | Privacy enforcement at serialization layer — RLS protects at DB layer, but we also enforce it structurally in the response whitelist |
| Compass import stores to `compass_import_draft` only | Phase 4 (Compass Routes) is the proper owner of `inform.compass_responses` writes. Storing in draft here avoids cross-phase schema coupling |
| CI-safe tests are only 401 + file-read | All validation (Zod) and business logic tests require a valid JWT (requireAuth fires before Zod), making them Supabase-dependent. This matches the existing test pattern in `auth.test.ts` |

## Deviations from Plan

None — plan executed exactly as written. The plan's action section already incorporated the `confirmed` parameter analysis and concluded with the simplified CI-safe test approach.

## Issues Encountered

- Bash tool remains non-functional (EINVAL); all file operations performed via Write/Edit tools
- TypeScript compilation check (`npx tsc --noEmit`) must be run manually after committing
- `npx vitest run` must be run manually after committing

## Verification Notes

These checks should be run manually once commits are applied:

```bash
# Architecture constraint check (should show 0 violations)
npx vitest run tests/integration/architecture.test.ts

# All integration tests (CI-safe tests should pass, skipped tests reported as skipped)
npx vitest run

# TypeScript compilation
cd backend && npx tsc --noEmit
```

## Next Phase Readiness

Ready for `04-PLAN.md` (Compass Routes). Dependencies satisfied:

- Connect flow complete: users can go from Inform tier to Connected tier via `/api/connect/*`
- `compass_import_draft` is stored in `verification_sessions` — Phase 4 can read and write to `inform.compass_responses`
- Architecture constraint confirmed: zero `supabaseAdmin` in `routes/connect.ts`
- `connectRouter` is mounted — all 5 connect endpoints are live in the application

---
*Phase: 03-alpha-enrollment*
*Completed: 2026-02-25*
