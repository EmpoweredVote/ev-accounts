---
phase: quick
plan: "012"
subsystem: essentials-geofence
tags: [postgis, tiger-line, ogr2ogr, geofence, representatives, senators, data-fix]

dependency-graph:
  requires: []
  provides:
    - "essentials.geofence_boundaries: CA state boundary polygon (geo_id='06', mtfcc='G4000')"
    - "essentials.districts 8f76aeec-...: geo_id set to '06'"
    - "essentials.offices Padilla: title='Senator', district_id=NATIONAL_UPPER"
  affects:
    - "GET /api/essentials/representatives/me — CA users now get both Schiff and Padilla"

tech-stack:
  added: []
  patterns:
    - "TIGER STATE shapefile load into essentials.geofence_boundaries via ogr2ogr with active_schema=essentials"
    - "G4000 MTFCC (state boundary) for NATIONAL_UPPER senator geofence"

key-files:
  created: []
  modified: []

key-decisions:
  - "ogr2ogr key=value PG_CONN format with active_schema=essentials (not URL format)"
  - "PROMOTE_TO_MULTI required for state boundary (TIGER may include non-contiguous polygons)"
  - "STATEFP='06' filter to load only CA row from national state file"
  - "Statewide query (d.state='CA') does not need geofence; geofence path needed geo_id='06' on both boundary and district"

metrics:
  duration: "6 minutes (19:20Z → 19:26Z)"
  completed: "2026-03-30"
---

# Quick Task 012: Fix CA NATIONAL_UPPER Senators (Padilla Geofence) Summary

**One-liner:** Loaded CA state TIGER boundary (G4000/geo_id='06') into essentials.geofence_boundaries and fixed Padilla's corrupted office (Councilman/LOCAL → Senator/NATIONAL_UPPER), enabling both CA US Senators to appear in address-based representative search.

## Accomplishments

### Task 1: Load CA State Boundary + Fix District geo_id

- Downloaded `tl_2024_us_state.zip` from Census TIGER 2024
- Loaded CA state polygon into `essentials.geofence_boundaries` via ogr2ogr:
  - `geo_id='06'`, `mtfcc='G4000'`, `state='CA'`, geometry SRID=4326
  - Filtered to STATEFP='06' (CA only) from national state shapefile
  - Used key=value PG_CONN format with `active_schema=essentials`
- Updated `essentials.districts` id=`8f76aeec-fcd4-4010-9a37-7bca1063224b` geo_id from `''` to `'06'`
- Verified geofence intersection: ST_Covers for LA coords (-118.2437, 34.0522) returns NATIONAL_UPPER row

### Task 2: Fix Padilla's Corrupted Office Record

- Found Padilla's sole office had `title='Councilman'`, `district_id` pointing to a LOCAL district (geo_id=0636546)
- Updated to `title='Senator'`, `district_id='8f76aeec-fcd4-4010-9a37-7bca1063224b'` (CA NATIONAL_UPPER), `representing_state='CA'`
- Verified both senators on district: Schiff + Padilla, both title='Senator', NATIONAL_UPPER, geo_id='06'
- Verified statewide query returns both senators for `d.state='CA' AND d.district_type='NATIONAL_UPPER'`

## Verification Results

| Check | Query | Result |
|-------|-------|--------|
| Geofence boundary loaded | `COUNT(*) WHERE geo_id='06' AND mtfcc='G4000'` | 1 row |
| District geo_id set | `SELECT geo_id WHERE id='8f76aeec-...'` | '06' |
| Geofence intersection | ST_Covers for LA coords → NATIONAL_UPPER | 1 row (geo_id=06, CA) |
| Both senators statewide | `d.state='CA' AND d.district_type='NATIONAL_UPPER'` | Schiff + Padilla |

## Task Commits

| Task | Name | Commit | Change |
|------|------|--------|--------|
| 1 | Load CA state boundary + fix district geo_id | 94b0392 | DB-only: geofence_boundaries row + district update |
| 2 | Fix Padilla office corruption | 718e7f9 | DB-only: offices title+district_id update |

## Deviations from Plan

None — plan executed exactly as written.

## Root Cause Summary

Two independent data issues:

1. **Missing geofence boundary** — `essentials.geofence_boundaries` had no row for the CA state polygon (geo_id='06', G4000). The geofence query joins on `geo_id`, so the NATIONAL_UPPER district was never matched by PostGIS intersection.

2. **Corrupted Padilla office** — Padilla's office record pointed to a LOCAL district (geo_id=0636546, likely City of Los Angeles) with title='Councilman'. This was likely a seed script error assigning a city official's district instead of the state-level senator district.
