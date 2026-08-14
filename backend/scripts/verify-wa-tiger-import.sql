-- WA TIGER import verification (FIPS 53).
-- Loaded 2026-08-13 via:
--   npx tsx scripts/load-state-tiger-boundaries.ts --state WA --fips 53 --layers place,sldu,sldl
--
-- All queries below were run and confirmed on 2026-08-13.
-- NOTE the geometry column is named `geometry`, NOT `geom`.

-- 1. Layer counts.
SELECT mtfcc, count(*) AS n
FROM essentials.geofence_boundaries
WHERE state = '53'
GROUP BY mtfcc
ORDER BY mtfcc;
-- CONFIRMED 2026-08-13:
--   G4020 =  39  (counties, pre-existing)
--   G4110 = 281  (incorporated cities/towns, loaded 2026-08-13)
--   G5200 =  10  (congressional, pre-existing)
--   G5210 =  49  (STATE_UPPER — Senate; see query 3)
--   G5220 =  49  (STATE_LOWER — House polygons, 98 seats; see query 4)
--
-- The G4000 state polygon does NOT appear here: it is stored with
-- state = 'WA' (the abbreviation), not state = '53'. Query it separately:
--   SELECT geo_id, name FROM essentials.geofence_boundaries
--   WHERE mtfcc = 'G4000' AND state = 'WA';   -- => 53 | Washington

-- 2. Seattle's geo_id. Read, never assumed — four prior cities were seeded
--    against a wrong ESTIMATED geo_id.
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '53' AND mtfcc = 'G4110' AND name ILIKE 'Seattle%';
-- CONFIRMED 2026-08-13: exactly 1 row => 5363000 | Seattle city | G4110

-- 3. MTFCC orientation. This loader assigns sldu -> G5210 and sldl -> G5220,
--    INVERTED relative to a plain reading of the TIGER convention (and matching
--    how CA/VA/NV/AZ are handled here). Do NOT assume the standard mapping.
--
--    !! geo_id is NOT unique across MTFCCs in WA. '53001' is simultaneously
--    Adams County (G4020), Legislative District 1 upper (G5210), and
--    Legislative District 1 lower (G5220). Any districts <-> geofence join
--    MUST key on (geo_id, mtfcc) — joining on geo_id alone cross-products.
SELECT d.district_type, d.mtfcc, count(*) AS n
FROM essentials.districts d
WHERE d.state ILIKE 'wa' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
GROUP BY d.district_type, d.mtfcc
ORDER BY d.district_type;
-- CONFIRMED 2026-08-13:
--   STATE_LOWER | G5220 | 49
--   STATE_UPPER | G5210 | 49

-- 4. WA legislative districts are MULTI-MEMBER: 49 districts, each electing one
--    senator and TWO representatives over the SAME boundary. A STATE_LOWER count
--    of 98 would mean single-member polygons and would invalidate the
--    two-offices-per-district model in the structure migration.
SELECT count(*) AS state_lower_polygons
FROM essentials.districts
WHERE state ILIKE 'wa' AND district_type = 'STATE_LOWER';
-- CONFIRMED 2026-08-13: 49  (NOT 98)

-- 5. The loader ALSO wrote the 98 district rows itself (writeDistrictRow=true for
--    sldu/sldl). The structure migration therefore creates CHAMBERS and OFFICES
--    only — it must NOT re-create districts.
SELECT district_type, count(*) AS n, min(geo_id) AS lo, max(geo_id) AS hi
FROM essentials.districts
WHERE state ILIKE 'wa'
GROUP BY district_type
ORDER BY district_type;
-- CONFIRMED 2026-08-13:
--   COUNTY         | 39 | 53001 | 53077
--   NATIONAL_LOWER | 10 | 5301  | 5310
--   NATIONAL_UPPER |  1 | 53    | 53
--   STATE_EXEC     |  5 | 53    | 53
--   STATE_LOWER    | 49 | 53001 | 53049
--   STATE_UPPER    | 49 | 53001 | 53049
--
-- districts.state is 'wa' (LOWERCASE) for the STATE/COUNTY tiers.

-- 6. Geometry validity and SRID. A bad ring or a 4269 SRID silently breaks
--    point-in-polygon routing — the failure looks like "this address has no
--    representatives", not like an error.
SELECT count(*) FILTER (WHERE NOT ST_IsValid(geometry)) AS invalid_geoms,
       count(DISTINCT ST_SRID(geometry))                AS distinct_srids,
       min(ST_SRID(geometry))                           AS srid,
       count(*)                                         AS total
FROM essentials.geofence_boundaries
WHERE state = '53';
-- CONFIRMED 2026-08-13: invalid_geoms=0, distinct_srids=1, srid=4326, total=428
