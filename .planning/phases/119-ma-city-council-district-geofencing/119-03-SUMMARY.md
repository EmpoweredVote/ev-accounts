---
plan: 119-03
phase: 119-ma-city-council-district-geofencing
status: complete
completed: "2026-06-15"
subsystem: geofencing
tags: [massgis, postgis, ward-boundaries, city-council, geofencing, migration]
dependency_graph:
  requires: [119-01]
  provides: [MAGE-12, MAGE-13, MAGE-14, MAGE-15]
  affects: [essentials.districts, essentials.offices, essentials.geofence_boundaries]
tech_stack:
  added: []
  patterns:
    - ST_Union dissolution of MassGIS precinct polygons into ward polygons (Option B via unnest($5::text[]))
    - Parameterized multi-city import script with city allowlist validation
    - Migration pre-flight RAISE EXCEPTION enforcing script-first ordering (T-119-M4)
    - Lowell LOCAL_EXEC omission pattern for Plan E council-manager cities
    - Non-round FIPS guard pattern for Quincy '2555745' exact string
key_files:
  created:
    - backend/scripts/load-ma-ward-boundaries.ts
    - backend/migrations/661_springfield_council_ward_geofencing.sql
    - backend/migrations/662_lowell_council_district_geofencing.sql
    - backend/migrations/663_brockton_council_ward_geofencing.sql
    - backend/migrations/664_quincy_council_ward_geofencing.sql
  modified: []
decisions:
  - load-ma-ward-boundaries.ts uses Option B (unnest + ST_Union aggregate) to dissolve precincts — handles variable precinct counts per ward without dynamic SQL
  - Migration 660 (Worcester) was written by parallel agent; 661-664 based on 119-RESEARCH.md patterns + migration 659 structure
metrics:
  duration: "~25 minutes"
  completed: "2026-06-15"
  tasks: 2
  files: 5
---

# Phase 119 Plan 03: Springfield/Lowell/Brockton/Quincy Ward Geofencing Summary

## What Was Built

`load-ma-ward-boundaries.ts` — a parameterized script that fetches precinct polygons from MassGIS WARDSPRECINCTS2022_POLY FeatureServer, dissolves them per ward/district using ST_Union inside PostgreSQL (Option B: unnest array), and inserts one dissolved polygon per ward into `essentials.geofence_boundaries`. Accepts `--city SPRINGFIELD|LOWELL|BROCKTON|QUINCY` and `--ward-count N`.

Migrations 661-664 — one per city — each insert per-ward LOCAL district rows, backfill `tiger_geoid` on the ward rows and citywide rows, and re-link ward/district councillors from the citywide LOCAL district to their per-ward LOCAL district, enabling Path 0 geofencing for all ward-based seats.

## Key Files

### Created

- `backend/scripts/load-ma-ward-boundaries.ts` — Parameterized MassGIS precinct dissolution script. CRITICAL comments: Worcester excluded; TOWN must be uppercase; outSR=4326 required. City config lookup table for 4 cities. ST_Union Option B via unnest($5::text[]). Post-import count verification ensures ward count matches (not precinct count).
- `backend/migrations/661_springfield_council_ward_geofencing.sql` — Springfield: 8 per-ward rows; tiger_geoid on 8 wards + 2 citywide; 8 ward councillors re-linked.
- `backend/migrations/662_lowell_council_district_geofencing.sql` — Lowell: 8 per-district rows; tiger_geoid on 8 districts + 1 citywide LOCAL only (NO LOCAL_EXEC — Plan E); 8 district councillors re-linked.
- `backend/migrations/663_brockton_council_ward_geofencing.sql` — Brockton: 7 per-ward rows; tiger_geoid on 7 wards + 2 citywide; 7 ward councillors re-linked.
- `backend/migrations/664_quincy_council_ward_geofencing.sql` — Quincy: 6 per-ward rows; tiger_geoid on 6 wards + 2 citywide; 6 ward councillors re-linked. '2555745' exact non-round FIPS used throughout.

## Verification Results

### Task 1 — Script runs and geofence_boundaries

| Gate | Expected | Actual |
|------|----------|--------|
| Springfield dry-run: 64 precincts, 8 ward groups | 8 groups | 8 ✅ |
| Total X0014 ward rows (all 4 cities) | 29 | 29 ✅ |
| Springfield rows | 8 | 8 ✅ |
| Lowell rows | 8 | 8 ✅ |
| Brockton rows | 7 | 7 ✅ |
| Quincy rows | 6 | 6 ✅ |

### Task 2 — Migrations 661-664

