---
phase: 61-auth-flow-restyle
plan: 05
subsystem: auth
tags: [postgres, supabase, express, zod, typescript, rpc, migration]

# Dependency graph
requires:
  - phase: 61-auth-flow-restyle
    provides: Auth flow restyle context; SignupPage will add display_name field (61-04)
provides:
  - Migration 071: signup_with_invite RPC updated to accept and store p_display_name
  - POST /api/auth/signup Zod schema requires display_name field
  - adminRpc call passes p_display_name to signup_with_invite
  - database.types.ts Args type updated with p_display_name: string
affects:
  - 61-04 (SignupPage restyle — can now add display_name AuthInput with backend ready)
  - 62 (Onboarding restyle — connected_profiles.display_name is populated at creation, not deferred)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic signup: display_name stored in same RPC transaction as legal_name + invite claim"
    - "CREATE OR REPLACE FUNCTION for non-breaking RPC updates — no DROP needed"

key-files:
  created:
    - backend/migrations/071_signup_with_invite_display_name.sql
  modified:
    - backend/src/routes/auth.ts
    - backend/src/types/database.types.ts

key-decisions:
  - "display_name required (not optional) in Zod schema — every Connected account must have a civic pseudonym from creation"
  - "Fourth parameter position: p_user_id, p_legal_name, p_invite_code, p_display_name — matches SQL function signature order"
  - "Faithful copy of migration 036 logic — only changed signature and INSERT value; all validation/chain/idempotency logic preserved"

patterns-established:
  - "Migration 071 applies as CREATE OR REPLACE — no DROP first, safe to re-run"

# Metrics
duration: 4min
completed: 2026-04-25
---

# Phase 61 Plan 05: Backend display_name Signup Support Summary

**signup_with_invite RPC updated to accept p_display_name and store it atomically; Express Zod schema requires display_name on POST /signup**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-25T20:50:10Z
- **Completed:** 2026-04-25T20:53:52Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Migration 071 replaces `connect.signup_with_invite` with a version that accepts `p_display_name TEXT` as a fourth parameter, storing it in `connect.connected_profiles.display_name` instead of NULL — applied to production
- `POST /api/auth/signup` Zod schema now requires `display_name: z.string().min(1).max(100)`, making the civic pseudonym mandatory for every Connected account from the moment of creation
- `database.types.ts` Args type updated so TypeScript resolves the `adminRpc('signup_with_invite', ...)` call cleanly with all four parameters

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration 071 — add p_display_name to signup_with_invite RPC** - `9ad4d4b` (feat)
2. **Task 2: Update auth.ts — add display_name to Zod schema and RPC call** - `887bcf0` (feat)
3. **Task 3: Update database.types.ts — add p_display_name to signup_with_invite Args** - `fe8a3d7` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `backend/migrations/071_signup_with_invite_display_name.sql` — New migration: `CREATE OR REPLACE FUNCTION connect.signup_with_invite` with p_display_name fourth parameter; applied to production via psql
- `backend/src/routes/auth.ts` — Added `display_name: z.string().min(1).max(100)` to signUpBodySchema, added to destructuring, added `p_display_name: display_name` to adminRpc call
- `backend/src/types/database.types.ts` — Added `p_display_name: string` to signup_with_invite Args type (line 588)

## Decisions Made

- `display_name` is required (not `.optional()`) in the Zod schema — this enforces that every Connected account must choose a civic pseudonym at signup time; the frontend (Plan 61-04) will provide the required AuthInput field
- Followed migration 036's logic exactly, changing only two things: the function signature (add `p_display_name TEXT`) and the INSERT VALUES (replace `NULL` with `p_display_name`). The self-invite guard, three-path INVALID_OR_CLAIMED_CODE block, UPDATE with `updated_at`, and conditional invite chain insert are all preserved unchanged.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. Migration applied cleanly (`CREATE FUNCTION` returned). TypeScript compiled with zero errors after all three changes.

## User Setup Required

None — migration applied directly to production. No environment variable changes required.

## Next Phase Readiness

- Backend is ready to receive `display_name` from the signup form
- Plan 61-04 (SignupPage restyle) can now add the `display_name` AuthInput field — the backend will accept and persist it
- Phase 62 (Onboarding restyle) benefits: `connected_profiles.display_name` is populated at account creation, not deferred, so the onboarding flow can assume it already exists

---
*Phase: 61-auth-flow-restyle*
*Completed: 2026-04-25*
