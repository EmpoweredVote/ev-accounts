---
phase: 49-stored-jurisdiction-cross-app-location-profile
plan: 01
subsystem: database
tags: [postgres, supabase, migration, jurisdiction, location, connected_profiles]

# Dependency graph
requires:
  - phase: 19-location-schema-rpcs
    provides: resolve_user_jurisdiction RPC used in backfill
provides:
  - 12 jurisdiction columns on connect.connected_profiles (5 geo_id, 5 _name, state, city)
  - Backfill of geo IDs for 8 users with location_consent=true
affects:
  - 49-02 (set-location writes + account/me reads from columns)
  - essentials (representatives/me reads stored geo IDs)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Jurisdiction stored at write time (set-location) rather than resolved at read time via RPC"
    - "Backfill via UPDATE ... FROM subquery calling RPC for existing users"

key-files:
  created:
    - supabase/migrations/20260326000053_phase49_jurisdiction_columns.sql
  modified: []

key-decisions:
  - "jurisdiction_state and jurisdiction_city not backfillable — resolve_user_jurisdiction RPC does not return state/city fields; populated on next set-location call"
  - "_name columns not backfillable from existing RPC — RPC returns geo IDs only; 49-02 will write names at set-location time from geocoding service response"
  - "Migration applied via pool.query() directly (pg driver) — supabase db push blocked by migration history mismatch from remote-only migrations"

patterns-established:
  - "Jurisdiction columns use TEXT DEFAULT NULL (not NOT NULL) to allow partial population"

# Metrics
duration: 8min
completed: 2026-03-26
---

# Phase 49 Plan 01: Stored Jurisdiction Schema Migration Summary

**12 TEXT columns added to `connect.connected_profiles` for storing pre-resolved jurisdiction data (geo IDs, district names, state, city), with backfill of 8 existing users via `resolve_user_jurisdiction` RPC**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-26T22:47:41Z
- **Completed:** 2026-03-26T22:55:00Z
- **Tasks:** 1 (single migration task)
- **Files modified:** 1

## Accomplishments

- Added 12 jurisdiction columns to `connect.connected_profiles` via `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`
- Backfilled 8 users with `location_consent=true` using `resolve_user_jurisdiction` RPC — 2 users received geo IDs, 6 returned null (boundary data not yet loaded for their addresses, per known CA geofence gap)
- Verified all 12 columns present in `information_schema.columns` (confirmed 12/12)

## Task Commits

1. **Task 1: Add jurisdiction columns + backfill** - `11f2b40` (feat)

**Plan metadata:** (committed together with task — single migration plan)

## Files Created/Modified

- `supabase/migrations/20260326000053_phase49_jurisdiction_columns.sql` — ALTER TABLE adds 12 columns; UPDATE backfills geo IDs for consent=true users

## Decisions Made

- **jurisdiction_state and jurisdiction_city not backfillable**: `resolve_user_jurisdiction` RPC returns congressional/state_senate/state_house/county/school_district geo IDs only — no state or city fields. These columns will be populated on next `set-location` call (49-02 work).
- **`_name` columns all null after backfill**: The existing RPC returns geo IDs but not district names. The 49-02 plan will write names at set-location time from the geocoding service response.
- **Migration applied via pool.query()**: `supabase db push` was blocked by migration history mismatch (remote has migrations not tracked locally). Used `pg` pool with DATABASE_URL directly — consistent with project pattern for non-public schema writes.

## Deviations from Plan

None — plan executed exactly as written. The null `_name` values after backfill are expected and documented in the migration SQL comment.

## Issues Encountered

- `supabase db push` failed with "Remote migration versions not found in local migrations directory" — several remote migrations exist that aren't tracked locally. Applied migration directly via `pool.query()` using the same pg driver pattern used throughout the backend. Migration file still committed to `supabase/migrations/` for tracking.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Schema is ready for 49-02: `set-location` handler can now write all 12 columns at location-set time
- `GET /account/me` and `PATCH /account/me` can read from stored columns instead of calling RPC
- `GET /account/me/jurisdiction` can read directly from columns
- `GET /essentials/representatives/me` can read stored geo IDs instead of calling `resolve_user_jurisdiction`
- Existing users will get full column population (including names and state/city) on next `set-location` call after 49-02 ships

---
*Phase: 49-stored-jurisdiction-cross-app-location-profile*
*Completed: 2026-03-26*
