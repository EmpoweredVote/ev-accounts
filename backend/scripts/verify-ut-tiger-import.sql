-- Phase 131 Utah TIGER import verification -- SELECT only, no writes
-- Run against production (or EV-Backend-Dev) after loader completes.
-- All assertions must pass before phase is accepted.

-- GEO-08 Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '49' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- GEO-08 Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '49'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- GEO-01: Per-layer row counts — all mtfcc values must be non-zero
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '49'
GROUP BY mtfcc
ORDER BY mtfcc;
-- Expected: G5200=4, G5210>0, G5220>0, G5420>=41, G4110>0, G4020>=29

-- GEO-01: Congressional districts — 2026 court-redrawn map = exactly 4
SELECT COUNT(*) AS cd119_count
FROM essentials.geofence_boundaries
WHERE state = '49' AND mtfcc = 'G5200';
-- Expected: 4

-- GEO-02: County boundaries present (G4020 → COUNTY routing)
SELECT COUNT(*) AS county_count
FROM essentials.geofence_boundaries
WHERE state = '49' AND mtfcc = 'G4020';
-- Expected: >= 29

-- D-12: Unified school districts (soft floor — see PITFALLS.md UT-4)
SELECT COUNT(*) AS unsd_count
FROM essentials.geofence_boundaries
WHERE state = '49' AND mtfcc = 'G5420';
-- Expected: >= 41 (may include non-unified; manual spot-check against 41-district list)

-- Point-in-polygon spot checks (D-12; ST_MakePoint takes longitude, latitude)

-- Magna, UT — should match county G4020 + place G4110 (HB 356 metro township → city)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '49'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-112.1, 40.71), 4326));

-- Salt Lake City — should match county + place + sldu + sldl + cd119
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '49'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-111.891, 40.761), 4326));

-- Park City, UT (Summit County) — should match county + place
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '49'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-111.498, 40.646), 4326));

-- Antelope Island (Great Salt Lake) — should match Davis County G4020 only, NO place
-- Tests GEN-5 GeometryCollection guard: lakebed + park-edge geometries
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '49'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-112.2, 41.0), 4326));

-- Optional hygiene: VACUUM ANALYZE (Phase 134 VAL-03 will re-run as formal gate)
-- VACUUM ANALYZE essentials.geofence_boundaries;
