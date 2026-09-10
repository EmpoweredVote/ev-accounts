-- verify-fort-wayne-probes.sql
-- Knight Foundation program, wave IN-3 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-fort-wayne-probes.sql
--
-- 🔴 check:reachability takes NO per-jurisdiction probe list, so a green gate means "no district
-- regressed", not "this wave's districts were examined". The acceptance evidence is the probe
-- below plus a per-district positive control across all six council districts.
--
-- ⚠ FORT WAYNE SCORES 3 OF 4, AND THE PROBE ASSERTS THAT RATHER THAN HIDING IT. The four-answer
-- test is council member + county commissioner + state representative + state senator. IN-3 is
-- stage 3; Allen County (stage 4) has not run, so the county slot is asserted at ZERO on purpose
-- -- the FL-5 pattern. A wave that quietly scored 3 of 4 would look identical to one that broke
-- the county tier.

\echo ''
\echo '=== 1. CONTROL ON THE PROBE ITSELF: does the anchor land in Fort Wayne? ==='

SELECT gb.geo_id, gb.name, (gb.geo_id = '1825000') AS anchor_ok
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'G4110' AND gb.state = '18'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326));

\echo ''
\echo '=== 2. THE PROBE: everything Fort Wayne City Hall returns ==='

SELECT d.label AS district, o.title, p.full_name AS holder,
       ot.term_start, ot.start_precision
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d
  ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326))
  AND gb.mtfcc IN ('X0048', 'G4110', 'G5220', 'G5210')
ORDER BY d.district_type, o.title;

\echo ''
\echo '=== 3. GATE ==='

DO $$
DECLARE
  v_place text; v_ward int; v_atlarge int; v_mayor int; v_clerk int;
  v_rep int; v_sen int; v_county int; v_bad int; v_multi int; v_zero int; v_districts int;
BEGIN
  -- 3a. the anchor
  SELECT gb.geo_id INTO v_place FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc='G4110' AND gb.state='18'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326)) LIMIT 1;
  IF v_place IS DISTINCT FROM '1825000' THEN
    RAISE EXCEPTION 'IN-3 probe: the City Hall anchor lands in place %, expected 1825000', coalesce(v_place,'NOTHING');
  END IF;

  -- 3b. what City Hall returns, by tier
  SELECT
    count(*) FILTER (WHERE gb.mtfcc='X0048' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='Council Member, At Large' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='Mayor' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G4110' AND o.title='City Clerk' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G5220' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc='G5210' AND och.politician_id IS NOT NULL)
  INTO v_ward, v_atlarge, v_mayor, v_clerk, v_rep, v_sen
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326))
    AND gb.mtfcc IN ('X0048','G4110','G5220','G5210');

  IF v_ward <> 1 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % district council member(s), expected 1', v_ward; END IF;
  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % at-large member(s), expected 3', v_atlarge; END IF;
  IF v_mayor <> 1 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % mayor(s), expected 1', v_mayor; END IF;
  IF v_clerk <> 1 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % clerk(s), expected 1', v_clerk; END IF;
  IF v_rep <> 1 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % state rep(s), expected 1', v_rep; END IF;
  IF v_sen <> 1 THEN RAISE EXCEPTION 'IN-3 probe: City Hall returns % state senator(s), expected 1', v_sen; END IF;

  -- Allen County (stage 4) has not run. Assert the absence so the day it lands, someone looks.
  SELECT count(*) INTO v_county
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '18003' AND d.district_type = 'COUNTY';
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'IN-3 probe: expected 0 Allen County offices (stage 4 has not run), found %', v_county;
  END IF;

  -- 3c. per-district positive control across all six council districts
  SELECT count(*) INTO v_districts FROM essentials.districts
   WHERE geo_id LIKE 'fort-wayne-in-council-district-%' AND district_type='LOCAL';
  IF v_districts <> 6 THEN RAISE EXCEPTION 'IN-3 probe: % council districts, expected 6', v_districts; END IF;

  SELECT count(*) FILTER (WHERE hits <> 1), count(*) FILTER (WHERE hits > 1), count(*) FILTER (WHERE hits = 0)
  INTO v_bad, v_multi, v_zero
  FROM (
    SELECT d.geo_id,
           (SELECT count(och2.politician_id)
              FROM essentials.geofence_boundaries gb2
              JOIN essentials.districts d2 ON d2.geo_id = gb2.geo_id AND d2.mtfcc = gb2.mtfcc
              JOIN essentials.offices o2 ON o2.district_id = d2.id
              LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = o2.id
             WHERE gb2.mtfcc = 'X0048'
               AND ST_Covers(gb2.geometry, ST_PointOnSurface(gb.geometry))
               AND d2.geo_id = d.geo_id) AS hits
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = 'X0048'
    WHERE d.geo_id LIKE 'fort-wayne-in-council-district-%' AND d.district_type = 'LOCAL'
  ) s;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'IN-3 probe: % of 6 council districts do not resolve to exactly one holder at their own interior point (% several, % none)',
      v_bad, v_multi, v_zero;
  END IF;

  RAISE NOTICE 'IN-3 PROBE PASSED: anchor validated; City Hall returns 1 district member + 3 at-large + mayor + clerk + 1 rep + 1 senator; county asserted at 0; 6/6 districts resolve to exactly one holder';
END $$;
