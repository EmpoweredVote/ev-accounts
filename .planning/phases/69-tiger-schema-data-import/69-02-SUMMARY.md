---
phase: 69-tiger-schema-data-import
plan: 02
subsystem: database
tags: [postgis, tiger, geofencing, geo_districts, ogr2ogr, gdal, tiger_geoid, backfill]

# Dependency graph
requires:
  - phase: 69-01
    provides: geo_districts table + resolve/cache RPCs (empty — ready for data)
provides:
  - "scripts/seed-tiger-districts.sh — committed, reusable, idempotent (GEO-06/07/08)"
  - "essentials.geo_districts populated: 80 ca_assembly + 40 ca_senate + 52 us_house rows"
  - "essentials.resolve_user_districts verified end-to-end: LA City Hall returns 3 rows"
  - "essentials.districts.tiger_geoid backfilled for all 172 CA assembly/senate/us_house rows (GEO-09)"
  - "Migration 091 applied: dropped UNIQUE constraint on tiger_geoid, added plain index"
affects:
  - 70-backend-wiring (location-set flow calls cache_user_districts — schema + data now live)
  - 71-school-districts (adds school layers to same geo_districts table)

# Tech tracking
tech-stack:
  added:
    - gdal/ogr2ogr (local-only ops tool — not a runtime dependency)
  patterns:
    - "TIGER import: download zip -> unzip -> ogr2ogr stage table (-overwrite) -> INSERT ... ON CONFLICT (layer, geoid) DO UPDATE -> DROP stage"
    - "human-checkpoint pattern: seed scripts that require local binaries (ogr2ogr) gate on user execution, not Claude sandbox"
    - "Phase 70 join MUST use tiger_geoid + district_type together — assembly D3 and senate D3 both have tiger_geoid='06003' (TIGER GEOID format is shared between SLDL and SLDU)"
    - "tiger_geoid is non-unique: same geoid appears in multiple layers (e.g., '06003' in both ca_assembly and ca_senate). Always filter by district_type when resolving"

key-files:
  created:
    - scripts/seed-tiger-districts.sh
    - supabase/migrations/20260509000003_091_tiger_geoid_backfill.sql
  modified: []

key-decisions:
  - "UNIQUE constraint on tiger_geoid dropped — SLDL and SLDU share geoid format (06NNN), so assembly D20 and senate D20 both map to '06020'. Non-unique index added instead."
  - "Join column: d.geo_id = gd.geoid (direct TIGER GEOID match — no casting needed). geo_id column in essentials.districts already stores TIGER format."
  - "Import ran against remote Supabase via session pooler (aws-0-*.pooler.supabase.com:5432) — direct host DNS fails due to IPv6 on this machine"
  - "PROJ_LIB must be set on Windows: export PROJ_LIB='C:/Program Files/GDAL/projlib'"
  - "CD layer: TIGER2024 uses cd119 state-specific files (tl_2024_06_cd119.zip, field CD119FP) — not cd118 or national cd118"

patterns-established:
  - "Phase 70 join pattern: SELECT d.* FROM essentials.districts d WHERE d.tiger_geoid = <geoid> AND d.district_type = <type_for_layer>"
  - "Layer -> district_type mapping: ca_assembly='STATE_LOWER', ca_senate='STATE_UPPER', us_house='NATIONAL_LOWER'"

# Metrics
duration: ~90min (including human checkpoint for ogr2ogr import)
completed: 2026-05-10
---

# Phase 69 Plan 02: TIGER Data Import + tiger_geoid Backfill Summary

**TIGER 2024 CA polygons imported into geo_districts (172 rows), tiger_geoid backfilled on all CA assembly/senate/us_house district rows, LA City Hall spot-check verified end-to-end.**

## Performance

- **Duration:** ~90 min (includes human-gated ogr2ogr checkpoint)
- **Tasks:** 3 (Task 1: seed script, Task 2: human import checkpoint, Task 3: backfill migration)
- **Files modified:** 2

## Accomplishments

- `scripts/seed-tiger-districts.sh` created: downloads TIGER 2024 CA shapefiles, reprojects NAD83→WGS84 via ogr2ogr, idempotent ON CONFLICT upsert into `essentials.geo_districts`
- TIGER import completed by user on local machine: 80 ca_assembly + 40 ca_senate + 52 us_house = 172 rows
- LA City Hall spot-check (34.0537, -118.2430) returns 3 rows: Assembly D54 (geoid 06054), Senate D26 (geoid 06026), US House CD34 (geoid 0634) ✓
- Migration 091 dropped the UNIQUE constraint on `tiger_geoid` (design fix) and backfilled all 172 CA rows

