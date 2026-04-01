---
phase: 50-precise-representatives-pre-phase-49-users
plan: 02
subsystem: database
tags: [postgres, pg, backfill, geo, jurisdiction, connected_profiles, resolve_user_jurisdiction]

# Dependency graph
requires:
  - phase: 49-stored-jurisdiction
    provides: connect.connected_profiles geo_id columns + resolve_user_jurisdiction RPC
provides:
  - One-time backfill script that populates 10 geo_id + district name columns for pre-Phase-49 users
affects:
  - representatives/me route (50-01) — backfill ensures pre-Phase-49 users have stored geo_ids to serve

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scripts call SECURITY DEFINER RPCs via pool.query (SELECT schema.fn($1)) — no Supabase client"
    - "--dry-run pattern: all writes gated behind if (!isDryRun)"

key-files:
  created:
    - backend/scripts/backfill-pre-phase49-geo-ids.ts
  modified: []

key-decisions:
  - "location_consent = true mandatory in WHERE clause — RPC raises EXCEPTION for consent=false users"
  - "Geofence gaps (no boundary match) counted as stillNull, not errors — expected for out-of-state users"
  - "Per-user loop with try/catch — one error does not abort the entire run"

patterns-established:
  - "Backfill scripts use pool.query for all DB access (no Supabase client in scripts)"

# Metrics
duration: 2min
completed: 2026-04-01
---

# Phase 50 Plan 02: Backfill Pre-Phase-49 Geo IDs Summary

**One-time backfill script that calls resolve_user_jurisdiction per Connected user and writes 10 geo_id + district name columns for those with encrypted coordinates but null congressional_geo_id**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-01T16:43:19Z
- **Completed:** 2026-04-01T16:45:17Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `backend/scripts/backfill-pre-phase49-geo-ids.ts` with full dry-run support and per-user logging
- WHERE clause correctly filters to `encrypted_lat IS NOT NULL AND location_consent = true AND congressional_geo_id IS NULL` to avoid RPC exceptions
- Writes all 10 jurisdiction columns (5 geo_ids + 5 district names) in a single UPDATE per user
- Geofence gaps (users outside loaded boundaries) logged as expected, not treated as errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create backfill-pre-phase49-geo-ids.ts** - `132f9d9` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/scripts/backfill-pre-phase49-geo-ids.ts` - One-time backfill script: finds pre-Phase-49 Connected users with encrypted coords but null geo_ids, calls resolve_user_jurisdiction RPC per user, writes 10 columns back

## Decisions Made

- `location_consent = true` mandatory in query — the `resolve_user_jurisdiction` RPC raises an EXCEPTION if a user lacks consent. Excluding these users at the query level avoids errors and respects user privacy.
- Geofence gaps counted as `stillNull`, not errors — users in states not yet loaded (outside CA/IN) will have no boundary match; this is expected and not actionable.
- Per-user try/catch with continue — a single RPC error (e.g., Vault key issue) does not abort the entire backfill run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Pre-existing TypeScript error in `src/lambda/sqs-worker.ts` (missing `aws-lambda` types, unrelated to this script). Confirmed zero errors attributable to the new script via `tsc --noEmit | grep backfill-pre-phase49`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Backfill script is ready to run against production: `cd backend && npx tsx scripts/backfill-pre-phase49-geo-ids.ts --dry-run` first, then without flag
- Phase 50 complete once 50-01 (Path 1.5 in /representatives/me) is also shipped

---
*Phase: 50-precise-representatives-pre-phase-49-users*
*Completed: 2026-04-01*
