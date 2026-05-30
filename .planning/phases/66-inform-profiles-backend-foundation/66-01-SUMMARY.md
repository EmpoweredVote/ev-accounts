---
phase: 66-inform-profiles-backend-foundation
plan: 01
subsystem: database
tags: [postgres, supabase, rpc, inform-tier, yellow-gems, trigger, migration]

# Dependency graph
requires:
  - phase: connect-signup-flow
    provides: connect.signup_with_invite RPC (migration 071 with display_name)
  - phase: gem-system
    provides: connect.connected_profiles.gem_balance_yellow column
provides:
  - inform.inform_profiles table (user_id PK, yellow_gem_balance INT DEFAULT 0, last_essentials_location JSONB, created_at TIMESTAMPTZ)
  - inform.handle_new_user() trigger function (SECURITY DEFINER, SET search_path = '')
  - trg_create_inform_profile AFTER INSERT trigger on public.users
  - Backfill: all 11 existing users have inform_profiles rows
  - Updated signup_with_invite that atomically transfers yellow_gem_balance to connected_profiles.gem_balance_yellow on Connect
affects:
  - 66-02 (inform profile API — GET /api/account/me inform_profile object)
  - 66-03 (yellow gem award endpoint — writes to inform_profiles.yellow_gem_balance)
  - Phase 67 (Login Hub + Inform Signup Flow — signup auto-creates inform_profiles row)
  - Phase 68 (Yellow Inform Profile Page — reads inform_profile object)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inform-tier auto-profile: AFTER INSERT trigger on public.users creates inform_profiles row — same pattern as connect/empower tiers"
    - "Yellow gem transfer on Connect: SELECT FOR UPDATE on inform_profiles before zeroing + seeding connected_profiles.gem_balance_yellow = COALESCE(v_inform_balance, 0)"
    - "Advisory lock pattern extended: FOR UPDATE on inform_profiles row prevents concurrent gem award racing during Connect transition"

key-files:
  created:
    - backend/migrations/084_inform_profiles.sql
    - backend/migrations/085_signup_with_invite_yellow_transfer.sql
  modified: []

key-decisions:
  - "IF FOUND guard on inform_profiles zero-out: UPDATE only fires if row exists — handles edge case where trigger hasn't run yet for a user"
  - "COALESCE(v_inform_balance, 0) in connected_profiles INSERT: new Connected users with no Inform history start with 0 yellow gems cleanly"
  - "Separate migrations for table (084) and RPC update (085): allows independent rollback if gem transfer logic needs adjustment post-deploy"

patterns-established:
  - "Tier transition gem transfer: zero inform_profiles.yellow_gem_balance then seed connected_profiles.gem_balance_yellow atomically in the same RPC transaction"
  - "FOR UPDATE lock on inform_profiles before gem mutation: prevents concurrent award races during tier transition"

# Metrics
duration: 15min
completed: 2026-04-27
---

# Phase 66 Plan 01: Inform Profiles Backend Foundation Summary

**`inform.inform_profiles` table live with auto-creation trigger and atomic yellow gem transfer on Connect via updated `signup_with_invite` RPC**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-27T20:57:27Z
- **Completed:** 2026-04-27T21:12:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `inform.inform_profiles` table created in production with correct schema (user_id PK, yellow_gem_balance INT DEFAULT 0, last_essentials_location JSONB, created_at TIMESTAMPTZ)
- Backfill complete — all 11 existing users have a corresponding inform_profiles row
- `trg_create_inform_profile` AFTER INSERT trigger on `public.users` auto-creates profile for every new signup
- `connect.signup_with_invite` updated to atomically zero inform_profiles.yellow_gem_balance and seed connected_profiles.gem_balance_yellow on Connect — no yellow gems lost during tier transition

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration 084 — inform.inform_profiles table, trigger, backfill** - `4d173c6` (feat)
2. **Task 2: Migration 085 — signup_with_invite yellow gem balance transfer** - `a612a55` (feat)

**Plan metadata:** (pending — this commit)

## Files Created/Modified

- `backend/migrations/084_inform_profiles.sql` — Table creation, index, trigger function, trigger drop/create, backfill INSERT
- `backend/migrations/085_signup_with_invite_yellow_transfer.sql` — Replaces signup_with_invite RPC to capture + zero inform_profiles.yellow_gem_balance then seed connected_profiles.gem_balance_yellow

## Decisions Made

- **IF FOUND guard on zero-out UPDATE**: The UPDATE on inform_profiles.yellow_gem_balance is guarded by `IF FOUND` — only fires when the row exists. Handles the edge case where a user was created before the trigger was deployed.
- **COALESCE(v_inform_balance, 0)** in the connected_profiles INSERT: ensures new Connected users with no prior Inform history start at 0 yellow gems cleanly, even if inform_profiles row somehow doesn't exist.
- **Separate migrations (084 vs 085)**: Table creation and RPC update kept separate so either can be rolled back independently without affecting the other.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Both migrations applied to production via Supabase Management API.

## Next Phase Readiness

- **66-02 ready**: `inform.inform_profiles` exists; plan 66-02 can add the `GET /api/account/me` inform_profile object and the POST `/api/inform/signup` endpoint.
- **66-03 ready**: yellow_gem_balance column exists; plan 66-03 can implement the gem award endpoint that writes to `inform_profiles.yellow_gem_balance`.
- **No blockers**: trigger verified live (test: insert any new user, row auto-appears in inform_profiles). Gem transfer logic verified in pg_proc.

---
*Phase: 66-inform-profiles-backend-foundation*
*Completed: 2026-04-27*
