-- verify-gary-probes.sql
-- Knight Foundation program, wave IN-4 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-gary-probes.sql
--
-- ⚠ GARY SCORES 3 OF 4 AT CITY HALL (was 2 of 4 before IN-6), AND THE PROBE ASSERTS EXACTLY THAT.
-- The four-answer test is council member + county commissioner + state representative + state
-- senator. Gary returns the state rep, the state senator and -- since IN-6 -- ALL THREE Lake
-- County commissioners, plus its Mayor, Clerk, City Judge and three at-large council members.
--
-- The missing answer is the DISTRICT council member, and it is missing TWICE over:
--   * Gary's six CITY council district seats are deferred (the 2023 settlement map is PDF-only;
--     the City's own GeoJSON repo is the 2014 map). See ROSTERS.md.
--   * Lake County's seven COUNCIL district seats are deferred for the same reason -- Lake
--     publishes every map as PDF and its open-data org carries no electoral layer.
--
-- Both deferrals are asserted at ZERO on purpose. A wave that quietly scored 3 of 4 would be
-- indistinguishable from one that broke a tier.

\echo ''
\echo '=== 1. CONTROL ON THE PROBE ITSELF: does the anchor land in Gary? ==='

SELECT gb.geo_id, gb.name, (gb.geo_id = '1827000') AS anchor_ok
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'G4110' AND gb.state = '18'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326));

\echo ''
\echo '=== 2. THE PROBE: everything Gary City Hall returns ==='

SELECT d.label AS district, o.title, p.full_name AS holder, ot.term_start, ot.start_precision
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326))
  AND gb.mtfcc IN ('G4110', 'G5220', 'G5210')
ORDER BY d.district_type, o.title, p.full_name;

\echo ''
\echo '=== 3. GATE ==='

DO $$
DECLARE
  v_place text; v_atlarge int; v_mayor int; v_clerk int; v_judge int;
  v_rep int; v_sen int; v_countyoff int; v_countycomm int; v_lakecouncil int; v_districtseats int; v_spencer_offices int; v_spencer_gary int;
BEGIN
  SELECT gb.geo_id INTO v_place FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc='G4110' AND gb.state='18'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326)) LIMIT 1;
  IF v_place IS DISTINCT FROM '1827000' THEN
    RAISE EXCEPTION 'IN-4 probe: the City Hall anchor lands in place %, expected 1827000', coalesce(v_place,'NOTHING');
  END IF;

  SELECT
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='Council Member, At Large' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='Mayor' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='City Clerk' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='Judge of the City Court' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G5220' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G5210' AND och.politician_id IS NOT NULL)
  INTO v_atlarge, v_mayor, v_clerk, v_judge, v_rep, v_sen
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326))
    AND gb.mtfcc IN ('G4110','G5220','G5210');

  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % at-large member(s), expected 3', v_atlarge; END IF;
  IF v_mayor <> 1 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % mayor(s), expected 1', v_mayor; END IF;
  IF v_clerk <> 1 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % clerk(s), expected 1', v_clerk; END IF;
  IF v_judge <> 1 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % city judge(s), expected 1 -- Gary elects one and Fort Wayne does not', v_judge; END IF;
  IF v_rep <> 1 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % state rep(s), expected 1', v_rep; END IF;
  IF v_sen <> 1 THEN RAISE EXCEPTION 'IN-4 probe: City Hall returns % state senator(s), expected 1', v_sen; END IF;

  -- The two DELIBERATE absences.
  SELECT count(*) INTO v_districtseats FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_districtseats <> 0 THEN
    RAISE EXCEPTION 'IN-4 probe: % Gary district council office(s) exist; they are deferred until the 2023 settlement map is obtained', v_districtseats;
  END IF;

  -- 🟢 UPDATED 2026-09-10 BY IN-6. This read "expected 0 Lake County offices (stage 4 has not
  -- run)" and FIRED the moment CC_0095 applied, reporting 12 -- which is what asserting an
  -- absence is for. Lake now carries 12 countywide offices: 3 commissioners + 9 officers.
  -- ⚠ Its SEVEN council district seats remain deferred for want of geometry, so Gary still does
  -- not get a county council answer, and that absence is asserted separately below.
  SELECT count(*) INTO v_countyoff FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '18089' AND d.district_type = 'COUNTY';
  IF v_countyoff <> 12 THEN
    RAISE EXCEPTION 'IN-4 probe: expected 12 countywide Lake County offices, found %', v_countyoff;
  END IF;

  -- 🔴 All THREE commissioners must reach a Gary address -- Indiana elects them county-wide.
  SELECT count(och.politician_id) INTO v_countycomm
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE gb.mtfcc = 'G4020' AND gb.state = '18'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326))
    AND c.name = 'Board of Commissioners';
  IF v_countycomm <> 3 THEN
    RAISE EXCEPTION 'IN-4 probe: Gary City Hall returns % county commissioner(s), expected 3', v_countycomm;
  END IF;

  -- The seven Lake County Council district seats are still deferred.
  SELECT count(*) INTO v_lakecouncil FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_lakecouncil <> 0 THEN
    RAISE EXCEPTION 'IN-4 probe: % Lake County Council office(s) exist; all seven are deferred until district geometry is obtained', v_lakecouncil;
  END IF;

  -- 🔴 Mark Spencer left Gary's at-large seat for SD-3. He must hold exactly ONE office, and it
  -- must not be a Gary one. This is NOT vacuous: it reads his real seat count.
  SELECT count(*) INTO v_spencer_offices
  FROM essentials.office_current_holder och
  JOIN essentials.politicians p ON p.id = och.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(p.last_name)='spencer' AND lower(p.first_name)='mark'
    AND lower(d.state) IN ('in','IN') AND d.district_type = 'STATE_UPPER';
  IF v_spencer_offices <> 1 THEN
    RAISE EXCEPTION 'IN-4 probe: Mark Spencer holds % Indiana STATE_UPPER seat(s), expected exactly 1 (SD-3, seated by CC_0089)', v_spencer_offices;
  END IF;

  SELECT count(*) INTO v_spencer_gary
  FROM essentials.office_current_holder och
  JOIN essentials.politicians p ON p.id = och.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Gary, Indiana, US'
    AND lower(p.last_name)='spencer' AND lower(p.first_name)='mark';
  IF v_spencer_gary <> 0 THEN
    RAISE EXCEPTION 'IN-4 probe: Mark Spencer holds a Gary office as well as SD-3 -- the same man on two live seats';
  END IF;

  RAISE NOTICE 'IN-4 PROBE PASSED: anchor validated; City Hall returns mayor + clerk + CITY JUDGE + 3 at-large + 1 rep + 1 senator; district seats deferred; Lake County 12 countywide incl 3 commissioners; Mark Spencer holds SD-3 only';
END $$;
