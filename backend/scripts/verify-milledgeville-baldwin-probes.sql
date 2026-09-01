-- verify-milledgeville-baldwin-probes.sql
--
-- GA-3 acceptance probe: Milledgeville + Baldwin County. READ-ONLY.
-- 🔴 RUN IT BEFORE THE APPLY AS WELL AS AFTER. FL-6 had a probe ruling that read
--    correctly against the wrong county, and running it early is what caught it.
--    Before the apply this scores 2 of 4; after, 4 of 4.
--
-- Wave GA-3 of the Knight Foundation cities program.
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
-- Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND GEORGIA IS WORSE THAN
--    FLORIDA: THE COLLISION IS THREE-WAY.
--
-- 13009 is Baldwin County (G4020) AND State House District 9 (G5220) AND State
-- Senate District 9 (G5210). All three rows are in production. Florida's
-- collision reached the county layer between two legislative layers; here three
-- layers overlap on one id at once. Probe 2 shows what the unpaired join returns.
--
-- ---------------------------------------------------------------------------
-- ⚠ BALDWIN COUNTY IS SPLIT BETWEEN TWO STATE HOUSE DISTRICTS -- HD-149 and
--   HD-128 -- so "the county's representative" is not a single answer. The city
--   of Milledgeville sits in HD-149. Confirmed against the Secretary of State's
--   2024 ballot, which carries both.
--
-- ⚠ THE COUNTY SEAT'S OWN HQ IS INSIDE THE CITY, AND THE TWO TIERS NUMBER THE
--   SAME GROUND DIFFERENTLY. Both addresses below are inside Milledgeville:
--
--     City Hall,      119 E Hancock St     -> city D2, commission D3
--     County Govt Bldg, 1601 N Columbia St -> city D5, commission D1
--
--   Four different district numbers across two addresses a mile apart. Probe 1b
--   asserts the second address precisely because a loader or migration that
--   crossed the tiers would still satisfy probe 1a.
\pset pager off

\echo
\echo == 1. Milledgeville City Hall, 119 E Hancock St ==
\echo ==    Geocoded by the Census to -83.226730175561, 33.081230307104. ==
\echo ==    The definition of done is FOUR REQUIRED answers: council D2, commission D3, ==
\echo ==    HD-149, SD-25. A city-hall address also legitimately elects the Mayor citywide ==
\echo ==    and all six county officers countywide, so more rows than four is correct. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-83.226730175561, 33.081230307104), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc, o.title,
       coalesce(p.full_name,
                CASE WHEN o.is_vacant THEN '(flagged vacant)' ELSE '(NO TERM ROW - INVISIBLE)' END) AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'ga'
   AND d.representation_basis = 'residency'
   AND (
     (gp.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
     OR (gp.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
     OR (gp.mtfcc = 'G4020' AND d.district_type = 'COUNTY')
     OR (gp.mtfcc IN ('G4110','G4120') AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
     OR (gp.mtfcc LIKE 'X%' AND d.district_type IN ('LOCAL','COUNTY'))
   )
 ORDER BY d.district_type, o.title;

\echo
\echo == 1a. THE DEFINITION OF DONE, asserted. Every row must read PRESENT. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-83.226730175561, 33.081230307104), 4326) AS g),
answers AS (
  SELECT d.district_type, d.geo_id, gp.mtfcc, o.title, p.full_name
    FROM pt
    JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
    JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'ga' AND d.representation_basis = 'residency'
),
required(n, what, dt, geo, mt) AS (VALUES
  (1, 'city council member', 'LOCAL',       'milledgeville-ga-council-district-2', 'X0042'),
  (2, 'county commissioner', 'COUNTY',      'baldwin-ga-commission-district-3',    'X0043'),
  (3, 'state representative','STATE_LOWER', '13149',                               'G5220'),
  (4, 'state senator',       'STATE_UPPER', '13025',                               'G5210')
)
SELECT r.n, r.what,
       coalesce(a.full_name, '*** ABSENT ***') AS holder,
       CASE WHEN a.full_name IS NOT NULL THEN 'PRESENT' ELSE '*** FAIL ***' END AS status
  FROM required r
  LEFT JOIN answers a
    ON a.district_type = r.dt AND a.geo_id = r.geo AND a.mtfcc = r.mt
 ORDER BY r.n;

