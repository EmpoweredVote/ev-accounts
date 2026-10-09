-- AK TIGER place (G4110) import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-ak-tiger-import.sql
-- Scope: `place` layer only (Read & Rank city-name lookup). AK "counties" (G4020, 30) are
-- boroughs / census areas and pre-existed.
-- Raw TIGER 2024 FIPS 02 place file, measured 2026-10-06: 149 G4110 + 206 G4210 CDPs
-- (the loader keeps G4110 only).

-- Gate 1: Per-layer row counts for Alaska (state is 2-digit FIPS)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '02'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|30, G4110|149, G5200|1, G6350|245 (G4020/G5200/G6350 pre-existing)

-- Gate 2: No null names / geometries and no invalid or non-polygon geometry on G4110 — MUST be all 0
SELECT count(*) FILTER (WHERE name IS NULL OR name = '')                                  AS null_names,
       count(*) FILTER (WHERE geometry IS NULL)                                           AS null_geoms,
       count(*) FILTER (WHERE NOT ST_IsValid(geometry))                                   AS invalid_geoms,
       count(*) FILTER (WHERE ST_GeometryType(geometry) NOT IN ('ST_Polygon','ST_MultiPolygon')) AS non_polygon,
       count(DISTINCT ST_SRID(geometry))                                                  AS distinct_srids
FROM essentials.geofence_boundaries
WHERE state = '02' AND mtfcc = 'G4110';
-- Expected: 0, 0, 0, 0, 1

-- Gate 3: Identity probes — exact geo_id (STATEFP + PLACEFP)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '02' AND mtfcc = 'G4110' AND geo_id IN ('0203000', '0224230', '0236400')
ORDER BY geo_id;
-- Expected: 0203000 Anchorage municipality · 0224230 Fairbanks city · 0236400 Juneau city and borough

-- Gate 4: Every AK place resolves to a county-equivalent (after REFRESH of essentials.geofence_child_county)
SELECT count(*) AS places_without_county
FROM essentials.geofence_boundaries b
LEFT JOIN essentials.geofence_child_county cc
  ON cc.child_geo_id = b.geo_id AND cc.child_mtfcc = 'G4110'
WHERE b.state = '02' AND b.mtfcc = 'G4110' AND cc.county_geo_id IS NULL;
-- Expected: 0 or a small number — Alaska's boroughs do not tile the state (the Unorganized
-- Borough is split into census areas), so investigate any non-zero count before accepting it.

-- Gate 5: Stale-view check — MUST return 0 rows for AK
SELECT * FROM essentials.geofence_child_county_stale WHERE state = '02' LIMIT 10;
