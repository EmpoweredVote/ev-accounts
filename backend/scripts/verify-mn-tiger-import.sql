-- verify-mn-tiger-import.sql — Knight Foundation program, wave MN-1. Read-only.
-- Run after the sldu/sldl load, and again after the place load.
--
-- ── THE ENACTED PLAN ────────────────────────────────────────────────────────────
--
--   L2022, ordered by the Minnesota Supreme Court Special Redistricting Panel in
--   Wattson v. Simon on 2022-02-15, first effective for the 2022 election.
--   67 Senate districts; 134 House districts, two per Senate district, labelled
--   with the Senate number plus A or B.
--   Published at gis.lcc.mn.gov/redist2020/plans.php?plname=L2022&pltype=court
--
-- 🔴 A COUNT OF 67 AND 134 PROVES NOTHING ABOUT WHICH MAP YOU HAVE. Minnesota's
--    2012 plan had the SAME 67/134 shape and the SAME A/B labelling, and TIGER's
--    LSY field is a field, not proof. The anchors below are the vintage test.
--
-- ── IDENTITY ANCHORS ────────────────────────────────────────────────────────────
--
-- Resolved 2026-09-12 against the Minnesota Legislative Coordinating Commission's
-- own point service — the enacted plan's publisher, independent of TIGER:
--   https://gis.lcc.mn.gov/iMaps/districts/php/getPointData.php?lat=<lat>&lng=<lng>
-- It is undocumented; the endpoint is in the app's own js/app.js (identifyDistrict).
-- Full provenance: backend/data/seed-mn-2026/SOURCES.md and anchors-L2022.json.
--
--   Duluth City Hall        (-92.1057144, 46.7828028) -> SD 27008 / HD 2708A
--   Saint Paul City Hall    (-93.0931028, 44.9439514) -> SD 27065 / HD 2765B
--   235 Marshall Ave, StP   (-93.1111422, 44.9482453) -> SD 27064 / HD 2764A
--   1200 Montreal Ave, StP  (-93.1502406, 44.9123744) -> SD 27064 / HD 2764B
--
-- 🔴 THE LAST TWO ARE AN A/B DISCRIMINATOR PAIR: same Senate district 64, different
--    House districts. They are the only test that catches an sldl load which
--    collapses a Senate district's two halves into one or swaps A with B. No single
--    point can detect either failure. BOTH must pass.
--
-- 🔴 DULUTH IS THE VINTAGE DISCRIMINATOR. Duluth's Senate seat was District 7 under
--    the 2012 plan and is District 8 under L2022 — Jen McEwen served District 7 from
--    2021 to 2023 and was re-elected in the renumbered District 8 in Nov 2022. If
--    Duluth City Hall returns 27007, TIGER has handed you the 2012 plan: roll the
--    load back, do not patch it.
--
-- ⚠ ALL FOUR ANCHORS ARE SINGLE SOURCE. Weaker than FL-1, which had a second
--   government-domain source for two of three. Ramsey County publishes no
--   legislative layer (all 60 operational layers read); the Secretary of State's
--   precinct finder sits behind a Radware bot manager and needs Playwright; St.
--   Louis County has not actually been searched. Stated, not hidden.
--
-- ── RESULTS, 2026-09-12 (apply run) ─────────────────────────────────────────────
--   201 boundaries + 201 districts inserted, 0 errors, 0 pre-existing.
--   All assertions below returned PASS.

\echo '=== 1. Record counts ==='
SELECT 'sldu districts'   AS check, count(*) AS got, 67  AS want,
       CASE WHEN count(*) = 67  THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM essentials.districts WHERE lower(state) = 'mn' AND district_type = 'STATE_UPPER'
UNION ALL
SELECT 'sldl districts', count(*), 134,
       CASE WHEN count(*) = 134 THEN 'PASS' ELSE 'FAIL' END
FROM essentials.districts WHERE lower(state) = 'mn' AND district_type = 'STATE_LOWER'
UNION ALL
SELECT 'geofence G5210', count(*), 67,
       CASE WHEN count(*) = 67  THEN 'PASS' ELSE 'FAIL' END
FROM essentials.geofence_boundaries WHERE state = '27' AND mtfcc = 'G5210'
UNION ALL
SELECT 'geofence G5220', count(*), 134,
       CASE WHEN count(*) = 134 THEN 'PASS' ELSE 'FAIL' END
FROM essentials.geofence_boundaries WHERE state = '27' AND mtfcc = 'G5220';

\echo ''
\echo '=== 2. ocd_id is DISTINCT per district ==='
-- 🔴 REGRESSION GUARD. The loader derived this suffix with parseInt, which drops a
--    trailing letter, so 08A and 08B both became .../sldl:8 — 134 districts
--    collapsing to 67 ocd_ids. ocd_id carries NO unique constraint, so it wrote
--    silently, and address search resolves on geo_id so no other gate could see it.
--    Fixed in src/lib/ocdDistrictSuffix.ts. Maryland still carries 24 such rows.
SELECT 'sldl DISTINCT ocd_id' AS check, count(DISTINCT ocd_id) AS got, 134 AS want,
       CASE WHEN count(DISTINCT ocd_id) = 134 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM essentials.districts WHERE lower(state) = 'mn' AND district_type = 'STATE_LOWER'
UNION ALL
SELECT 'sldu DISTINCT ocd_id', count(DISTINCT ocd_id), 67,
       CASE WHEN count(DISTINCT ocd_id) = 67 THEN 'PASS' ELSE 'FAIL' END
