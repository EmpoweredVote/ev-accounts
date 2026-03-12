---
phase: quick-8
plan: 01
subsystem: EV-Backend (essentials)
tags: [data-update, db-migration, monroe-county, council, chamber-rename, geofence-import, photos]
dependency_graph:
  requires: []
  provides: [correct-commission-name, council-membership-2025, monroe-council-geofences, council-member-photos]
  affects: [essentials frontend local-section display, address search district matching]
tech_stack:
  added: [supabase-py]
  patterns: [WHERE NOT EXISTS idempotent SQL, setup.go unconditional UPDATE, ArcGIS GeoJSON geofence import, X0001 custom MTFCC]
key_files:
  created:
    - EV-Backend/internal/essentials/data/migrate_quick8_council.sql
    - EV-Backend/scripts/import_monroe_council_districts.py
    - EV-Backend/scripts/upload_monroe_council_photos.py
  modified:
    - EV-Backend/internal/essentials/setup.go
decisions:
  - "offices table has no unique constraint on (politician_id, chamber_id) — used WHERE NOT EXISTS guards instead of ON CONFLICT"
  - "politicians.slug has no unique index — WHERE NOT EXISTS guards used for politician inserts too"
  - "Chamber rename is unconditional in setup.go (no AND guard) so it overwrites the stale old value on every server restart"
  - "District geofence source: Monroe County ArcGIS FeatureServer layer 13 (Monroe County Council 2022) — owner nYfGJ9xFTKW6VPqW"
  - "Photos stored at politician_photos/monroe_council/ in Supabase (bucket name is underscore, not hyphen)"
metrics:
  duration: "~20 minutes (including continuation)"
  completed_date: "2026-03-12"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 1
---

# Quick Task 8: Monroe County Data Update Summary

**One-liner:** Renamed Monroe County Commission to "Board of Commissioners," updated 2025 council membership (Munson deactivated, Feitl + 4 district members), imported district geofence boundaries from ArcGIS, and uploaded headshots to Supabase CDN.

## Tasks Completed

### Task 1: Rename Commission chamber and update government_bodies (commit: 77b8c2d, EV-Backend)

Updated `EV-Backend/internal/essentials/setup.go`:
- Changed chamber `name_formal` UPDATE to unconditional rename to `'Monroe County Board of Commissioners'`
- Added `UPDATE essentials.government_bodies` before the INSERT block to rename the existing `body_key`
- Updated INSERT block to use `'Monroe County Board of Commissioners'` for future clean installs
- Build verified: `go build` passes

DB state confirmed: chambers.name_formal = 'Monroe County Board of Commissioners' (3 rows), government_bodies.body_key renamed.

### Task 2: Seed council member changes via migration SQL (commit: 8a63351, EV-Backend)

Created and ran `EV-Backend/internal/essentials/data/migrate_quick8_council.sql`.

Results confirmed:
| Name | geo_id | Title | is_vacant |
|------|--------|-------|-----------|
| Liz Feitl | 18105 | Monroe County Council Member | false |
| Cheryl Munson | 18105 | Monroe County Council - At Large | true |
| Peter Iversen | 1810500001 | Monroe County Council Member - District 1 | false |
| Kate Wiltz | 1810500002 | Monroe County Council Member - District 2 | false |
| Marty Hawk | 1810500003 | Monroe County Council Member - District 3 | false |
| Jennifer Crossley | 1810500004 | Monroe County Council Member - District 4 | false |

### Task 3a: Import district geofence boundaries (commit: f588299, EV-Backend)

Script: `EV-Backend/scripts/import_monroe_council_districts.py`

Source: Monroe County ArcGIS FeatureServer layer 13 "Monroe County Council 2022"
URL: `https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/Monroe_County_Election_Map_Current_WFL1/FeatureServer/13`

Imported 4 district polygons with `mtfcc='X0001'` into `essentials.geofence_boundaries`:
- `1810500001` — Monroe County Council District 1
- `1810500002` — Monroe County Council District 2
- `1810500003` — Monroe County Council District 3
- `1810500004` — Monroe County Council District 4

