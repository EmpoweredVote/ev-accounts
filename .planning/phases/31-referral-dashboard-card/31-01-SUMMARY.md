---
phase: 31-referral-dashboard-card
plan: 01
subsystem: ui
tags: [react, referral, dashboard, invite, connected-profile]

# Dependency graph
requires:
  - phase: 30-profile-hub-ui
    provides: DashboardPage baseline with cp and apiFetch patterns
  - phase: 19-location-schema-rpcs
    provides: connected_profiles schema that referral columns extend
provides:
  - Formal verification that all four Phase 31 referral requirements are satisfied by commit 97b2dab
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Referral card state driven entirely by GET /api/referral — no client-side guessing"
    - "Render guard: {cp && referral && (...)} — card only shown when both connected_profile and API data loaded"
    - "requireConnected middleware gates /api/referral — Inform-tier users never trigger the fetch"

key-files:
  created: []
  modified: []

key-decisions:
  - "Phase 31 was implemented ahead-of-schedule during v1.4 work (commit 97b2dab). This plan formally verifies all requirements are met."
  - "No new code required — all four REF requirements confirmed satisfied by existing implementation."

patterns-established: []

# Metrics
duration: 5min
completed: 2026-03-19
---

# Phase 31 Plan 01: Referral Dashboard Card Summary

**Referral invite card with locked/waiting/active states, driven entirely by GET /api/referral, confirmed satisfied in commit 97b2dab.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-19T07:30:02Z
- **Completed:** 2026-03-19T07:35:00Z
- **Tasks:** 1 of 1
- **Files modified:** 0 (verification-only)

## Accomplishments

- Confirmed REF-01: Active state shows referral code with one-click copy and "Copied!" feedback
- Confirmed REF-02: Locked state renders lock icon and "Reach level 2 to unlock" with no code visible
- Confirmed REF-03: Waiting state shows pulsing dot, "Friend joined!", invitee level, and refresh explanation
- Confirmed REF-04: `ReferralState` interface matches API contract exactly; fetch gated on `connected_profile`; render guard `{cp && referral}`

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify all four referral card requirements against existing code** - `5c198d7` (feat)

**Plan metadata:** (included in task commit — verification plan has no separate metadata commit)

## Files Created/Modified

None — verification-only plan. All implementation already shipped in:

- `app/src/pages/DashboardPage.tsx` — referral card UI (lines 28–33, 135–136, 150–154, 156–162, 277–332)
- `backend/src/routes/referral.ts` — `GET /api/referral` route with `requireAuth` + `requireConnected`
- `backend/src/lib/referralService.ts` — `getReferralState()` query against `connect.connected_profiles`
- `supabase/migrations/20260318000001_referral_codes.sql` — schema columns and RPCs

## Decisions Made

Phase 31 was implemented ahead-of-schedule during v1.4 work. This plan formally verified the implementation rather than creating new code. All four requirements mapped to specific line ranges in the existing file.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 31 complete. All four referral requirements confirmed satisfied.
- Ready to proceed to Phase 32 (CompassV2 Integration Doc) or Phase 33.
- No blockers introduced by this phase.

---
*Phase: 31-referral-dashboard-card*
*Completed: 2026-03-19*
