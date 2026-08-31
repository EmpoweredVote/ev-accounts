-- verify-bradenton-manatee-probes.sql
--
-- FL-3 acceptance probe: Bradenton + Manatee County. READ-ONLY. Run before and
-- after the applies.
--
-- Wave FL-3 of the Knight Foundation cities program.
-- Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND FLORIDA IS WHY.
--
-- 12081 is BOTH Manatee County (G4020) AND State House District 81 (G5220).
-- 12020 is BOTH Senate District 20 (G5210) AND House District 20 (G5220).
--
-- Run WITHOUT the pairing, this probe returned FOUR rows at Bradenton City Hall
-- on 2026-08-28 -- and two of them were officials in other counties: HD-20's
-- member in north Florida, matched through the SD-20 polygon, and HD-81's member
-- in Collier County, matched through the MANATEE COUNTY polygon. Nothing errored.
-- fl.md documented only the sldl/sldu half of this collision.
--
-- ---------------------------------------------------------------------------
-- ⚠ CITY HALL'S PUBLISHED ADDRESS DOES NOT GEOCODE. "101 Old Main Street"
-- returns 0 matches from the Census geocoder. The city's own footer explains it:
-- city hall is "At the corner of Old Main Street (12th St. W.) and Barcarrota
-- Boulevard". 101 12TH ST W, BRADENTON, FL 34205 geocodes to the point below.
\pset pager off

\echo
\echo == 1. Bradenton City Hall, 101 12th St W (a.k.a. 101 Old Main St) ==
\echo ==    The definition of done is FOUR REQUIRED answers: Ward 3 council member, ==
\echo ==    Commissioner District 3, HD-71, SD-20. ==
\echo ==    Measured 2026-08-28 this returns TWELVE rows, and that is correct: a city-hall ==
\echo ==    address also legitimately elects the Mayor citywide, both at-large commissioners ==
\echo ==    and all five constitutional officers. Probe 1a asserts the four; this lists all. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-82.5733305, 27.5000582), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc, o.title,
       coalesce(p.full_name,
                CASE WHEN o.is_vacant THEN '(flagged vacant)' ELSE '(NO TERM ROW - INVISIBLE)' END) AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl'
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
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-82.5733305, 27.5000582), 4326) AS g),
answers AS (
  SELECT d.district_type, d.geo_id, gp.mtfcc, o.title, p.full_name
    FROM pt
    JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
    JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'fl' AND d.representation_basis = 'residency'
),
required(n, what, dt, geo, mt) AS (VALUES
  (1, 'city council member', 'LOCAL',       'bradenton-fl-council-ward-3',        'X0036'),
  (2, 'county commissioner', 'COUNTY',      'manatee-fl-commissioner-district-3', 'X0037'),
  (3, 'state representative','STATE_LOWER', '12071',                              'G5220'),
  (4, 'state senator',       'STATE_UPPER', '12020',                              'G5210')
)
SELECT r.n, r.what,
       coalesce(a.full_name, '*** ABSENT ***') AS holder,
       CASE WHEN a.full_name IS NOT NULL THEN 'PRESENT' ELSE '*** FAIL ***' END AS status
  FROM required r
  LEFT JOIN answers a
    ON a.district_type = r.dt AND a.geo_id = r.geo AND a.mtfcc = r.mt
 ORDER BY r.n;

\echo
\echo == 2. What the SAME point returns WITHOUT the mtfcc pairing (the collision, for the record) ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-82.5733305, 27.5000582), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc AS matched_via_layer, p.full_name AS holder,
       CASE WHEN d.mtfcc = gp.mtfcc THEN 'correct' ELSE '*** WRONG - COLLISION ***' END AS verdict
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
 ORDER BY verdict DESC, d.label;

\echo
\echo == 3. Seats and occupancy, per body ==
\echo ==    Expected: Bradenton City Council 5/5, Office of the Mayor 1/1, ==
\echo ==              Manatee BOCC 7 offices / 6 seated / 1 vacant, Elected Officials 5/5 ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id IN ('1207950','12081') AND g.type IN ('City','County')
 GROUP BY g.name, c.name ORDER BY g.name, c.name;

\echo
\echo == 4. Every FL local/county office with no term row and no vacancy flag (MUST be 0 rows) ==
\echo ==    An office with no term row is INVISIBLE and nothing errors. This is the one ==
\echo ==    failure mode CI cannot catch. ==
SELECT d.label, o.title, o.is_vacant
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_terms t ON t.office_id = o.id
 WHERE lower(d.state) = 'fl' AND d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY')
   AND t.id IS NULL AND o.is_vacant = false;

\echo
\echo == 5. The rulings that no count can see ==
\echo ==    Expected: Mayor full + tie-break description; 3 appointments; 3 unknown-precision; ==
\echo ==              District 1 vacant since 2026-02-24 ==
SELECT 'mayor voting_powers/description' AS ruling,
       (SELECT o.voting_powers || ' / ' || CASE WHEN o.description ILIKE '%tie%' THEN 'tie-break text present' ELSE '*** MISSING ***' END
          FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '1207950' AND o.title = 'Mayor') AS value
UNION ALL
SELECT 'appointed terms (Barnebey, Schuessler, Colonneso)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1207950','12081') AND t.how_started = 'appointed')
UNION ALL
SELECT 'unknown-precision open starts (Kocher, Moore, Coachman)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1207950','12081')
           AND t.start_precision = 'unknown' AND t.term_start IS NULL)
UNION ALL
SELECT 'District 1 vacant_since',
       (SELECT coalesce(o.vacant_since::date::text, '*** NOT SET ***')
          FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
         WHERE d.geo_id = 'manatee-fl-commissioner-district-1' AND d.mtfcc = 'X0037'
           AND d.district_type = 'COUNTY')
UNION ALL
SELECT 'nickname alternate_names',
       (SELECT count(*)::text FROM essentials.politicians
         WHERE external_id BETWEEN -1249999 AND -1240000
           AND array_length(alternate_names, 1) > 0);

\echo
\echo == 6. Negative control: a Palmetto address must NOT return a Bradenton council member ==
\echo ==    Palmetto is in Manatee County, so it SHOULD return a commissioner and no ward. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-82.5728926, 27.5153915), 4326) AS g)
SELECT d.district_type, d.label, gp.mtfcc, o.title, p.full_name AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl' AND gp.mtfcc IN ('X0036','X0037')
 ORDER BY d.district_type, o.title;