Script is idempotent via `ON CONFLICT (geo_id, mtfcc) DO UPDATE`.

### Task 3b: Upload politician photos (commit: 19131cb, EV-Backend)

Script: `EV-Backend/scripts/upload_monroe_council_photos.py`

Source: https://www.in.gov/counties/monroe/government/council/
Bucket: `politician_photos/monroe_council/` (Supabase)

All 5 CDN URLs confirmed in `essentials.politicians.photo_custom_url`:
- `https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Liz-Feitl.png`
- `https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Peter-Iversen.png`
- `https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Kate-Wiltz.png`
- `https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Marty-Hawk.png`
- `https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Jennifer-Crossley.png`

## Final DB State

| Name | geo_id | Title | is_vacant | has_photo |
|------|--------|-------|-----------|-----------|
| Liz Feitl | 18105 | Monroe County Council Member | false | YES |
| Cheryl Munson | 18105 | Monroe County Council - At Large | true | - |
| Peter Iversen | 1810500001 | Monroe County Council Member - District 1 | false | YES |
| Kate Wiltz | 1810500002 | Monroe County Council Member - District 2 | false | YES |
| Marty Hawk | 1810500003 | Monroe County Council Member - District 3 | false | YES |
| Jennifer Crossley | 1810500004 | Monroe County Council Member - District 4 | false | YES |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ON CONFLICT (slug) fails on politicians — no unique constraint on slug**
- Found during: Task 2 (first migration run attempt)
- Issue: Plan specified `ON CONFLICT (slug) DO NOTHING` but `essentials.politicians` has no unique index on `slug`
- Fix: Replaced with `WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE slug = '...')` SELECT-based INSERT
- Files modified: EV-Backend/internal/essentials/data/migrate_quick8_council.sql

**2. [Rule 1 - Bug] ON CONFLICT (politician_id) fails on offices — column is nullable**
- Found during: Task 2 (first migration run attempt)
- Issue: Plan specified `ON CONFLICT (politician_id) DO NOTHING` but PostgreSQL ON CONFLICT requires a constraint, and nullable columns with indexes cannot be targeted this way
- Fix: Replaced with `WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE politician_id = p.id)` guard in the SELECT subquery
- Files modified: EV-Backend/internal/essentials/data/migrate_quick8_council.sql

**3. [Rule 3 - Blocker] REST API upload rejected sb_secret_ key format**
- Found during: Task 3 photo upload (first attempt using curl + Authorization header)
- Issue: `sb_secret_` format is not a compact JWS JWT; raw REST API rejects it
- Fix: Used supabase-py SDK which handles this key format correctly; also clarified bucket name is `politician_photos` (underscore) not `politician-photos` (hyphen)

**4. [Rule 3 - Blocker] supabase-py not installed in environment**
- Found during: Task 3
- Fix: `pip install supabase` — installed supabase-py 2.28.0

## Success Criteria Status

- [x] "Monroe County Board of Commissioners" in DB chambers + government_bodies
- [x] Liz Feitl is at-large council member with photo
- [x] 4 district council members in DB with correct district linkage and photos
- [x] Cheryl Munson no longer shows as active (is_vacant=true)
- [x] Photos uploaded and linked for all 5 new politicians
- [x] District geofence boundaries imported — ST_Intersects will match addresses to district members

## Self-Check: PASSED

- [x] EV-Backend/internal/essentials/setup.go — modified, build verified
- [x] EV-Backend/internal/essentials/data/migrate_quick8_council.sql — created and run
- [x] EV-Backend/scripts/import_monroe_council_districts.py — created and run (4 geofences)
- [x] EV-Backend/scripts/upload_monroe_council_photos.py — created and run (5 photos)
- [x] EV-Backend commit 77b8c2d — chamber/government_bodies rename
- [x] EV-Backend commit 8a63351 — council SQL migration
- [x] EV-Backend commit f588299 — geofence import script
- [x] EV-Backend commit 19131cb — photo upload script
- [x] DB geofence_boundaries: 4 rows confirmed for 1810500001-1810500004
- [x] DB politicians: photo_custom_url set for all 5 council members