## Import Results

| Layer | Rows imported | Expected |
|-------|--------------|---------|
| ca_assembly | 80 | 80 ✓ |
| ca_senate | 40 | 40 ✓ |
| us_house | 52 | 52 ✓ |

## LA City Hall Spot-check

```
layer       | geoid | district_num | name
ca_assembly | 06054 | 054          | Assembly District 54
ca_senate   | 06026 | 026          | State Senate District 26
us_house    | 0634  | 34           | Congressional District 34
```

## Task 3 Investigation Findings

**district_type mapping:**
- `STATE_LOWER` = CA Assembly (80 CA rows)
- `STATE_UPPER` = CA Senate (40 CA rows)
- `NATIONAL_LOWER` = US House (52 CA rows with matching geoids in geo_districts)

**Join column:** `d.geo_id = gd.geoid` — direct TIGER GEOID match, no casting.

**Backfill counts after migration 091:**
| district_type | total | with_geoid | without_geoid |
|--------------|-------|------------|--------------|
| NATIONAL_LOWER | 52 | 52 | 0 |
| STATE_LOWER | 80 | 80 | 0 |
| STATE_UPPER | 40 | 40 | 0 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UNIQUE constraint on tiger_geoid blocks backfill for same-numbered districts**

- **Found during:** Migration 091 apply attempt
- **Issue:** Assembly District 20 and Senate District 20 both have `geo_id = '06020'` (TIGER uses state FIPS + 3-digit number for both SLDL and SLDU). The UNIQUE constraint added in migration 089 rejected the second row.
- **Fix:** Migration 091 drops `districts_tiger_geoid_key` and adds `idx_districts_tiger_geoid` (non-unique index) instead.
- **Impact on Phase 70:** The join from `resolve_user_districts` result to `essentials.districts` MUST always include both `tiger_geoid` and `district_type` (or equivalently, the layer→type mapping) to disambiguate assembly vs. senate rows with the same number.

**2. [Context] TIGER 2024 uses cd119 state-specific files, not cd118**

- **Found during:** Download step
- **Issue:** Plan template specified `tl_2024_06_cd118.zip` — file does not exist on Census Bureau. TIGER2024 uses 119th Congress naming.
- **Fix:** Updated seed script to `tl_2024_06_cd119.zip` with field `CD119FP`.

**3. [Context] Windows GDAL requires PROJ_LIB env var**

- **Found during:** ogr2ogr execution on Windows
- **Fix:** `export PROJ_LIB="C:/Program Files/GDAL/projlib"` before running ogr2ogr.

**4. [Context] Supabase direct host DNS fails (IPv6); must use session pooler**

- **Found during:** psql connection attempts
- **Fix:** Use `aws-0-<region>.pooler.supabase.com:5432` (session pooler), not `db.<project>.supabase.co:5432`.

## Task Commits

1. **Task 1: seed-tiger-districts.sh** — commits 046c988, 7175977, 8c8620d (patches for cd119 URL/field)
2. **Task 3: migration 091** — commit fb579f8

## Issues Encountered

- **Line continuation breaking in MINGW64**: Multi-line ogr2ogr commands with `\` were split by the chat UI, causing `EPSG:4326` to be treated as a shell command. Resolved by writing a `/c/tmp/tiger/import.sh` script file executed directly.
- **Copy-paste limitation**: Single-line commands exceeding terminal width still broke due to chat rendering inserting newlines. Script file approach bypassed this entirely.

## Phase 70 Readiness

- `essentials.geo_districts` populated (172 rows) — `resolve_user_districts(lat, lng)` returns real results
- `essentials.cache_user_districts(user_id, lat, lng)` can now be called and will populate `connect.user_districts`
- `essentials.districts.tiger_geoid` backfilled — politician-by-district join is live
- **Phase 70 join pattern**: when resolving districts from `resolve_user_districts` result `(layer, geoid)`, look up politicians via:
  ```sql
  SELECT d.* FROM essentials.districts d
  WHERE d.tiger_geoid = <geoid>
    AND d.district_type = <layer_to_type_map[layer]>
  ```
  Layer→type: `ca_assembly`→`STATE_LOWER`, `ca_senate`→`STATE_UPPER`, `us_house`→`NATIONAL_LOWER`

---
*Phase: 69-tiger-schema-data-import*
*Completed: 2026-05-10*
