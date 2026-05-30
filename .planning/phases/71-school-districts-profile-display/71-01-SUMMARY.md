---
phase: 71-school-districts-profile-display
plan: 01
subsystem: api
tags: [postgres, postgis, tiger, geo_districts, user_districts, school-districts, pool.query, express]

# Dependency graph
requires:
  - phase: 70-geofencing-backend-integration
    provides: connect.user_districts table, GET /api/account/districts, Path 0 fast path in representatives/me, cache_user_districts wired into set-location
  - phase: 69-tiger-schema-data-import
    provides: essentials.geo_districts table with layer discriminator, resolve_user_districts + cache_user_districts RPCs, TIGER 2024 legislative district polygons

provides:
  - Migration 093: both essentials.resolve_user_districts and essentials.cache_user_districts now default to 6 layers (adds school_unified, school_elementary, school_secondary)
  - scripts/seed-tiger-school-districts.sh: idempotent TIGER 2024 UNSD/ELSD/SCSD importer for CA school districts
  - GET /api/account/school-district: new endpoint returning cached school district rows for the authenticated user (204 on empty)
  - Path 0 layerTypeMap in essentials.ts extended with three SCHOOL_* district_type values (forward-compatible)
  - CA school district polygons in essentials.geo_districts: 346 school_unified, 517 school_elementary, 112 school_secondary

affects:
  - 71-02 (Location tab frontend) — depends on GET /api/account/school-district being live
  - future school board ingestion phase — layerTypeMap already wired; only needs essentials.districts rows + essentials.politicians rows
  - recache-user-districts.ts operator CLI — inherits 6-layer default via essentials.recache_user_districts_for_user (no code change needed)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Separate endpoint for school vs. legislative district layers — GET /districts locked to ca_assembly/ca_senate/us_house; school layers served by GET /school-district"
    - "6-layer RPC default: backwards-compatible extension — all 3-arg call sites inherit school layers automatically via Postgres default parameter"
    - "Forward-compatible layerTypeMap: SCHOOL_UNIFIED/SCHOOL_ELEMENTARY/SCHOOL_SECONDARY mapped before essentials.districts has rows — join returns zero rows safely"
    - "NAME field (not NAMELSAD) for school shapefiles; per-layer LEA codes UNSDLEA/ELSDLEA/SCSDLEA (not SLDLST)"

key-files:
  created:
    - supabase/migrations/20260509000004_093_extend_cache_user_districts_school_layers.sql
    - scripts/seed-tiger-school-districts.sh
    - (Plan 71-01 SUMMARY itself)
  modified:
    - backend/src/routes/account.ts
    - backend/src/routes/essentials.ts

key-decisions:
  - "GET /api/account/districts stays legislative-only (ca_assembly, ca_senate, us_house) — school districts exposed via dedicated GET /api/account/school-district endpoint"
  - "204 No Content (not 200 with nulls, not 404) when user has no school-layer rows in connect.user_districts"
  - "School layers added to RPC defaults (migration 093) — no Node.js call-site changes needed; all existing set-location paths auto-cache school districts for future users"
  - "Path 0 layerTypeMap extended before essentials.districts has school rows — empty join is safe, no pre-created placeholder rows"

patterns-established:
  - "Endpoint separation pattern: stable legislative endpoint vs. extensible school endpoint — avoids breaking API shape when adding new geo layers"
  - "Forward-compatible map entries: add district_type to layerTypeMap before data exists; zero-row join is safe and clean"

# Metrics
duration: ~25min
completed: 2026-05-10
---

# Phase 71 Plan 01: School Districts Backend Summary

**Migration 093 extends cache_user_districts/resolve_user_districts to 6 layers; 975 CA school district polygons imported from TIGER 2024; GET /api/account/school-district live with pool.query + 204-on-empty contract**

## Performance

- **Duration:** ~25 min (Tasks 4-5 only; Tasks 1-2 committed before checkpoint; Task 3 completed by operator)
- **Started:** 2026-05-10 (continuation after human-action checkpoint)
- **Completed:** 2026-05-10
- **Tasks:** 5 (Tasks 1-2 pre-checkpoint, Task 3 operator, Tasks 4-5 post-checkpoint)
- **Files modified:** 2 (backend/src/routes/account.ts, backend/src/routes/essentials.ts)

## Accomplishments

- Migration 093 applied to remote Supabase — both `essentials.resolve_user_districts` and `essentials.cache_user_districts` now default to 6 layers (ca_assembly, ca_senate, us_house, school_unified, school_elementary, school_secondary). All existing 3-arg call sites inherit school layers automatically.
- CA school district polygons imported via `scripts/seed-tiger-school-districts.sh`:
  - `school_unified`: 346 rows (TIGER 2024 UNSD, NAME field, UNSDLEA geoid)
  - `school_elementary`: 517 rows (TIGER 2024 ELSD, NAME field, ELSDLEA geoid)
  - `school_secondary`: 112 rows (TIGER 2024 SCSD, NAME field, SCSDLEA geoid)
  - LA spot-check confirmed: `school_unified | 0622710 | Los Angeles Unified School District`
