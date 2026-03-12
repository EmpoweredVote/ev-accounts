---
phase: quick-8
plan: 01
subsystem: EV-Backend (essentials)
tags: [data-update, db-migration, monroe-county, council, chamber-rename]
dependency_graph:
  requires: []
  provides: [correct-commission-name, council-membership-2025]
  affects: [essentials frontend local-section display]
tech_stack:
  added: []
  patterns: [WHERE NOT EXISTS idempotent SQL, setup.go unconditional UPDATE]
key_files:
  created:
    - EV-Backend/internal/essentials/data/migrate_quick8_council.sql
  modified:
    - EV-Backend/internal/essentials/setup.go
decisions:
  - "offices table has no unique constraint on (politician_id, chamber_id) — used WHERE NOT EXISTS guards instead of ON CONFLICT"
  - "politicians.slug has no unique index — WHERE NOT EXISTS guards used for politician inserts too"
  - "Chamber rename is unconditional in setup.go (no AND guard) so it overwrites the stale old value on every server restart"
  - "DB updates applied directly via psql in addition to setup.go — server restart would re-apply via Init()"
metrics:
  duration: "~4 minutes"
  completed_date: "2026-03-12"
  tasks_completed: 2
  tasks_total: 3
  files_created: 1
  files_modified: 1
---

# Quick Task 8: Monroe County Data Update Summary

**One-liner:** Renamed Monroe County Commission chamber to its legal name "Board of Commissioners" and updated 2025 Council membership — deactivated Munson, added Feitl (at-large) + 4 district members.

## Tasks Completed

### Task 1: Rename Commission chamber and update government_bodies (commit: 77b8c2d)

Updated `EV-Backend/internal/essentials/setup.go`:
- Changed chamber `name_formal` UPDATE to unconditional rename to `'Monroe County Board of Commissioners'`
- Added `UPDATE essentials.government_bodies` before the INSERT block to rename the existing `body_key` from `'Monroe County Commission'`
- Updated INSERT block to use `'Monroe County Board of Commissioners'` for future clean installs
- Build verified: `go build` passes

DB state after: chambers.name_formal = 'Monroe County Board of Commissioners' (3 rows), government_bodies.body_key = 'Monroe County Board of Commissioners'

### Task 2: Seed council member changes via migration SQL (commit: 8a63351)

Created `EV-Backend/internal/essentials/data/migrate_quick8_council.sql` and ran it against the Supabase DB.

Results (confirmed via SELECT):
| Name | geo_id | Title | is_vacant |
|------|--------|-------|-----------|
| Liz Feitl | 18105 | Monroe County Council Member | false |
| Cheryl Munson | 18105 | Monroe County Council - At Large | true |
| Peter Iversen | 1810500001 | Monroe County Council Member - District 1 | false |
| Kate Wiltz | 1810500002 | Monroe County Council Member - District 2 | false |
| Marty Hawk | 1810500003 | Monroe County Council Member - District 3 | false |
| Jennifer Crossley | 1810500004 | Monroe County Council Member - District 4 | false |

### Task 3: Checkpoint (awaiting human verification)

Status: Paused for human review — see checkpoint below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ON CONFLICT (slug) fails — no unique constraint on politicians.slug**
- Found during: Task 2 (first migration run attempt)
- Issue: Plan specified `ON CONFLICT (slug) DO NOTHING` for politician inserts, but `essentials.politicians` has no unique index on `slug` (only on `external_id`)
- Fix: Replaced all `ON CONFLICT` clauses with `WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE slug = '...')` guards
- Files modified: EV-Backend/internal/essentials/data/migrate_quick8_council.sql

**2. [Rule 1 - Bug] ON CONFLICT (politician_id) fails on offices table**
- Found during: Task 2 (first migration run attempt)
- Issue: Plan specified `ON CONFLICT (politician_id) DO NOTHING` for office inserts, but the UNIQUE index on `politician_id` is named `idx_essentials_offices_politician_id` and the column is nullable — PostgreSQL requires the conflict target to match a constraint, not just any index
- Fix: Replaced with `WHERE NOT EXISTS (SELECT 1 FROM essentials.offices WHERE politician_id = p.id)` guard in the SELECT subquery
- Files modified: EV-Backend/internal/essentials/data/migrate_quick8_council.sql

## Outstanding Items (Awaiting Human Action)

### District Geofence Boundaries — MISSING

Query confirmed 0 rows in `essentials.geofence_boundaries` for geo_ids `1810500001`-`1810500004`. This means district council members (Iversen, Wiltz, Hawk, Crossley) will NOT surface on address search until boundaries are imported.

**To fix:** Import Monroe County Council district boundary shapefiles with `mtfcc='X0001'`. Source: Indiana GIS data at https://www.in.gov/gis/ or request from Monroe County GIS.

### Politician Photos — Not Yet Uploaded

No photos have been uploaded for Feitl, Iversen, Wiltz, Hawk, or Crossley. `photo_custom_url` is null for all five new politicians.

**To fix:** Source photos from https://www.in.gov/counties/monroe/government/council/, upload to Supabase `politician-photos` bucket, then run:
```sql
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician-photos/[filename]'
WHERE slug = '[slug]';
```

## Self-Check: PASSED

- [x] EV-Backend/internal/essentials/setup.go — modified (verified)
- [x] EV-Backend/internal/essentials/data/migrate_quick8_council.sql — created (verified)
- [x] Commit 77b8c2d — exists
- [x] Commit 8a63351 — exists
- [x] DB: chambers.name_formal = 'Monroe County Board of Commissioners' (3 rows)
- [x] DB: government_bodies.body_key = 'Monroe County Board of Commissioners'
- [x] DB: 5 council politician+office rows correct, Munson is_vacant=true
