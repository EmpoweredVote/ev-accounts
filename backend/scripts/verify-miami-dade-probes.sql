-- verify-miami-dade-probes.sql
--
-- FL-6 acceptance probe: City of Miami + Miami-Dade County. READ-ONLY. Run
-- before and after the apply.
--
-- Wave FL-6 of the Knight Foundation cities program.
-- Plan: docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md
--
-- ---------------------------------------------------------------------------
-- 🔴 TWO ANCHORS, AND PROBE A RETURNS THREE OF FOUR ANSWER CLASSES BY DESIGN.
--
-- Miami City Hall sits inside STATE HOUSE DISTRICT 113, which is VACANT: Vicki
-- Lopez resigned it in November 2025 to take a Miami-Dade Commission seat, and
-- the Supervisor of Elections confirms the seat is filled at the NOVEMBER 2026
-- general rather than by special election. FL-2 predicted this exactly.
--
-- Probe B, at the county Governmental Center, returns all four. Both anchors are
-- here because the vacancy is the truth about City Hall's address, and a single
-- convenient anchor would hide it.
--
-- ⚠ HD-113 returning zero officials is CORRECT DATA, not a defect. It is
-- asserted below as want = 0, so the absence is a checked claim rather than
-- something a reader has to notice.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND MIAMI-DADE IS THE
-- FOURTH FLORIDA COUNTY IN FOUR WAVES TO PROVE IT -- WITH A NEW FAILURE SHAPE.
--
-- 12086 is Miami-Dade County (G4020), State House District 86 (G5220), AND ZIP
-- CODE 12086 IN NEW YORK (G6350). After 12081/HD-81 (Manatee), 12073/HD-73
-- (Leon) and 12099/HD-99 (Palm Beach), this is the first wave where one arm of
-- the collision sits in ANOTHER STATE. 40 of Florida's 67 county geo_ids have a
-- New York ZCTA twin in geofence_boundaries.
--
-- The two failure shapes differ, and query 3 shows BOTH:
--   * a G5220 or G4020 twin returns a WRONG OFFICIAL;
--   * the G6350 twin is a polygon 1,300 miles away, so ST_Covers yields NOTHING
--     and the symptom is a SILENTLY EMPTY result.
--
-- ---------------------------------------------------------------------------
-- ⚠ THIRTEEN SINGLE-MEMBER COUNTY DISTRICTS AND NO AT-LARGE COMMISSIONER, so
-- exactly ONE county commissioner answers at any address, and the countywide
-- district carries SIX offices -- the Mayor, who is not a Board member, plus the
-- five constitutional officers. Palm Beach carries five, Leon eight, Manatee
-- seven. Four counties, four shapes; never inherit the template.
--
-- The City of Miami is the mirror image: five single-member commission districts,
-- and the Mayor is a separate citywide executive, so the citywide district
-- carries exactly ONE office where Tallahassee's carries five.
\pset pager off

