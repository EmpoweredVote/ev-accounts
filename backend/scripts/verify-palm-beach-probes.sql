-- verify-palm-beach-probes.sql
--
-- FL-5 acceptance probe: Palm Beach County. READ-ONLY. Run before and after the
-- apply.
--
-- Wave FL-5 of the Knight Foundation cities program.
-- Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md
--
-- ---------------------------------------------------------------------------
-- 🔴 THREE REQUIRED ANSWERS, NOT FOUR, AND THAT IS CORRECT.
--
-- Palm Beach County has NO CITY HALF in this program. The anchor -- the county
-- Governmental Center, 301 N Olive Ave -- sits inside TIGER place 1276600, the
-- City of West Palm Beach, which is deliberately NOT seated. So a municipal
-- official is legitimately absent from every answer set below.
--
-- ⚠ DO NOT READ THE MISSING FOURTH ANSWER AS A FAILURE. FL-3 and FL-4 both
-- anchored on a city hall and asserted four answers; this wave is a stage-4
-- county wave on its own. Compare FL-2's note that Miami has no state
-- representative at all while HD-113 is vacant: the honest record of an absence
-- is not a defect.
--
-- A fourth assertion IS made below, but it is not the city slot -- it is the five
-- constitutional officers, which every Palm Beach address elects countywide and
-- which are what most of the county's 1.5 million residents actually get.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND PALM BEACH IS THE THIRD
-- FLORIDA COUNTY IN THREE WAVES TO PROVE IT.
--
-- 12099 is BOTH Palm Beach County (G4020) AND State House District 99 (G5220),
-- after 12081/HD-81 (Manatee) and 12073/HD-73 (Leon). Probe 2 demonstrates it
-- live rather than describing it, and at this anchor it is the richest
-- demonstration in the slice: THREE wrong rows, one in each failure direction.
--
-- ---------------------------------------------------------------------------
-- ⚠ SEVEN SINGLE-MEMBER DISTRICTS AND NO AT-LARGE COMMISSIONER, so exactly ONE
-- commissioner answers at any address and the countywide district carries FIVE
-- offices -- the officers, and nothing else. Leon's carries eight and Manatee's
-- seven.
--
-- The anchor geocodes cleanly: 301 N OLIVE AVE, WEST PALM BEACH, FL 33401 returns
-- exactly one Census match at -80.051906016174, 26.71529321541.
\pset pager off

\echo
\echo == 1. Palm Beach County Governmental Center, 301 N Olive Ave ==
\echo ==    Required: Commission District 7, HD-87, SD-24, and all 5 officers ==
\echo ==    NO city seat -- West Palm Beach is not in scope. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.051906016174, 26.71529321541), 4326) AS g)
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
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.051906016174, 26.71529321541), 4326) AS g),
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
-- 🔴 Answers 1-3 are the three required by the plan. Answer 4 is the countywide
--    officers -- not the absent city slot. There is no fourth REQUIRED answer at
--    this anchor, and answer 5 states that absence as an assertion rather than
--    leaving it to be noticed.
required(n, what, dt, geo, mt, want) AS (VALUES
  (1, 'county commissioner (District 7, single-member)', 'COUNTY',      'palm-beach-fl-commissioner-district-7', 'X0039', 1),
  (2, 'state representative (HD-87)',                    'STATE_LOWER', '12087',                                 'G5220', 1),
  (3, 'state senator (SD-24)',                           'STATE_UPPER', '12024',                                 'G5210', 1),
  (4, 'constitutional officers (all 5, countywide)',     'COUNTY',      '12099',                                 'G4020', 5),
  (5, 'city seat -- LEGITIMATELY ABSENT, must be 0',     'LOCAL',       '1276600',                               'G4110', 0)
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
\echo ==    Expected: 3 correct + 3 WRONG. Monroe County via the HD-87 sldl polygon; ==
\echo ==    HD-24 via the SD-24 sldu polygon; HD-99 via the Palm Beach County OWN G4020 ==
\echo ==    polygon. All three failure directions in one query, and nothing errors. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.051906016174, 26.71529321541), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc AS matched_via_layer,
       coalesce(p.full_name, '(no holder)') AS holder,
       CASE WHEN d.mtfcc = gp.mtfcc THEN 'correct' ELSE '*** WRONG - COLLISION ***' END AS verdict
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER','COUNTY')
 ORDER BY verdict DESC, d.label;

\echo
\echo == 3. Seats and occupancy, per body ==
\echo ==    Expected: Palm Beach BOCC 7/7, Elected Officials 5/5 (FIVE -- no elected ==
\echo ==              Superintendent, unlike the Leon six), 0 vacant ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id = '12099' AND g.type = 'County'
 GROUP BY g.name, c.name ORDER BY c.name;

