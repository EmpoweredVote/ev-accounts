---
phase: 66-inform-profiles-backend-foundation
plan: 02
subsystem: api
tags: [gems, postgres, rpc, typescript]

requires:
  - phase: 66-inform-profiles-backend-foundation/66-01
    provides: inform.inform_profiles table (referenced by award_inform_yellow_gem RPC)

provides:
  - inform.yellow_gem_events idempotency ledger table
  - inform.award_inform_yellow_gem SECURITY DEFINER RPC
  - Tier-branching in awardGems() — Inform-tier → inform path, Connected → existing RPC
  - HTTP 422 for blue/red gem awards to Inform-tier users (INFORM_TIER_NO_BLUE_RED)

affects: gems, gemService, inform-tier, award-gems

tech-stack:
  added: []
  patterns:
    - "Tier check via pool.query EXISTS on connected_profiles before gem award"
    - "Private helper pattern (awardInformYellowGem) for routing without changing call site"
    - "Double-check idempotency: pre-check before lock + re-check after lock"

key-files:
  created:
    - backend/migrations/086_award_inform_yellow_gem.sql
  modified:
    - backend/src/lib/gemService.ts
    - backend/src/routes/gems.ts

key-decisions:
  - "Branch in awardGems() via pool.query EXISTS — callers don't need to know tier"
  - "Separate inform.yellow_gem_events ledger (not in-table idempotency) — mirrors connect pattern"
  - "INFORM_TIER_NO_BLUE_RED → 422 not 403 — semantically a bad request, not access denied"

patterns-established:
  - "Inform-tier gem writes: pool.query → inform.award_inform_yellow_gem RPC (never PostgREST)"
  - "Advisory lock for Inform gem concurrency: md5(user_id) → BIT(60) → BIGINT lock key"

duration: 12min
completed: 2026-04-27
---

# Plan 66-02: Yellow Gem Routing Summary

**inform.yellow_gem_events ledger + award_inform_yellow_gem RPC + tier-branching in awardGems() so POST /api/gems/award routes yellow gems to Inform-tier users without callers changing**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-04-27
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Migration 086 applied: `inform.yellow_gem_events` table with idempotency unique constraint and `inform.award_inform_yellow_gem` SECURITY DEFINER RPC mirroring the connect.award_gems double-check + advisory lock pattern
- `awardGems()` in gemService.ts now checks `connect.connected_profiles` existence first; Inform-tier users route to `awardInformYellowGem()` helper; Connected-tier users continue to the existing `award_gems` RPC unchanged
- Blue/red gem awards for Inform-tier users throw `INFORM_TIER_NO_BLUE_RED` → HTTP 422 in gems.ts

## Task Commits

1. **Task 1: Migration 086** — `63e3bab` (feat)
2. **Task 2: gemService tier-branching + gems.ts 422** — `fe026cd` (feat)

## Files Created/Modified

- `backend/migrations/086_award_inform_yellow_gem.sql` — yellow_gem_events table + award_inform_yellow_gem RPC
- `backend/src/lib/gemService.ts` — pool import, awardInformYellowGem helper, tier branch in awardGems()
- `backend/src/routes/gems.ts` — INFORM_TIER_NO_BLUE_RED → HTTP 422 handler

## Decisions Made

- Tier check is eager (before calling award_gems RPC), not lazy — required to return 422 for blue/red before the RPC throws NOT_CONNECTED
- `awardInformYellowGem` is a private (unexported) function — only awardGems() should call it

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

Wave 2 (plan 66-03) can now proceed: requireInform middleware + GET /me inform_profile field + PATCH /location-hint route.

---
*Phase: 66-inform-profiles-backend-foundation*
*Completed: 2026-04-27*