\echo
\echo == 1. PROBE A -- Miami City Hall, 3500 Pan American Drive ==
\echo ==    Required: city D2, city Mayor, county D7, 6 countywide, SD-38 ==
\echo ==    and HD-113 EMPTY, because the seat is vacant until November 2026. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.234992579394, 25.728661855119), 4326) AS g)
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
\echo == 1a. PROBE A -- THE DEFINITION OF DONE, asserted as a COUNT per answer. ==
\echo ==     All six must read PASS. Answer 6 passes by being EMPTY. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.234992579394, 25.728661855119), 4326) AS g),
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
-- 🔴 Answer 6 is the vacancy, asserted at ZERO. It is the only row in the slice
--    whose PASS condition is an empty result, and it must never be "fixed".
required(n, what, dt, geo, mt, want) AS (VALUES
  (1, 'city commissioner (District 2)',                   'LOCAL',       'miami-fl-commission-district-2',        'X0041', 1),
  (2, 'city mayor (citywide, NOT a commissioner)',         'LOCAL',       '1245000',                               'G4110', 1),
  (3, 'county commissioner (District 7, single-member)',   'COUNTY',      'miami-dade-fl-commissioner-district-7', 'X0040', 1),
  (4, 'county mayor + 5 constitutional officers',          'COUNTY',      '12086',                                 'G4020', 6),
  (5, 'state senator (SD-38)',                             'STATE_UPPER', '12038',                                 'G5210', 1),
  (6, 'state rep -- HD-113 IS VACANT, must be 0',          'STATE_LOWER', '12113',                                 'G5220', 0)
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
\echo == 2. PROBE B -- Stephen P. Clark Government Center, 111 NW 1st Street ==
\echo ==    The four-answer control: city D5, county D5 (appointed), SD-36, HD-109. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.196332709513, 25.775078850443), 4326) AS g)
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
\echo == 2a. PROBE B -- THE DEFINITION OF DONE. All five must read PASS. ==
\echo ==     Rows 1-4 are the plan four. Row 5 carries the countywide six, which ==
\echo ==     every Miami-Dade address elects and which probe A also asserts. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.196332709513, 25.775078850443), 4326) AS g),
answers AS (
  SELECT d.district_type, d.geo_id, gp.mtfcc, o.title, p.full_name
    FROM pt
    JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
    JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'fl' AND d.representation_basis = 'residency'
)
SELECT r.n, r.what, r.want AS expected,
       count(a.full_name) AS got,
       CASE WHEN count(a.full_name) = r.want THEN 'PASS' ELSE '*** FAIL ***' END AS status,
       coalesce(string_agg(a.full_name, ', ' ORDER BY a.title), '(none)') AS holders
  FROM (VALUES
    (1, 'city commissioner (District 5)',                  'LOCAL',       'miami-fl-commission-district-5',        'X0041', 1),
    (2, 'county commissioner (District 5, APPOINTED)',      'COUNTY',      'miami-dade-fl-commissioner-district-5', 'X0040', 1),
    (3, 'state senator (SD-36)',                            'STATE_UPPER', '12036',                                 'G5210', 1),
    (4, 'state representative (HD-109) -- the control',     'STATE_LOWER', '12109',                                 'G5220', 1),
    (5, 'county mayor + 5 officers (carried, countywide)',  'COUNTY',      '12086',                                 'G4020', 6)
  ) AS r(n, what, dt, geo, mt, want)
  LEFT JOIN answers a
    ON a.district_type = r.dt AND a.geo_id = r.geo AND a.mtfcc = r.mt
 GROUP BY r.n, r.what, r.want
 ORDER BY r.n;

\echo
\echo == 3. What the SAME point returns WITHOUT the mtfcc pairing (the collision) ==
\echo ==    Expected at City Hall: the correct rows, PLUS HD-86 matched via the ==
\echo ==    county G4020 polygon and Miami-Dade County matched via the HD-86 G5220 ==
\echo ==    polygon. Both directions of the wrong-official failure, and nothing errors. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.234992579394, 25.728661855119), 4326) AS g)
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
\echo == 3a. THE ZCTA ARM -- the OTHER failure shape, which returns nothing at all ==
\echo ==     ZIP 12086 is in New York. Expected: the polygon EXISTS, state = 36, ==
\echo ==     and it covers NEITHER anchor. A geo_id join alone would therefore ==
\echo ==     drop the county silently, with no wrong row to notice. ==
WITH a AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.234992579394, 25.728661855119), 4326) AS g),
     b AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.196332709513, 25.775078850443), 4326) AS g)
SELECT gp.geo_id, gp.mtfcc, gp.state AS state_fips,
       public.ST_Covers(gp.geometry, a.g) AS covers_city_hall,
       public.ST_Covers(gp.geometry, b.g) AS covers_govt_center,
       CASE WHEN gp.state = '36'
             AND NOT public.ST_Covers(gp.geometry, a.g)
             AND NOT public.ST_Covers(gp.geometry, b.g)
            THEN 'PASS -- New York, covers neither anchor'
            ELSE '*** FAIL ***' END AS status
  FROM essentials.geofence_boundaries gp, a, b
 WHERE gp.geo_id = '12086' AND gp.mtfcc = 'G6350';

\echo
\echo == 3b. No Florida district may be attached to the New York ZCTA (MUST be 0) ==
SELECT count(*) AS florida_districts_on_zcta_12086,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE '*** FAIL ***' END AS status
  FROM essentials.districts d
 WHERE d.geo_id = '12086' AND d.mtfcc = 'G6350' AND lower(d.state) = 'fl';

