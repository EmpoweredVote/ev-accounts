---
phase: 59-referral-code-system
plan: "02"
subsystem: api
tags: [postgres, pool, invites, quota, admin, express, typescript]

# Dependency graph
requires:
  - phase: 59-01
    provides: DB schema — invite_chains, invite_codes, sanction_invitee RPC, generate_invite_code_if_allowed RPC, get_my_invitees RPC, get_invite_cap_for_level fn, invite_cap_override column

provides:
  - inviteQuotaService.ts with generateInviteCodeIfAllowed, getMyInvitees, sanctionInvitee, clearSlotLock, setInviteCapOverride, getInviteOverrides
  - POST /api/invites/generate — quota-aware code generation (CAP_REACHED at limit)
  - GET /api/invites/my-invitees — invitee list with active_count, cap, can_generate
  - POST /api/admin/accounts/:userId/invite-cap-override — sets/clears explicit cap with audit log
  - GET /api/admin/invite-overrides — all users with active overrides + effective_cap
  - Suspend route integration — sanction_invitee called non-blockingly on suspension
  - Unsuspend route integration — slot_locked_until cleared non-blockingly on reinstatement

affects: [59-03-frontend-invitee-dashboard, 59-04-admin-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-blocking side-effects: sanction/slot-clear wrapped in inner try/catch so suspension succeeds even if accountability RPC fails"
    - "Fallback cap query: getMyInvitees queries cap directly when RPC returns no rows (user with zero invitees)"
    - "Unlimited sentinel: invite_cap_override = -1 maps to 2147483647 (max int) for can_generate arithmetic"

key-files:
  created:
    - backend/src/lib/inviteQuotaService.ts
  modified:
    - backend/src/routes/invites.ts
    - backend/src/routes/admin.ts

key-decisions:
  - "sanctionInvitee and clearSlotLock are non-blocking in the suspend/unsuspend routes — account state change must not be rolled back due to a quota accounting failure"
  - "getMyInvitees handles empty-invitee case with a direct cap query rather than returning incorrect zeros for can_generate"
  - "InviteCapSchema uses z.union([z.literal(-1), z.number().int().min(1), z.null()]) to enforce the three valid override states"

patterns-established:
  - "Non-blocking side-effects pattern: inner try/catch with console.error, outer try/catch handles primary operation"
  - "All connect schema reads/writes via pool.query() — never PostgREST"

# Metrics
duration: 2min
completed: 2026-04-09
---

# Phase 59 Plan 02: Backend Service and Routes Summary

**inviteQuotaService.ts + /generate + /my-invitees routes + admin cap-override + non-blocking sanction/slot-unlock on suspend/unsuspend**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-09T02:59:13Z
- **Completed:** 2026-04-09T03:01:36Z
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Created `inviteQuotaService.ts` with six exported functions covering all quota operations
- Added `POST /api/invites/generate` (quota-aware, returns CAP_REACHED with active_count/cap context) and `GET /api/invites/my-invitees` (full invitee list with quota summary)
- Extended admin suspend/unsuspend with non-blocking sanction/slot-unlock side-effects and added `POST /api/admin/accounts/:userId/invite-cap-override` + `GET /api/admin/invite-overrides`

## Task Commits

Each task was committed atomically:

1. **Task 1: inviteQuotaService + /generate + /my-invitees routes** - `f410447` (feat)
2. **Task 2: admin invite-cap-override + sanction/unsuspend integration** - `4fa25db` (feat)

**Plan metadata:** `(docs commit follows)`

## Files Created/Modified

- `backend/src/lib/inviteQuotaService.ts` — all quota service functions: generateInviteCodeIfAllowed, getMyInvitees, sanctionInvitee, clearSlotLock, setInviteCapOverride, getInviteOverrides
- `backend/src/routes/invites.ts` — added import + POST /generate + GET /my-invitees routes
- `backend/src/routes/admin.ts` — added import, InviteCapSchema, suspend/unsuspend integrations, invite-cap-override + invite-overrides routes

## Decisions Made

- **Non-blocking accountability:** sanctionInvitee and clearSlotLock wrapped in inner try/catch so a quota RPC failure cannot roll back a suspension or unsuspension — account standing change is authoritative; quota accounting is best-effort.
- **Empty-invitee fallback:** getMyInvitees falls back to a direct connected_profiles cap query when the get_my_invitees RPC returns no rows, ensuring can_generate reflects true quota even for users with zero invitees.
- **InviteCapSchema union:** `z.union([z.literal(-1), z.number().int().min(1), z.null()])` enforces all three valid override states exactly.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — TypeScript passed zero errors on both tasks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `/api/invites/generate` and `/api/invites/my-invitees` ready for Phase 59-03 frontend dashboard
- Admin override endpoints ready for Phase 59-04 admin UI
- All DB RPCs (generate_invite_code_if_allowed, get_my_invitees, sanction_invitee) must exist in production before routes will function — confirm Phase 59-01 migration was applied

---
*Phase: 59-referral-code-system*
*Completed: 2026-04-09*
