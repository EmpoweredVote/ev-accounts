---
phase: 18-compassv2-api-contract
plan: 03
subsystem: api
tags: [express, supabase, zod, typescript, compass, guest-state, rpc]

# Dependency graph
requires:
  - phase: 18-compassv2-api-contract
    provides: Phase 18 context — CV2 API contract requirements and guest state migration RPC
  - phase: 09-xp-leveling
    provides: total_xp column, calculate_level RPC, connected_profiles structure
provides:
  - GET /api/account/me returns completed_onboarding at response root (not only inside connected_profile)
  - PATCH /api/account/me returns completed_onboarding at response root
  - POST /api/auth/signup accepts optional guest_state for atomic compass state migration
  - migrate_guest_compass_state RPC called after signup when guest_state present; errors non-fatal
affects:
  - 18-04 (remaining CV2 compatibility tasks)
  - CompassV2 frontend — reads completed_onboarding from root of /me response

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Root field promotion: additive change — field added at root AND kept in nested block for backward compat"
    - "Non-fatal RPC: try/catch wraps post-signup side effects; errors logged, signup never fails"
    - "Separate signup schema: signUpBodySchema extends base auth fields without touching authBodySchema used by login"

key-files:
  created: []
  modified:
    - backend/src/routes/account.ts
    - backend/src/routes/auth.ts

key-decisions:
  - "completed_onboarding added at root AND kept in connected_profile — additive only, no backward-compat break"
  - "guest_state migration is non-fatal: try/catch swallows errors, signup always returns 201 on success"
  - "signUpBodySchema created separately from authBodySchema — login schema stays minimal (email+password only)"
  - "p_selected_topics passed as null when absent/empty so RPC null guard skips the UPDATE"

patterns-established:
  - "Non-fatal post-signup side effect: wrap in try/catch, console.error, never block response"
  - "Root field promotion pattern: dual presence (root + nested) for CV2 compatibility"

# Metrics
duration: 3min
completed: 2026-03-10
---

# Phase 18 Plan 03: CompassV2 /me Response and Guest State Migration Summary

**`completed_onboarding` promoted to root of GET/PATCH /me; POST /signup now accepts optional `guest_state` and atomically migrates anonymous compass answers via RPC**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-10T14:09:47Z
- **Completed:** 2026-03-10T14:12:18Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `GET /api/account/me` now returns `completed_onboarding: boolean` at the response root (in addition to inside `connected_profile`); Inform-tier users get `false`
- `PATCH /api/account/me` returns the same root-level field with identical semantics
- `POST /api/auth/signup` accepts an optional `guest_state: { answers, selected_topics }` body field; when present, calls `migrate_guest_compass_state` RPC after account creation with errors swallowed

## Task Commits

Each task was committed atomically:

1. **Task 1: Promote completed_onboarding to root of GET/PATCH /me** - `f2d1066` (feat)
2. **Task 2: Add optional guest_state to POST /signup with atomic RPC migration** - `806184b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/routes/account.ts` - Added `completed_onboarding: connected?.completed_onboarding ?? false` at root of meResponse in both GET and PATCH handlers
- `backend/src/routes/auth.ts` - Added `signUpBodySchema` with optional `guest_state`, imported `adminRpc`, added non-fatal RPC call after successful signup

## Decisions Made

- **Additive root promotion:** `completed_onboarding` is now at both root and inside `connected_profile`. This avoids breaking any callers that read from the nested location while satisfying CompassV2's expectation of a root field.
- **Non-fatal migration:** Guest state migration is a best-effort side effect. The account is created successfully regardless. Errors are logged at `console.error` for ops visibility.
- **Separate signup schema:** `signUpBodySchema` is a new schema rather than extending `authBodySchema`. The login route continues to use the minimal schema. Keeps concerns cleanly separated.
- **Null for empty selected_topics:** `p_selected_topics` is passed as `null` (not `[]`) when absent or empty, so the RPC's null guard skips the `UPDATE` to `selected_topics` column. This avoids overwriting existing data in edge cases.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CompassV2 frontend can now read `completed_onboarding` from the root of `/me` responses without special casing
- Guest anonymous compass sessions will survive signup and appear immediately after account creation
- 18-04 can proceed (remaining CV2 compatibility tasks)

---
*Phase: 18-compassv2-api-contract*
*Completed: 2026-03-10*