\echo
\echo == 3a. Offices per district: exactly 1 on each of the 7, exactly 5 countywide ==
\echo ==     🔴 A commissioner mis-mapped countywide still totals 12 and would appear ==
\echo ==     for EVERY Palm Beach address. This is where that shows up. ==
SELECT d.label, d.geo_id, d.mtfcc, count(o.id) AS offices,
       count(och.politician_id) AS seated,
       CASE WHEN d.mtfcc = 'X0039' AND count(o.id) = 1 THEN 'PASS'
            WHEN d.mtfcc = 'G4020' AND count(o.id) = 5 THEN 'PASS'
            ELSE '*** FAIL ***' END AS status
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id = '12099' AND g.type = 'County'
 GROUP BY d.label, d.geo_id, d.mtfcc
 ORDER BY d.mtfcc, d.geo_id;

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
\echo ==    Expected: 5 officers (not 6); Superintendent/State Attorney/Public Defender ==
\echo ==    ABSENT; 0 unknown-precision; day 2 / month 9 / year 1; 2 appointed; 0 vacant ==
SELECT 'Elected Officials chamber size (charter county, still FIVE)' AS ruling,
       (SELECT official_count::text FROM essentials.chambers c
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND c.name = 'Elected Officials') AS value
UNION ALL
SELECT 'Superintendent of Schools offices (must be 0 -- appointed here, elected in Leon)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND o.title = 'Superintendent of Schools')
UNION ALL
SELECT 'State Attorney + Public Defender offices (must be 0 -- 15th Circuit, not county)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND o.title IN ('State Attorney','Public Defender'))
UNION ALL
SELECT 'unknown-precision or undated terms (must be 0 -- a Florida first)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099'
           AND (t.start_precision = 'unknown' OR t.term_start IS NULL))
UNION ALL
SELECT 'day-precision starts (Sheriff 2005-01-04, Clerk Ad Interim 2026-08-18)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND t.start_precision = 'day')
UNION ALL
SELECT 'month-precision starts (7 commissioners + 2 officers)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND t.start_precision = 'month')
UNION ALL
SELECT 'year-precision starts (Supervisor of Elections, appointed 2019)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND t.start_precision = 'year')
UNION ALL
SELECT 'appointed terms (must be 2 -- a Florida first)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND t.how_started = 'appointed')
UNION ALL
SELECT 'Clerk Ad Interim seated, with the suspension recorded in description',
       (SELECT coalesce(p.full_name, '*** ABSENT ***')
               || CASE WHEN o.description ILIKE '%suspended, not removed%'
                       THEN ' / description OK' ELSE ' / *** DESCRIPTION MISSING ***' END
          FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
          LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
          LEFT JOIN essentials.politicians p ON p.id = och.politician_id
         WHERE g.geo_id = '12099' AND o.title = 'Clerk of the Circuit Court & Comptroller')
UNION ALL
SELECT 'longest tenure (Sheriff Bradshaw, sworn 2005-01-04)',
       (SELECT t.term_start::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND o.title = 'Sheriff')
UNION ALL
SELECT 'commissioner offices on the countywide district (must be 0 -- no at-large seat)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE g.geo_id = '12099' AND c.name = 'Board of County Commissioners'
           AND d.geo_id = '12099' AND d.mtfcc = 'G4020')
UNION ALL
SELECT 'Mack Bernard still holds ONLY SD-24 (he traded seats with Powell)',
       (SELECT string_agg(d.label, ' + ' ORDER BY d.label)
          FROM essentials.politicians p
          JOIN essentials.office_current_holder och ON och.politician_id = p.id
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE p.external_id = -1230024)
UNION ALL
SELECT 'flagged vacant anywhere in this wave (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12099' AND o.is_vacant = true);

\echo
\echo == 6. Negative control: a point in BROWARD County must return NO Palm Beach seat ==
\echo ==    Fort Lauderdale is immediately south across the county line: expect NO ==
\echo ==    Palm Beach commissioner and NO Palm Beach officer. FL-4 used Bradfordville. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.1373, 26.1224), 4326) AS g)
SELECT d.label, gp.mtfcc, o.title, p.full_name AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE g.geo_id = '12099'
 ORDER BY d.label, o.title;

\echo
\echo == 6a. Positive control inside the county but far from the anchor ==
\echo ==     Belle Glade, in the western Glades: expect Commission District 6 ==
\echo ==     (Sara Baxter) plus all 5 officers, and NO District 7. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.6681, 26.6845), 4326) AS g)
SELECT d.label, gp.mtfcc, o.title, p.full_name AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE g.geo_id = '12099'
 ORDER BY d.mtfcc, d.label, o.title;
