---
phase: quick
plan: 009
subsystem: infra
tags: [cron, node-cron, postgres, supabase, districts, jurisdiction, geo_ids]

# Dependency graph
requires:
  - phase: 19-location-schema-rpcs
    provides: resolve_user_jurisdiction RPC and geo_id columns on connected_profiles
provides:
  - Weekly cron job re-verifying district geo_id assignments for all Connected users with coordinates
  - districts_last_verified_at column tracking last verification timestamp per user
affects: [location, districts, cron, connected_profiles]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-user non-fatal try/catch in cron loop, structured JSON job summary log, conditional UPDATE (all geo columns vs timestamp-only)]

key-files:
  created:
    - supabase/migrations/20260329000054_add_districts_last_verified_at.sql
    - backend/src/lib/districtStalenessService.ts
    - backend/src/cron/districtStaleness.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "Separate UPDATE paths: full geo_id + name update when any value changed, timestamp-only update when nothing changed (prevents column churn)"
  - "Does NOT update jurisdiction_state or jurisdiction_city — those come from geocoding (set-location), not jurisdiction resolution"
  - "Per-user errors are non-fatal — loop continues, failed counter incremented"

patterns-established:
  - "District staleness pattern: compare RPC result keys (congressional, state_senate, etc.) against stored _geo_id columns"

# Metrics
duration: 4min
completed: 2026-03-29
---

# Quick Task 009: Weekly District Staleness Check Cron Summary

**Weekly cron at Sunday 03:00 UTC re-resolves district geo_ids for all users with coordinates, writing only changed columns to prevent churn, with districts_last_verified_at always stamped**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-29T04:27:55Z
- **Completed:** 2026-03-30T04:31:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `districts_last_verified_at TIMESTAMPTZ` column to `connect.connected_profiles` via migration (applied to production)
- Implemented `runDistrictStalenessCheck()` service that queries all users with stored coordinates, re-resolves via `resolve_user_jurisdiction` RPC, and writes only changed geo_ids
- Registered `startDistrictStalenessCron()` at `0 3 * * 0` (weekly Sunday 03:00 UTC) alongside calibration-lapse and campaign-finance crons
- Verified server boots with all three cron jobs registering in log output

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration + district staleness service** - `061a9f4` (feat)
2. **Task 2: Cron registration + wiring** - `3fee345` (feat)

## Files Created/Modified

- `supabase/migrations/20260329000054_add_districts_last_verified_at.sql` - Adds districts_last_verified_at column
- `backend/src/lib/districtStalenessService.ts` - Core job logic (runDistrictStalenessCheck)
- `backend/src/cron/districtStaleness.ts` - node-cron registration (startDistrictStalenessCron)
- `backend/src/index.ts` - Import and call added alongside existing cron registrations

## Decisions Made

- **Separate UPDATE paths**: When geo_ids changed, update all 10 geo_id/name columns + `districts_last_verified_at`. When nothing changed, update only `districts_last_verified_at`. This prevents noisy writes to columns that didn't change.
- **No `jurisdiction_state` / `jurisdiction_city` updates**: These come from geocoding (set-location flow), not from `resolve_user_jurisdiction`. Only the 5 district types (congressional, state_senate, state_house, county, school_district) are re-resolved.
- **Non-fatal per-user loop**: A single user's failure (RPC error, network blip) increments `failed` counter and continues — does not abort the job for other users.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Pre-existing TypeScript error in `backend/src/lambda/sqs-worker.ts` (missing `aws-lambda` types) — not related to this task. All new files compile without errors.
- Port 3000 already in use during startup test (dev server running) — cron registration log lines appeared before the port error, confirming correct registration.

## Next Phase Readiness

- District staleness cron is live and will fire next Sunday 03:00 UTC
- If districts are verified as needing re-resolution sooner, `runDistrictStalenessCheck()` can be invoked ad-hoc
- No blockers

---
*Phase: quick*
*Completed: 2026-03-29*
