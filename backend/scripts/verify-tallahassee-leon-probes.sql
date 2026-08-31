-- verify-tallahassee-leon-probes.sql
--
-- FL-4 acceptance probe: Tallahassee + Leon County. READ-ONLY. Run before and
-- after the applies.
--
-- Wave FL-3 of the Knight Foundation cities program.
-- Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND FLORIDA IS WHY.
--
-- 12073 is BOTH Leon County (G4020) AND State House District 73 (G5220), the same
-- county-layer collision that returned Collier County's representative for
-- Bradenton in FL-3. Probe 2 below demonstrates it live rather than describing it.
--
-- ---------------------------------------------------------------------------
-- ⚠ THE CITY ANSWER IS FIVE PEOPLE, NOT ONE.
--
-- Tallahassee's commission is entirely at-large -- five seats, and the Mayor is
-- SEAT 4 inside that numbering. So every Tallahassee address returns ALL FIVE
-- commissioners from the one citywide polygon. Probe 1a asserts a COUNT per
-- required answer for exactly this reason: "at least one city commissioner" would
-- pass with four of the five missing.
--
-- The anchor is Tallahassee City Hall, 300 S Adams St, which geocodes cleanly --
-- unlike Bradenton's ceremonial "101 Old Main Street", which the Census geocoder
-- does not resolve at all.
\pset pager off

\echo
\echo == 1. Tallahassee City Hall, 300 S Adams St ==
\echo ==    Required: all 5 city commissioners, County Commission District 5, HD-9, SD-3 ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-84.2820030, 30.4395411), 4326) AS g)
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
\echo == 1a. THE DEFINITION OF DONE, asserted as a COUNT per answer. All must read PASS. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-84.2820030, 30.4395411), 4326) AS g),
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
required(n, what, dt, geo, mt, want) AS (VALUES
  (1, 'city commissioners (all 5, at-large)', 'LOCAL',       '1270600',                         'G4110', 5),
  (2, 'county commissioner',                  'COUNTY',      'leon-fl-commissioner-district-5', 'X0038', 1),
  (3, 'state representative',                 'STATE_LOWER', '12009',                           'G5220', 1),
  (4, 'state senator',                        'STATE_UPPER', '12003',                           'G5210', 1)
)
SELECT r.n, r.what, r.want AS expected,
       count(a.full_name) AS got,
       CASE WHEN count(a.full_name) = r.want THEN 'PASS' ELSE '*** FAIL ***' END AS status,
       coalesce(string_agg(a.full_name, ', ' ORDER BY a.title), '(none)') AS holders
  FROM required r
  LEFT JOIN answers a
    ON a.district_type = r.dt AND a.geo_id = r.geo AND a.mtfcc = r.mt
 GROUP BY r.n, r.what, r.want
 ORDER BY r.n;

\echo
\echo == 2. What the SAME point returns WITHOUT the mtfcc pairing (the collision, for the record) ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-84.2820030, 30.4395411), 4326) AS g)
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
\echo ==    Expected: Tallahassee City Commission 5/5, Leon BOCC 7/7, ==
\echo ==              Leon Elected Officials 6/6 (SIX -- Leon is a charter county), 0 vacant ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id IN ('1270600','12073') AND g.type IN ('City','County')
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
\echo == 5. The rulings and blanks that no count can see ==
\echo ==    Expected: Mayor (Seat 4) full/no note; 9 unknown-precision; 9 dated; ==
\echo ==              6 officers in the Elected Officials chamber; 0 vacant ==
SELECT 'mayor is Seat 4, full voting, no note' AS ruling,
       (SELECT o.voting_powers || CASE WHEN o.representation_note IS NULL THEN ' / no note (correct)' ELSE ' / *** UNEXPECTED NOTE ***' END
          FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '1270600' AND o.title = 'Mayor (Seat 4)') AS value
UNION ALL
SELECT 'unknown-precision open starts (3 city + 6 officers)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1270600','12073')
           AND t.start_precision = 'unknown' AND t.term_start IS NULL)
UNION ALL
SELECT 'month-precision dated starts (2 city + 7 commissioners)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1270600','12073') AND t.start_precision = 'month')
UNION ALL
SELECT 'Leon Elected Officials chamber size (charter county -> 6)',
       (SELECT official_count::text FROM essentials.chambers c
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12073' AND c.name = 'Elected Officials')
UNION ALL
SELECT 'Superintendent of Schools seated (the 6th officer)',
       (SELECT coalesce(p.full_name, '*** ABSENT ***') FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
          LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
          LEFT JOIN essentials.politicians p ON p.id = och.politician_id
         WHERE g.geo_id = '12073' AND o.title = 'Superintendent of Schools')
UNION ALL
SELECT 'longest tenure (Proctor, District 1, since 1996)',
       (SELECT t.term_start::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE d.geo_id = 'leon-fl-commissioner-district-1' AND d.mtfcc = 'X0038'
           AND d.district_type = 'COUNTY')
UNION ALL
SELECT 'flagged vacant anywhere in this wave (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id IN ('1270600','12073') AND o.is_vacant = true);

\echo
\echo == 6. Negative control: a point outside the city must return NO city commissioner ==
\echo ==    Bradfordville is in Leon County but OUTSIDE Tallahassee: expect a county ==
\echo ==    commissioner and NO city seat. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-84.2380, 30.5560), 4326) AS g)
SELECT d.district_type, d.label, gp.mtfcc, o.title, p.full_name AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl' AND (gp.mtfcc = 'X0038' OR (gp.mtfcc = 'G4110' AND d.geo_id = '1270600'))
 ORDER BY d.district_type, o.title;