- `GET /api/account/school-district` endpoint added to account.ts — `requireAuth`, `pool.query` (never PostgREST), 204 on empty, 200 with `{ school_unified, school_elementary, school_secondary }` shape
- Path 0 `layerTypeMap` in essentials.ts extended with `SCHOOL_UNIFIED`, `SCHOOL_ELEMENTARY`, `SCHOOL_SECONDARY` — forward-compatible; representatives feed response unchanged until school board ingestion phase populates `essentials.districts`

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration 093 SQL file** - `8c6cbdd` (feat)
2. **Task 2: seed-tiger-school-districts.sh** - `9c89634` (feat)
3. **Task 3: Operator import checkpoint** - (no commit — operator action)
4. **Task 4: GET /api/account/school-district endpoint** - `9c5fe47` (feat)
5. **Task 5: Extend Path 0 layerTypeMap** - `8823716` (feat)

**Plan metadata:** (this docs commit)

## Files Created/Modified

- `supabase/migrations/20260509000004_093_extend_cache_user_districts_school_layers.sql` — CREATE OR REPLACE for both RPCs with 6-layer default + GRANT EXECUTE re-applied
- `scripts/seed-tiger-school-districts.sh` — TIGER 2024 UNSD/ELSD/SCSD importer; uses NAME (not NAMELSAD), per-layer LEA codes, ON CONFLICT DO UPDATE idempotency
- `backend/src/routes/account.ts` — added `router.get('/school-district', requireAuth, ...)` immediately after `/districts` handler (line 785)
- `backend/src/routes/essentials.ts` — extended `layerTypeMap` from 3 to 6 entries inside Path 0 block (line 494)

## Endpoint Contract

### GET /api/account/school-district

**Auth:** Bearer token (requireAuth — both Inform and Connected tiers)

**200 Response (user has school-layer rows):**
```json
{
  "school_unified":    { "name": "Los Angeles Unified School District", "geoid": "0622710" },
  "school_elementary": null,
  "school_secondary":  null
}
```
Each key is either `{ name, geoid }` or `null`. LA users in LAUSD get unified only (unified district covers elementary grades).

**204 Response (user has no school-layer rows):**
Empty body. Occurs when: user has no location set, user is outside CA, or coordinate fell outside all school polygons.

**500 Response:**
```json
{ "code": "INTERNAL_ERROR", "message": "An unexpected error occurred" }
```

### GET /api/account/districts (unchanged)

Response shape locked to legislative layers only:
```json
{
  "ca_assembly": { "district_number": "51", "name": "...", "tiger_geoid": "06051" },
  "ca_senate":   { "district_number": "24", "name": "...", "tiger_geoid": "06024" },
  "us_house":    { "district_number": "37", "name": "...", "tiger_geoid": "3706" }
}
```
No school keys added to this endpoint.

## Decisions Made

1. **Separate school endpoint**: `GET /api/account/school-district` is distinct from `GET /api/account/districts` (legislative-only). The legislative endpoint shape is locked — adding school keys would change the contract for existing callers. School layers go to the dedicated endpoint, consumed by the Location tab in Plan 71-02.

2. **204 on empty, not 200 with nulls**: Follows the same pattern as `GET /api/account/districts`. Cleaner for the frontend — a 204 means "no data; don't render the section."

3. **6-layer RPC default, no Node.js call-site changes**: The migration 093 default propagates to all existing set-location paths (Connected `POST /api/connect/set-location`, Inform `POST /api/account/set-location`, and the recache CLI). No handler code touched.

4. **Forward-compatible layerTypeMap**: School entries added to Path 0 before `essentials.districts` has any school rows. Empty join is safe — zero school board members appear in the representatives feed until the school board ingestion phase ships.

## Deviations from Plan

None — plan executed exactly as written. TypeScript compiled clean (`npx tsc --noEmit` exits 0) after both edits.

## Issues Encountered

None. The human-action checkpoint (Task 3) resolved successfully with operator-confirmed row counts: 346 unified, 517 elementary, 112 secondary. LA spot-check confirmed.

## User Setup Required

None — no new environment variables, no new external service configuration. The school district endpoint uses the same Supabase pool connection and auth middleware already in place.

## Next Phase Readiness

**Plan 71-02 (Location tab frontend) can proceed immediately.** It depends on:
- `GET /api/account/school-district` — live at `login.empowered.vote/api/account/school-district`
- `GET /api/account/districts` — unchanged, live
- School district names in `essentials.geo_districts` — 975 rows imported

**Future school board ingestion phase** can proceed when ready. The backend is pre-wired:
- `layerTypeMap` has `SCHOOL_UNIFIED/SCHOOL_ELEMENTARY/SCHOOL_SECONDARY` entries
- `essentials.geo_districts` has all CA school district polygons for geofencing
- `connect.user_districts` will auto-populate school-layer rows for any user who sets location (via the 6-layer RPC default)
- Only missing: `essentials.districts` rows and `essentials.politicians` rows for school board members

---
*Phase: 71-school-districts-profile-display*
*Completed: 2026-05-10*
