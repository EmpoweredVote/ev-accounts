---
phase: 123-ward-geofencing-all-7-cities
plan: "01"
subsystem: geofencing
tags:
  - massgis
  - ward-boundaries
  - geofence_boundaries
  - x0014
  - polygon-import
dependency_graph:
  requires:
    - "120-01: Newton, Somerville, Lynn, Fall River, Waltham, Medford, New Bedford district records (FK targets for migrations 706-712)"
  provides:
    - "54 X0014 dissolved ward polygons for all 7 Phase 123 cities"
    - "Migrations 706-712 pre-flight guards are unblocked"
  affects:
    - "essentials.geofence_boundaries (54 new X0014 rows)"
tech_stack:
  added: []
  patterns:
    - "MassGIS WARDSPRECINCTS2022_POLY FeatureServer — single dataset for all 7 MA cities"
    - "encodeURIComponent handles FALL%20RIVER and NEW%20BEDFORD space-in-TOWN correctly"
    - "ST_Union precinct dissolution inside PostgreSQL pool.query (not client-side JS)"
    - "ON CONFLICT (geo_id, mtfcc) DO NOTHING — idempotent insert pattern"
key_files:
  created: []
  modified:
    - backend/scripts/load-ma-ward-boundaries.ts
decisions:
  - "CITY_CONFIGS extended with 7 quoted-key entries ('FALL RIVER', 'NEW BEDFORD' use string literal keys); ALLOWED_CITIES auto-derives from Object.keys(CITY_CONFIGS)"
  - "parseArgs() error messages updated to document space-quoted city name pattern — no parsing logic changes needed since shell quotes deliver 'FALL RIVER' as a single args[] element"
  - "Task 2 committed as empty commit — data lives in DB, no source files changed post-Task-1"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-16"
  tasks_completed: 2
  files_modified: 1
---

# Phase 123 Plan 01: Extend load-ma-ward-boundaries.ts + Load 54 Ward Polygons Summary

Extended `load-ma-ward-boundaries.ts` with 7 new CITY_CONFIGS entries (NEWTON, SOMERVILLE, LYNN, 'FALL RIVER', WALTHAM, MEDFORD, 'NEW BEDFORD') and loaded 54 dissolved X0014 ward polygons into essentials.geofence_boundaries for all 7 Phase 123 cities.

## Tasks Completed

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 1 | Extend load-ma-ward-boundaries.ts with 7 new city configs | DONE | 6e1ac4d6 |
| 2 | Run polygon imports for all 7 cities | DONE | 82590061 |

## What Was Built

### Task 1: Script Extension

Modified `backend/scripts/load-ma-ward-boundaries.ts`:

- Added 7 new entries to CITY_CONFIGS map (11 total, up from 4): NEWTON, SOMERVILLE, LYNN, 'FALL RIVER', WALTHAM, MEDFORD, 'NEW BEDFORD'
- Updated file-level ward counts comment block with all 7 new cities and verified counts
- Added 7 new usage examples to file header including `--city "FALL RIVER"` and `--city "NEW BEDFORD"` quoted patterns
- Updated parseArgs() error messages to self-document the space-quoted city name pattern
- ALLOWED_CITIES constant auto-extends via Object.keys(CITY_CONFIGS) — no manual allowlist changes needed
- TypeScript compiles without errors (`npx tsc --noEmit` exits 0)

### Task 2: Data Load

Ran `load-ma-ward-boundaries.ts` for all 7 cities in sequence. Results:

| City | Run | Ward Groups | Precincts/Ward | Rows Inserted | Status |
|------|-----|-------------|----------------|---------------|--------|
| NEWTON | Dry-run + Live | 8 | 4 | 8 | All loaded |
| SOMERVILLE | Live | 7 | 4 | 7 | All loaded |
| LYNN | Live | 7 | 4 | 7 | All loaded |
| FALL RIVER | Live | 9 | 3 | 9 | All loaded (URL: FALL%20RIVER) |
| WALTHAM | Live | 9 | 2 | 9 | All loaded |
| MEDFORD | Live | 8 | 2 | 8 | All loaded |
| NEW BEDFORD | Live | 6 | 6 | 6 | All loaded (URL: NEW%20BEDFORD) |

**Verification query result:**
```
newton=8, somerville=7, lynn=7, fall_river=9, waltham=9, medford=8, new_bedford=6, total=54
```

All 54 rows: mtfcc='X0014', state='25', geometry non-null (dissolved ward polygons in WGS-84 / SRID 4326).

## Must-Have Verification

| Criterion | Result |
|-----------|--------|
| CITY_CONFIGS has 11 entries (4 existing + 7 new) | PASS |
| 'FALL RIVER' and 'NEW BEDFORD' as quoted string keys | PASS |
| 8 newton-ma-council-ward-N rows in geofence_boundaries, mtfcc=X0014 | PASS (8) |
| 7 somerville-ma-council-ward-N rows | PASS (7) |
| 7 lynn-ma-council-ward-N rows | PASS (7) |
| 9 fall-river-ma-council-ward-N rows | PASS (9) |
| 9 waltham-ma-council-ward-N rows | PASS (9) |
| 8 medford-ma-council-ward-N rows | PASS (8) |
| 6 new-bedford-ma-council-ward-N rows | PASS (6) |
| Total: 54 dissolved ward polygons (not precinct count) | PASS (54) |
| TypeScript compiles without errors | PASS |
| Fall River space-in-TOWN: URL = FALL%20RIVER | PASS (confirmed from script log) |
| New Bedford space-in-TOWN: URL = NEW%20BEDFORD | PASS (confirmed from script log) |
| Dry-run NEWTON shows 8 ward groups (not 32 precincts) | PASS |
| All 7 cities end with "loaded successfully" message, zero warnings | PASS |

## Deviations from Plan

None — plan executed exactly as written.

The parseArgs() analysis in the plan noted "The real issue is..." (no code change needed for space handling since shell quotes ensure the arg arrives as a single element). Confirmed: `--city "FALL RIVER"` delivers args[cityIdx+1] = 'FALL RIVER' as a single element. Only the error messages needed updating to document this pattern for operators.

## Security Review

No security-relevant surface changes. All work is:
- Admin CLI scripts run by operators (no user input, no API endpoints)
- All MassGIS WARD field values validated via parseInt + isNaN + range check (T-123-M1)
- City names validated against CITY_CONFIGS allowlist before any DB/HTTP use (T-123-M2)
- URL construction uses encodeURIComponent for TOWN values (T-123-M2)
- All SQL parameters via $N placeholders — no string interpolation (T-119-M1 inherited)
- Post-insert row count verifies dissolved ward count matches wardCount arg (T-123-M3)

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Known Stubs

None — all 54 ward polygons are real dissolved MassGIS geometry, not placeholder data.

## Next Steps

- Plan 02: SQL migrations 706-712 (one per city) — per-ward district rows, tiger_geoid backfill, office re-links for cities with ward seats (Newton, Somerville, Lynn, Waltham, New Bedford)
- Plan 03: Phase gate verification (verify-phase-123.sql assertions for all MAGE-16..22)

## Self-Check: PASSED

- `backend/scripts/load-ma-ward-boundaries.ts` exists and has 11 CITY_CONFIGS entries: VERIFIED
- Commit 6e1ac4d6 exists: VERIFIED (Task 1 — script extension)
- Commit 82590061 exists: VERIFIED (Task 2 — data load record)
- 54 X0014 rows in essentials.geofence_boundaries: VERIFIED via SQL query
