---
phase: 66-inform-profiles-backend-foundation
plan: 03
subsystem: api
tags: [middleware, account, inform-tier, typescript]

requires:
  - phase: 66-inform-profiles-backend-foundation/66-01
    provides: inform.inform_profiles table (read in GET /me, upserted in PATCH /location-hint)

provides:
  - requireInform middleware exported from tierGuards.ts
  - GET /api/account/me includes inform_profile field for all authenticated users
  - PATCH /api/account/location-hint endpoint (Inform-tier only, stores last_essentials_location)

affects: account, tierGuards, inform-tier, profile-page

tech-stack:
  added: []
  patterns:
    - "requireInform is the inverse of requireConnected — passes when no connected_profiles row"
    - "inform_profile uses pool.query with graceful degradation (errors don't fail /me)"
    - "location-hint upserts via INSERT ON CONFLICT (defensive against missing row)"

key-files:
  created: []
  modified:
    - backend/src/middleware/tierGuards.ts
    - backend/src/routes/account.ts

key-decisions:
  - "inform_profile included for ALL tiers (null if no row) — frontend decides what to show"
  - "Graceful degradation on inform_profiles read error — /me must never fail due to inform path"
  - "PATCH /location-hint uses requireInform (not just requireAuth) — Connected users get 403 per spec"

patterns-established:
  - "requireInform: checks connected_profiles presence, inverts requireConnected logic"
  - "All inform schema reads in routes via pool.query (not PostgREST)"

duration: 10min
completed: 2026-04-27
---

# Plan 66-03: Middleware + /me inform_profile + location-hint Summary

**requireInform middleware + inform_profile on GET /me for all tiers + PATCH /location-hint upsert for Inform-tier users**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-04-27
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `requireInform` exported from `tierGuards.ts` — passes for Inform-tier (no connected_profiles row), returns 403 for Connected/Empowered
- `GET /api/account/me` now includes `inform_profile: { yellow_gem_balance, last_essentials_location }` for all authenticated users; graceful degradation on DB error
- `PATCH /api/account/location-hint` route added — guarded by `requireAuth + requireInform`, stores location JSON via pool.query INSERT ON CONFLICT upsert

## Task Commits

1. **Task 1: requireInform middleware** — `aaacf0e` (feat)
2. **Task 2: inform_profile on GET /me + PATCH /location-hint** — `a7cc5d1` (feat)

## Files Created/Modified

- `backend/src/middleware/tierGuards.ts` — added requireInform export
- `backend/src/routes/account.ts` — requireInform import, step 4c inform_profile read, inform_profile in meResponse, PATCH /location-hint route

## Decisions Made

- `inform_profile` included for all tiers (null when no row exists) — Phase 68 frontend code can always read the field without tier-branching
- Pool.query graceful degradation for inform_profiles read — /me is a critical path and must not fail due to a secondary read

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. TypeScript compiled cleanly on first attempt.

## Next Phase Readiness

Phase 66 all 3 plans complete. Ready for verification then Phase 67 (Login Hub + Inform Signup Flow).

---
*Phase: 66-inform-profiles-backend-foundation*
*Completed: 2026-04-27*