\echo
\echo == 4. Seats and occupancy, per body ==
\echo ==    Expected: Miami City Commission 5/5, Office of the Mayor 1/1; ==
\echo ==    Miami-Dade BOCC 13/13, Office of the Mayor 1/1, Elected Officials 5/5; ==
\echo ==    0 flagged vacant anywhere in the wave. ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (g.geo_id = '1245000' AND g.type = 'City')
    OR (g.geo_id = '12086'   AND g.type = 'County')
 GROUP BY g.name, c.name ORDER BY g.name, c.name;

\echo
\echo == 4a. Offices per district: 1 on each single-member seat, 1 citywide, 6 countywide ==
\echo ==     🔴 A commissioner mis-mapped to the countywide district still totals right ==
\echo ==     and would appear for EVERY address in the county. This is where that shows up. ==
SELECT g.name AS government, d.label, d.geo_id, d.mtfcc, count(o.id) AS offices,
       count(och.politician_id) AS seated,
       CASE WHEN d.mtfcc IN ('X0040','X0041') AND count(o.id) = 1 THEN 'PASS'
            WHEN d.mtfcc = 'G4110' AND count(o.id) = 1 THEN 'PASS'
            WHEN d.mtfcc = 'G4020' AND count(o.id) = 6 THEN 'PASS'
            ELSE '*** FAIL ***' END AS status
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (g.geo_id = '1245000' AND g.type = 'City')
    OR (g.geo_id = '12086'   AND g.type = 'County')
 GROUP BY g.name, d.label, d.geo_id, d.mtfcc
 ORDER BY g.name, d.mtfcc, d.geo_id;

\echo
\echo == 5. Every FL local/county office with no term row and no vacancy flag (MUST be 0 rows) ==
\echo ==    An office with no term row is INVISIBLE and nothing errors. This is the one ==
\echo ==    failure mode CI cannot catch. ==
SELECT d.label, o.title, o.is_vacant
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_terms t ON t.office_id = o.id
 WHERE lower(d.state) = 'fl' AND d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY')
   AND t.id IS NULL AND o.is_vacant = false;

\echo
\echo == 6. The rulings and blanks that no count can see ==
\echo ==    Expected: 5 officers sharing 2025-01-07; FOUR appointments, not two; ==
\echo ==    the three forbidden titles at 0; exactly ONE Oliver Gilbert row. ==
SELECT 'constitutional officers sharing term_start 2025-01-07 (must be 5)' AS ruling,
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12086' AND g.type = 'County'
           AND c.name = 'Elected Officials' AND t.term_start = '2025-01-07') AS value
UNION ALL
-- 🔴 FOUR appointed commissioners, not the two this plan first predicted. The
--    count AND the titles are asserted, because a wrong seat would still total 4.
SELECT 'appointed county terms -- MUST be D5, D6, D8, D11 (four, not two)',
       (SELECT coalesce(string_agg(o.title, ' + ' ORDER BY o.title), '(none)')
          FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12086' AND g.type = 'County' AND t.how_started = 'appointed')
UNION ALL
SELECT 'appointed county terms, count (must be 4)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '12086' AND g.type = 'County' AND t.how_started = 'appointed')
UNION ALL
-- The county publishers agree with FL-5: State Attorney and Public Defender are
-- 11th Circuit offices, and the Superintendent is appointed here.
SELECT 'forbidden titles in EITHER government (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE ((g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County'))
           AND o.title IN ('Superintendent of Schools','State Attorney','Public Defender'))
UNION ALL
SELECT 'politician rows named Oliver Gilbert (must be exactly 1 -- the REUSE)',
       (SELECT count(*)::text FROM essentials.politicians WHERE full_name = 'Oliver Gilbert')
UNION ALL
SELECT 'Oliver Gilbert external_id -1212402 now holds (must be county District 1)',
       (SELECT coalesce(string_agg(d.label, ' + ' ORDER BY d.label), '*** NO TERM ***')
          FROM essentials.politicians p
          JOIN essentials.office_current_holder och ON och.politician_id = p.id
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE p.external_id = -1212402)
UNION ALL
SELECT 'unknown-precision or undated terms in the wave (must be 0)',
       (SELECT count(*)::text FROM essentials.office_terms t
          JOIN essentials.offices o ON o.id = t.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE ((g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County'))
           AND (t.start_precision = 'unknown' OR t.term_start IS NULL))
UNION ALL
SELECT 'flagged vacant anywhere in the wave (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE ((g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County'))
           AND o.is_vacant = true)
