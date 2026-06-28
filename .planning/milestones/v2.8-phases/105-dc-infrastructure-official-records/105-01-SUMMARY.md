# Phase 105-01 Summary: DC Infrastructure

**Status:** Complete  
**Completed:** 2026-06-07

## What Was Built

DC government stub, 19 district records, 8 ward TIGER polygons (geofence_boundaries + geo_districts), tiger_geoid backfill, and resolve_user_districts RPC extension.

## Commits

- `d8cfbcd` feat(105-01): migration 284 — DC government stub + 19 district records (DCIN-01, DCIN-02)
- `f0a6c10` feat(105-01): extend load-state-tiger-boundaries.ts for DC sldl — allowlist, type map, MTFCC assertion (DCIN-03)
- `8011eda` feat(105-01): DC ward boundaries — geofence_boundaries + geo_districts (DCIN-03)
- `6d229c1` feat(105-01): migration 285 — tiger_geoid backfill + dc_ward in RPC default (DCIN-04)

## Deviations

**DCIN-03 — TIGER URL 404:** `tl_2024_11_sldl.zip` returns 404 for all vintages (2022/2023/2024). Census does not publish a standalone DC SLDL shapefile. Adapted by creating `load-dc-ward-boundaries.ts` fetching from DC GIS MapServer layer 53 (Ward - 2022, `Administrative_Other_Boundaries_WebMercator`). This replaces both the planned Step A (TIGER import) and Step B (ogr2ogr bash script). The script writes to both `geofence_boundaries` (mtfcc=G5220) and `geo_districts` (layer=dc_ward) in one run.

**Pre-existing row:** `SELECT COUNT(*) FROM essentials.districts WHERE state='DC'` returns 20, not 19. The extra row (`geo_id='1198'`, `district_type='NATIONAL_LOWER'`) is a pre-existing Cicero-era import, not created by migration 284.

## Verification

```
geofence_boundaries WHERE state='11' AND mtfcc='G5220': 8 rows ✓
geo_districts WHERE layer='dc_ward': 8 rows ✓
districts WHERE state='DC' AND district_type='CITY_COUNCIL' AND geo_id LIKE 'dc-ward-%': 8 rows, all tiger_geoid set ✓
districts WHERE state='DC' AND district_type='CITY_COUNCIL' AND tiger_geoid IS NULL: 1 (dc-council-at-large) ✓
resolve_user_districts(38.9072, -77.0369): returns dc_ward/11002/Ward 2 ✓
```