FROM essentials.districts WHERE lower(state) = 'mn' AND district_type = 'STATE_UPPER';

\echo ''
\echo '=== 3. Label structure: 67 senate-number groups of exactly 2 ==='
SELECT 'house groups NOT of size 2' AS check, count(*) AS got, 0 AS want,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (
  SELECT regexp_replace(geo_id, '[AB]$', '') AS g
  FROM essentials.districts
  WHERE lower(state) = 'mn' AND district_type = 'STATE_LOWER'
  GROUP BY 1 HAVING count(*) <> 2
) x;

\echo ''
\echo '=== 4. GEOMETRY nesting — measured, never inferred from the labels ==='
-- ⚠ Tennessee has an exact 3:1 House:Senate ratio and only 28 of 99 House districts
--   actually nest; Colorado behaves the same way. Minnesota's A/B naming invites the
--   assumption even more strongly. So assert it with PostGIS rather than believe it.
WITH h AS (
  SELECT geo_id, '27' || lpad(substr(regexp_replace(geo_id, '[AB]$', ''), 3), 3, '0') AS sd_expected,
         geometry
  FROM essentials.geofence_boundaries WHERE state = '27' AND mtfcc = 'G5220'
), s AS (
  SELECT geo_id, geometry FROM essentials.geofence_boundaries WHERE state = '27' AND mtfcc = 'G5210'
)
SELECT 'HD interior point inside its own SD' AS check,
       count(*) FILTER (WHERE ST_Covers(s.geometry, ST_PointOnSurface(h.geometry))) AS got,
       134 AS want,
       CASE WHEN count(*) FILTER (WHERE ST_Covers(s.geometry, ST_PointOnSurface(h.geometry))) = 134
            THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM h JOIN s ON s.geo_id = h.sd_expected;

\echo ''
\echo '=== 5. Per-district positive control: each resolves to EXACTLY one ==='
-- A green check:reachability means "nothing regressed"; it does NOT prove this
-- wave's own districts were examined (spec §5, corrected at GA-3). This does.
WITH probe AS (
  SELECT mtfcc, geo_id, ST_PointOnSurface(geometry) AS pt
  FROM essentials.geofence_boundaries WHERE state = '27' AND mtfcc IN ('G5210', 'G5220')
), hits AS (
  SELECT p.mtfcc,
         (SELECT count(*) FROM essentials.geofence_boundaries g
           WHERE g.state = '27' AND g.mtfcc = p.mtfcc AND ST_Covers(g.geometry, p.pt)) AS n
  FROM probe p
)
SELECT mtfcc AS check, count(*) FILTER (WHERE n = 1) AS got, count(*) AS want,
       CASE WHEN count(*) FILTER (WHERE n = 1) = count(*) THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM hits GROUP BY mtfcc ORDER BY mtfcc;

\echo ''
\echo '=== 6. IDENTITY ANCHORS — the vintage test ==='
WITH anchors(name, lon, lat, want_sd, want_hd) AS (VALUES
  ('Duluth City Hall',       -92.1057144, 46.7828028, '27008', '2708A'),
  ('Saint Paul City Hall',   -93.0931028, 44.9439514, '27065', '2765B'),
  ('235 Marshall Ave, StP',  -93.1111422, 44.9482453, '27064', '2764A'),
  ('1200 Montreal Ave, StP', -93.1502406, 44.9123744, '27064', '2764B')
)
SELECT a.name AS check,
       (SELECT string_agg(g.geo_id, ',') FROM essentials.geofence_boundaries g
         WHERE g.state = '27' AND g.mtfcc = 'G5210'
           AND ST_Covers(g.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))) AS got_sd,
       a.want_sd,
       (SELECT string_agg(g.geo_id, ',') FROM essentials.geofence_boundaries g
         WHERE g.state = '27' AND g.mtfcc = 'G5220'
           AND ST_Covers(g.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))) AS got_hd,
       a.want_hd
FROM anchors a;

\echo ''
\echo '=== 7. offices_missing_terms must NOT move — MN-1 creates districts, not offices ==='
SELECT 'offices_missing_terms' AS check, count(*) AS got, 822 AS want,
       CASE WHEN count(*) = 822 THEN 'PASS' ELSE 'INVESTIGATE' END AS verdict
FROM essentials.offices_missing_terms;

\echo ''
\echo '=== 8. AFTER THE PLACE LOAD ONLY — the two Knight places, BY GEOID ==='
-- 🔴 Match the GEOID, never the name. TIGER calls the capital "St. Paul", so a search
--    for "Saint Paul" matches NOTHING, while "%St. Paul%" matches FIVE Minnesota
--    cities — and St. Paul Park (2758018) shares the capital's first five characters.
--    Production also already holds a government row "City of Saint Paul, Texas, US".
SELECT 'Duluth 2717000 + St. Paul 2758000' AS check, count(*) AS got, 2 AS want,
       CASE WHEN count(*) = 2 THEN 'PASS' ELSE 'not loaded yet (Task 5)' END AS verdict
FROM essentials.geofence_boundaries
WHERE state = '27' AND mtfcc = 'G4110' AND geo_id IN ('2717000', '2758000');

\echo ''
\echo '⚠ AFTER THE PLACE LOAD, REFRESH THE CHILD->COUNTY MATVIEW.'
\echo '  G4110 IS a child (with G5420/G5400/G5410); G5210/G5220 are NOT, which is why'
\echo '  check:child-county passed after the sldu/sldl load without a refresh.'
\echo '    REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;'
\echo '    npm run check:child-county   -> expect "stale 0"'
