---
phase: quick-018
plan: 01
subsystem: database
tags: [postgres, postgis, elections, jurisdiction, LA, geofence, migration]

# Dependency graph
requires:
  - phase: quick-014
    provides: city_council_geo_id column and resolve_user_jurisdiction RPC (063 + 064 pattern)
  - phase: quick-017
    provides: 2026 LA County Primary election + challenger roster
provides:
  - municipality_geo_id column on connect.connected_profiles
  - resolve_user_jurisdiction returning municipality key for incorporated places
  - Backfill migration for all existing users with stored coordinates
  - LA citywide races (City Attorney, Controller, Clerk) seeded for 2026 Primary
  - LA City Attorney candidates seeded (Feldstein Soto + Marissa Roy)
affects:
  - elections/me route (already wired - municipality_geo_id included in geoIds array)
  - set-location route (already wired - municipality_geo_id written on location store)
  - Any future phase adding more city-level office types

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "municipality_geo_id parallel to city_council_geo_id — two separate columns for two levels of locality"
    - "LOCAL_EXEC district_type with G4110/G4040/G4120 MTFCC for incorporated place boundaries"
    - "Parallel RPC query block pattern: separate SELECT INTO for each jurisdiction tier"

key-files:
  created:
    - backend/migrations/065_add_municipality_geo_id.sql
    - backend/migrations/066_update_resolve_user_jurisdiction_municipality.sql
    - backend/migrations/067_backfill_municipality_geo_id.sql
    - backend/scripts/seed-la-citywide-races-2026.sql
  modified:
    - backend/src/routes/essentials.ts
    - backend/src/routes/connect.ts

key-decisions:
  - "Separate municipality_geo_id column rather than overloading city_council_geo_id — city council = ward/district, municipality = city-level boundary"
  - "LOCAL_EXEC district_type used for city-boundary match — parallels LOCAL for city council"
  - "MTFCC G4110/G4040/G4120 for incorporated places (principal city, consolidated city, independent city)"
  - "Seed script is manual-only — not run automatically. Execute via psql $DATABASE_URL -f scripts/seed-la-citywide-races-2026.sql"
  - "Controller and Clerk candidates intentionally omitted — require lavote.gov verification before seeding"

patterns-established:
  - "City-level geo_id ('0644000' for LA) stored in municipality_geo_id; included in getElectionsByGeoIds array"
  - "Backfill migration follows 064 pattern: loop connected_profiles where encrypted_lat IS NOT NULL AND location_consent = true"
  - "Seed script verifies election and district exist before inserting; uses WHERE NOT EXISTS + ON CONFLICT for idempotency"

# Metrics
duration: 15min
completed: 2026-04-13
---

# Quick-018: Municipality Geo ID Support — LA Citywide Races Summary

**municipality_geo_id column + RPC extension + backfill so LA residents see City Attorney, Controller, and Clerk on the Elections page**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-13
- **Completed:** 2026-04-13
- **Tasks:** 3
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- Added `municipality_geo_id TEXT` column to `connect.connected_profiles` (migration 065)
- Extended `connect.resolve_user_jurisdiction` RPC to return a `municipality` key using LOCAL_EXEC district + G4110/G4040/G4120 MTFCC (migration 066)
- Backfill migration for all users with stored coordinates (migration 067), following the exact 064 pattern
- Route changes in `essentials.ts` and `connect.ts` already wired: municipality_geo_id flows through TypeScript interface, SELECT, Path 1 geoIds array, Path 1.5 write-back UPDATE, Path 1.5 geoIds array, and set-location write
- Seed script: 3 citywide LA races (City Attorney, Controller, Clerk) linked to 0644000 district; City Attorney candidates Hydee Feldstein Soto (incumbent) and Marissa Roy (challenger) verified via CAL-ACCESS

## Task Commits

1. **Task 1: Add municipality_geo_id column and update resolve_user_jurisdiction RPC** - `83b184f` (feat)
2. **Task 2: Wire municipality_geo_id into elections/me and set-location routes** - `00189fa` (feat)
3. **Task 3: Seed LA citywide races and candidates for 2026 Primary** - `b352a40` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `backend/migrations/065_add_municipality_geo_id.sql` - ADD COLUMN IF NOT EXISTS municipality_geo_id TEXT on connected_profiles
- `backend/migrations/066_update_resolve_user_jurisdiction_municipality.sql` - Full RPC replacement adding municipality query block and v_muni_geo_id to DECLARE + return
- `backend/migrations/067_backfill_municipality_geo_id.sql` - DO block loops all users with coordinates, calls RPC, writes municipality_geo_id only
- `backend/scripts/seed-la-citywide-races-2026.sql` - BEGIN/COMMIT wrapped seed: offices, races, politician records, race_candidates for LA citywide offices
- `backend/src/routes/essentials.ts` - municipality_geo_id in TypeScript interface, SELECT, Path 1 geoIds array, Path 1.5 write-back UPDATE params, Path 1.5 geoIds array
- `backend/src/routes/connect.ts` - municipality_geo_id as $16 in set-location jurisdiction write-back UPDATE

## Decisions Made

- **municipality_geo_id is a separate column from city_council_geo_id.** City council = sub-city ward/district. Municipality = the city boundary itself. Merging them would require type disambiguation and break the simple geoIds array pattern.
- **LOCAL_EXEC district_type** used for the municipality match. This mirrors how the LA Mayor office is already linked — city-level executive offices live under LOCAL_EXEC, council ward races live under LOCAL.
- **Seed script is manual-only.** City boundary data (geo_id 0644000 district) must exist before the seed runs. Script includes verification DO blocks that raise exceptions if the election or district is missing.
- **City Controller and City Clerk candidates intentionally not seeded.** Confirmed on lavote.gov ballot but candidate filing list not yet verified. Comment in script directs future contributor to verify before adding.

## Deviations from Plan

None — plan executed exactly as written. Tasks 1 and 2 were already committed before this execution session; Task 3 (seed script) was untracked and committed during this session.

## Issues Encountered

None. TypeScript compiled clean (`npx tsc --noEmit` exit 0). All three migration files and both route files were already in the correct state matching the plan spec.

## User Setup Required

**Migrations must be applied to production.** Run in order via Supabase MCP `apply_migration`:
1. `065_add_municipality_geo_id.sql`
2. `066_update_resolve_user_jurisdiction_municipality.sql`
3. `067_backfill_municipality_geo_id.sql`

**Seed script must be run manually** after migrations are applied and the LA city boundary is loaded in `essentials.geofence_boundaries`:
```
psql $DATABASE_URL -f backend/scripts/seed-la-citywide-races-2026.sql
```

## Next Phase Readiness

- LA residents with stored coordinates will see City Attorney, Controller, and Clerk races on Elections page once migrations + seed are applied
- Backfill covers all existing users — no manual re-enrollment needed
- City Controller and City Clerk candidates can be added via a follow-up seed once lavote.gov candidate filing list is verified
- Pattern is reusable for other cities: any city with LOCAL_EXEC districts in essentials.districts will auto-resolve municipality_geo_id for users inside that boundary

---
*Phase: quick-018*
*Completed: 2026-04-13*