UNION ALL
SELECT 'city offices where the Mayor is a Commission member (must be 0)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.geo_id = '1245000' AND g.type = 'City'
           AND c.name = 'City Commission' AND o.title = 'Mayor')
UNION ALL
-- ⚠ SCOPED TO THIS WAVE. Unscoped, this reads 33: Leon and Manatee each seat
--    two at-large commissioners on their countywide district and Tallahassee
--    seats five citywide, all of them correct. Neither government in THIS wave
--    has an at-large seat, so here the count must be 0.
SELECT 'commissioner offices on the countywide/citywide district (must be 0 -- no at-large seat in this wave)',
       (SELECT count(*)::text FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE ((g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County'))
           AND c.name IN ('Board of County Commissioners','City Commission')
           AND d.mtfcc IN ('G4020','G4110'));

\echo
\echo == 7. Mixed control: HIALEAH -- inside Miami-Dade, NOT in the City of Miami ==
\echo ==    🔴 THE LOAD-BEARING CONTROL OF THIS WAVE. Expected: ONE county ==
\echo ==    commissioner plus the countywide six, and ZERO City of Miami rows. ==
\echo ==    A city layer that has quietly become a county layer fails only here. ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-80.2781, 25.8576), 4326) AS g),
answers AS (
  SELECT g.geo_id AS gov_geo, g.type AS gov_type, d.label, o.title, p.full_name
    FROM pt
    JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
    JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County')
)
SELECT 'Miami-Dade County offices (expect 7 -- one commissioner + the six)' AS what,
       count(*)::text AS got,
       CASE WHEN count(*) = 7 THEN 'PASS' ELSE '*** FAIL ***' END AS status,
       coalesce(string_agg(full_name, ', ' ORDER BY title), '(none)') AS holders
  FROM answers WHERE gov_geo = '12086'
UNION ALL
SELECT 'City of Miami offices (MUST be 0 -- Hialeah is not in Miami)',
       count(*)::text,
       CASE WHEN count(*) = 0 THEN 'PASS' ELSE '*** FAIL ***' END,
       coalesce(string_agg(full_name, ', ' ORDER BY title), '(none)')
  FROM answers WHERE gov_geo = '1245000';

\echo
\echo == 8. Negative controls: across the county line, north and south-west ==
\echo ==    Fort Lauderdale in Broward and Key West in Monroe. Both must return ==
\echo ==    ZERO rows from either government in this wave. ==
WITH pts(name, g) AS (VALUES
  ('Fort Lauderdale, Broward', public.ST_SetSRID(public.ST_MakePoint(-80.1373, 26.1224), 4326)),
  ('Key West, Monroe',         public.ST_SetSRID(public.ST_MakePoint(-81.7800, 24.5551), 4326))
)
-- ⚠ Every join is a LEFT JOIN and there is NO WHERE clause, so each control
--    point ALWAYS produces exactly one row. A filtered-away point would
--    otherwise vanish from the output and read as silence, not as PASS.
SELECT pts.name,
       count(o.id) FILTER (WHERE g.id IS NOT NULL)::text AS offices_returned,
       CASE WHEN count(o.id) FILTER (WHERE g.id IS NOT NULL) = 0
            THEN 'PASS' ELSE '*** FAIL ***' END AS status,
       coalesce(string_agg(DISTINCT o.title, ', ') FILTER (WHERE g.id IS NOT NULL), '(none)') AS titles
  FROM pts
  LEFT JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pts.g)
  LEFT JOIN essentials.districts d ON d.geo_id = gp.geo_id AND d.mtfcc = gp.mtfcc
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
  LEFT JOIN essentials.governments g
         ON g.id = c.government_id
        AND ((g.geo_id = '1245000' AND g.type = 'City') OR (g.geo_id = '12086' AND g.type = 'County'))
 GROUP BY pts.name
 ORDER BY pts.name;