| Gate | Expected | Actual |
|------|----------|--------|
| MAX(version) after 664 | '664' | '664' ✅ |
| Springfield per-ward rows with tiger_geoid | 8 | 8 ✅ |
| Lowell per-district rows with tiger_geoid | 8 | 8 ✅ |
| Brockton per-ward rows with tiger_geoid | 7 | 7 ✅ |
| Quincy per-ward rows with tiger_geoid | 6 | 6 ✅ |
| Springfield ward councillors still at citywide 2567000 | 0 | 0 ✅ |
| Lowell district councillors still at citywide 2537000 | 0 | 0 ✅ |
| Brockton ward councillors still at citywide 2509000 | 0 | 0 ✅ |
| Quincy ward councillors still at citywide 2555745 | 0 | 0 ✅ |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration 660 (Worcester) not available**
- **Found during:** Task 2 setup (reading plan requires migration 660 as structural reference)
- **Issue:** Migration 660 was being written by a parallel agent (119-02) and did not exist on disk when 119-03 began execution.
- **Fix:** Used migration 659 (Boston tiger_geoid backfill) and the detailed specs in 119-RESEARCH.md as the structural reference instead. The structure matches exactly — pre-flight RAISE EXCEPTION, BEGIN/COMMIT, per-ward INSERTs, tiger_geoid UPDATEs, office re-links, post-verification DO block, ledger INSERT.
- **Files modified:** None — design deviation only; output files are structurally identical to what migration 660 would have specified.
- **Commit:** Part of feat(119-03) Task 2 commit 806a6a71.

## Per-City Gate Confirmation

**Springfield (migration 661) — MAGE-12:**
- 8 per-ward LOCAL rows with tiger_geoid (springfield-ma-council-ward-1..8)
- 8 ward councillors (Perez/Fenton/Edwards/Brown/Click-Bruce/Davila/Martin/Govan, ext_ids -256700002..-256700009) re-linked to per-ward rows
- At-large (Hurst/Delgado/Walsh/Whitfield/Santaniello, ext_ids -256700010..-256700014) remain at citywide 2567000 LOCAL
- Citywide LOCAL + LOCAL_EXEC tiger_geoid set for Mayor Sarno + at-large Path 0

**Lowell (migration 662) — MAGE-13:**
- 8 per-district LOCAL rows with tiger_geoid (lowell-ma-council-district-1..8)
- 8 district councillors (Rourke/Robinson/Juran/McDonough/Scott/Chau/Liang/Descoteaux, ext_ids -253700005..-253700012) re-linked to per-district rows
- City Manager/Mayor/at-large (Golden/Gitschier/Mercier/Nuon, ext_ids -253700001..-253700004) remain at citywide 2537000 LOCAL
- NO LOCAL_EXEC tiger_geoid step (Plan E council-manager — Lowell has no exec district, confirmed migration 353)

**Brockton (migration 663) — MAGE-14:**
- 7 per-ward LOCAL rows with tiger_geoid (brockton-ma-council-ward-1..7)
- 7 ward councillors (Green/Tavares/Griffin/Nicastro/Thompson/Lally/Asack, ext_ids -250900002..-250900008) re-linked to per-ward rows
- At-large (Darosa/Charnel/Farwell/Teixeira, ext_ids -250900009..-250900012) remain at citywide 2509000 LOCAL
- Citywide LOCAL + LOCAL_EXEC tiger_geoid set for Mayor Rodrigues + at-large Path 0

**Quincy (migration 664) — MAGE-15:**
- 6 per-ward LOCAL rows with tiger_geoid (quincy-ma-council-ward-1..6)
- 6 ward councillors (Jacobs/Ash/Hubley/Ryan/McKee/Riley, ext_ids -255574502..-255574507) re-linked to per-ward rows
- At-large (DiBona/Mahoney/Yuan, ext_ids -255574508..-255574510) remain at citywide 2555745 LOCAL
- Citywide LOCAL + LOCAL_EXEC tiger_geoid set for Mayor Koch + at-large Path 0
- '2555745' non-round FIPS used as exact string in all WHERE clauses

## Self-Check: PASSED

- `backend/scripts/load-ma-ward-boundaries.ts` — FOUND ✅
- `backend/migrations/661_springfield_council_ward_geofencing.sql` — FOUND ✅
- `backend/migrations/662_lowell_council_district_geofencing.sql` — FOUND ✅
- `backend/migrations/663_brockton_council_ward_geofencing.sql` — FOUND ✅
- `backend/migrations/664_quincy_council_ward_geofencing.sql` — FOUND ✅
- Commit d2b4c71a (Task 1: script + script runs) — FOUND ✅
- Commit 806a6a71 (Task 2: migrations 661-664) — FOUND ✅
- DB MAX(version) = '664' ✅
- 29 X0014 geofence boundary rows ✅
- 8+8+7+6 = 29 district rows with tiger_geoid ✅
- 0+0+0+0 ward councillors remaining at citywide LOCAL ✅

MAGE-12 ✅ Springfield 8 per-ward X0014 geofence rows loaded; 8 LOCAL ward rows with tiger_geoid; 8 ward councillors re-linked.
MAGE-13 ✅ Lowell 8 per-district X0014 geofence rows loaded; 8 LOCAL district rows with tiger_geoid; 8 district councillors re-linked.
MAGE-14 ✅ Brockton 7 per-ward X0014 geofence rows loaded; 7 LOCAL ward rows with tiger_geoid; 7 ward councillors re-linked.
MAGE-15 ✅ Quincy 6 per-ward X0014 geofence rows loaded; 6 LOCAL ward rows with tiger_geoid; 6 ward councillors re-linked.
