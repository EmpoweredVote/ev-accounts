-- preflight-la-wave1.sql
-- Re-runnable pre-flight script for Phase 108 Wave 1 (Gap-Fill Tier 1 Cities)
-- Run before AND after applying migrations 294-299 to confirm gaps and closures.
--
-- Usage: psql $DATABASE_URL -f backend/scripts/preflight-la-wave1.sql
--
-- Covers all 14 Tier 1 LA County cities already partially in DB:
--   Long Beach    (0643000)    Glendale    (0630000)    Burbank       (0608954)
--   Downey        (0619766)    El Monte    (0622230)    Inglewood     (0636546)
--   Lancaster     (0640130)    Norwalk     (0652526)    Palmdale      (0655156)
--   Pasadena      (0656000)    Pomona      (0658072)    Santa Clarita (0669088)
--   Torrance      (0680000)    West Covina (0684200)

-- ===========================================================================
-- SECTION 1: Aggregate count + geo_id check per city
-- ===========================================================================

\echo ''
\echo '=== AGGREGATE POLITICIAN COUNT BY CITY (geo_id, district_type) ==='
SELECT COUNT(*) AS politician_count, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id IN (
  '0643000','0630000','0608954','0619766','0622230','0636546',
  '0640130','0652526','0655156','0656000','0658072','0669088',
  '0680000','0684200'
)
GROUP BY d.geo_id, d.district_type
ORDER BY d.geo_id, d.district_type;

-- ===========================================================================
-- SECTION 2: Per-city detail rosters (name, title, district_type)
-- ===========================================================================

\echo ''
\echo '=== LONG BEACH (geo_id=0643000) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0643000'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== GLENDALE (geo_id=0630000) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0630000'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== BURBANK (geo_id=0608954) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0608954'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== DOWNEY (geo_id=0619766) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0619766'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== EL MONTE (geo_id=0622230) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0622230'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== INGLEWOOD (geo_id=0636546) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0636546'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== LANCASTER (geo_id=0640130) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0640130'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== NORWALK (geo_id=0652526) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0652526'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== PALMDALE (geo_id=0655156) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0655156'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== PASADENA (geo_id=0656000) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0656000'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== POMONA (geo_id=0658072) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0658072'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== SANTA CLARITA (geo_id=0669088) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0669088'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== TORRANCE (geo_id=0680000) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0680000'
ORDER BY d.geo_id, o.title, p.last_name;

\echo ''
\echo '=== WEST COVINA (geo_id=0684200) ==='
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0684200'
ORDER BY d.geo_id, o.title, p.last_name;

-- ===========================================================================
-- SECTION 3: External ID range clean check
-- ===========================================================================

\echo ''
\echo '=== EXTERNAL_ID RANGE CLEAN CHECK (-700199 to -700050) ==='
\echo 'Expected: used_in_range = 0 before any Wave 1 migrations are applied'
SELECT COUNT(*) AS used_in_range
FROM essentials.politicians
WHERE external_id BETWEEN -700199 AND -700050;

-- ===========================================================================
-- SECTION 4: geo_id null check (districts missing geo_id for these cities)
-- ===========================================================================

\echo ''
\echo '=== DISTRICTS MISSING geo_id FOR TIER 1 CITIES ==='
\echo 'These are districts that label-match but have no geo_id set yet'
SELECT id, label, district_type, state
FROM essentials.districts
WHERE state = 'CA'
  AND geo_id IS NULL
  AND (
    label ILIKE 'Long Beach%'
    OR label ILIKE 'Glendale%'
    OR label ILIKE 'Burbank%'
    OR label ILIKE 'Downey%'
    OR label ILIKE 'El Monte%'
    OR label ILIKE 'Inglewood%'
    OR label ILIKE 'Lancaster%'
    OR label ILIKE 'Norwalk%'
    OR label ILIKE 'Palmdale%'
    OR label ILIKE 'Pasadena%'
    OR label ILIKE 'Pomona%'
    OR label ILIKE 'Santa Clarita%'
    OR label ILIKE 'Torrance%'
    OR label ILIKE 'West Covina%'
  )
ORDER BY label;