\echo
\echo == 1b. SECOND ANCHOR: Baldwin County Govt Building, 1601 N Columbia St ==
\echo ==    Also inside the city. Expected city D5 and commission D1 -- DIFFERENT numbers ==
\echo ==    from probe 1a on both tiers. A wave that crossed the two tiers would pass 1a. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-83.2380, 33.0995), 4326) AS g),
answers AS (
  SELECT d.district_type, d.geo_id, gp.mtfcc, p.full_name
    FROM pt
    JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
    JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'ga' AND d.representation_basis = 'residency'
),
required(n, what, dt, geo, mt) AS (VALUES
  (1, 'city council member', 'LOCAL',  'milledgeville-ga-council-district-5', 'X0042'),
  (2, 'county commissioner', 'COUNTY', 'baldwin-ga-commission-district-1',    'X0043')
)
SELECT r.n, r.what,
       coalesce(a.full_name, '*** ABSENT ***') AS holder,
       CASE WHEN a.full_name IS NOT NULL THEN 'PRESENT' ELSE '*** FAIL ***' END AS status
  FROM required r
  LEFT JOIN answers a ON a.district_type = r.dt AND a.geo_id = r.geo AND a.mtfcc = r.mt
 ORDER BY r.n;

\echo
\echo == 2. The SAME point WITHOUT the mtfcc pairing -- the THREE-WAY collision in Georgia ==
\echo ==    Any row marked WRONG is an official the join reached through the wrong layer. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-83.226730175561, 33.081230307104), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc AS matched_via_layer,
       p.full_name AS holder,
       CASE WHEN d.mtfcc = gp.mtfcc THEN 'correct' ELSE '*** WRONG - COLLISION ***' END AS verdict
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'ga'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER','COUNTY')
 ORDER BY verdict DESC, d.label;

\echo
\echo == 3. Seats and occupancy, per body ==
\echo ==    Expected: Milledgeville City Council 6/6, Office of the Mayor 1/1, ==
\echo ==              Baldwin Board of Commissioners 5/5, Baldwin Elected Officials 6/6 ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id IN ('1351492','13009') AND g.type IN ('City','County')
 GROUP BY g.name, c.name ORDER BY g.name, c.name;

\echo
\echo == 4. Every GA local/county office with no term row and no vacancy flag (MUST be 0 rows) ==
\echo ==    An office with no term row is INVISIBLE and nothing errors. This is the one ==
\echo ==    failure mode CI cannot catch. ==
SELECT d.label, o.title, o.is_vacant
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_terms t ON t.office_id = o.id
 WHERE lower(d.state) = 'ga' AND d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY')
   AND t.id IS NULL AND o.is_vacant = false;

\echo
\echo == 5. The rulings that no count can see ==
SELECT 'R1 mayor voting_powers' AS ruling,
       coalesce((SELECT o.voting_powers::text
                   FROM essentials.offices o
                   JOIN essentials.chambers c ON c.id = o.chamber_id
                   JOIN essentials.governments g ON g.id = c.government_id
                  WHERE g.geo_id = '1351492' AND o.title = 'Mayor'), '*** ABSENT ***') AS value,
       'expected: full (Bradenton R2; charter is 2014 and silent)' AS expected
UNION ALL
SELECT 'R2 roles created as offices (chair/vice/pro-tem)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1351492','13009')
           AND (o.title ILIKE '%chair%' OR o.title ILIKE '%vice%' OR o.title ILIKE '%pro-tem%')),
       'expected: 0 -- they are parentheticals on the seat'
UNION ALL
SELECT 'R2 seats carrying a role note',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1351492','13009') AND o.description IS NOT NULL AND o.description <> ''),
       'expected: 2 -- county D2 Chairman, county D5 Vice Chairman'
UNION ALL
SELECT 'R3 excluded offices present (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '13009'
           AND (o.title ILIKE '%solicitor%' OR o.title ILIKE '%magistrate%'
                OR o.title ILIKE '%district attorney%' OR o.title ILIKE '%superior court judge%'
                OR o.title ILIKE '%school%')),
       'expected: 0 -- prosecutor, judicial branch, circuit, school board'
UNION ALL
SELECT 'R4 terms not open-ended unknown (must be 0)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.politicians p ON p.id = t.politician_id
         WHERE p.external_id BETWEEN -1331018 AND -1331001
           AND (t.start_precision <> 'unknown' OR t.term_start IS NOT NULL OR t.term_end IS NOT NULL)),
       'expected: 0 -- Georgia publishes no service-start'
UNION ALL
SELECT 'politicians in this wave''s band',
       (SELECT count(*)::text FROM essentials.politicians
         WHERE external_id BETWEEN -1331018 AND -1331001),
       'expected: 18'
UNION ALL
SELECT 'sheriff spelling (county layer says "Masse")',
       coalesce((SELECT p.full_name FROM essentials.politicians p WHERE p.external_id = -1331013), '*** ABSENT ***'),
       'expected: Bill Massee -- two e''s, per his own office';

\echo
\echo == 6. offices_missing_terms, which must not move ==
\echo ==    Baseline 2026-09-01: 821 total / 166 flagged / 655 UNFLAGGED. ==
\echo ==    The unflagged count is the load-bearing one. GA-3 creates no vacancy. ==
SELECT count(*) AS total,
       count(*) FILTER (WHERE is_vacant) AS flagged,
       count(*) FILTER (WHERE NOT is_vacant) AS unflagged
  FROM essentials.offices_missing_terms;
