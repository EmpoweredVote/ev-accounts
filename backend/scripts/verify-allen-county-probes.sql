-- verify-allen-county-probes.sql
-- Knight Foundation program, wave IN-5 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-allen-county-probes.sql
--
-- 🔴 THE ASSERTION THAT MATTERS MOST IS "THREE, NOT ONE".
-- Indiana elects county commissioners COUNTY-WIDE; the district is a residency rule for the
-- candidate. Every Allen County address must return ALL THREE commissioners. If one ever comes
-- back, somebody has moved them onto the Comm_Dist polygons, which is the failure this wave was
-- built to avoid.
--
-- The county council is the opposite: its four district members must return exactly ONE each at
-- their own interior points, and its three at-large members must return three everywhere.

\echo ''
\echo '=== 1. What a Fort Wayne address returns from the COUNTY tier ==='

SELECT c.name AS chamber, o.title, p.full_name AS holder, ot.start_precision
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
WHERE g.name = 'Allen County, Indiana, US'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326))
ORDER BY c.name, o.title;

\echo ''
\echo '=== 2. GATE ==='

DO $$
DECLARE
  v_comm int; v_cncl_d int; v_cncl_al int; v_officers int;
  v_bad int; v_multi int; v_zero int; v_seatedcomm int;
BEGIN
  -- 2a. At a real Fort Wayne address: 3 commissioners, 1 council district member, 3 at-large,
  --     9 officers. Sixteen county answers in total.
  SELECT
    count(*) FILTER (WHERE c.name = 'Board of County Commissioners' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE gb.mtfcc = 'X0049' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE o.title = 'Council Member, At Large' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE c.name = 'Elected Officials' AND och.politician_id IS NOT NULL)
  INTO v_comm, v_cncl_d, v_cncl_al, v_officers
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name = 'Allen County, Indiana, US'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13937, 41.07937), 4326));

  IF v_comm <> 3 THEN
    RAISE EXCEPTION 'IN-5 probe: a Fort Wayne address returns % commissioner(s), expected 3 -- Indiana elects all three county-wide', v_comm;
  END IF;
  IF v_cncl_d <> 1 THEN
    RAISE EXCEPTION 'IN-5 probe: a Fort Wayne address returns % county council DISTRICT member(s), expected 1', v_cncl_d;
  END IF;
  IF v_cncl_al <> 3 THEN
    RAISE EXCEPTION 'IN-5 probe: a Fort Wayne address returns % county council at-large member(s), expected 3', v_cncl_al;
  END IF;
  IF v_officers <> 9 THEN
    RAISE EXCEPTION 'IN-5 probe: a Fort Wayne address returns % county officer(s), expected 9', v_officers;
  END IF;

  -- 2b. Per-district positive control on the four council districts.
  SELECT count(*) FILTER (WHERE hits <> 1), count(*) FILTER (WHERE hits > 1), count(*) FILTER (WHERE hits = 0)
  INTO v_bad, v_multi, v_zero
  FROM (
    SELECT d.geo_id,
           (SELECT count(och2.politician_id)
              FROM essentials.geofence_boundaries gb2
              JOIN essentials.districts d2 ON d2.geo_id = gb2.geo_id AND d2.mtfcc = gb2.mtfcc
              JOIN essentials.offices o2 ON o2.district_id = d2.id
              LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = o2.id
             WHERE gb2.mtfcc = 'X0049'
               AND ST_Covers(gb2.geometry, ST_PointOnSurface(gb.geometry))
               AND d2.geo_id = d.geo_id) AS hits
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = 'X0049'
    WHERE d.geo_id LIKE 'allen-county-in-council-district-%' AND d.district_type = 'COUNTY'
  ) s;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'IN-5 probe: % of 4 county council districts do not resolve to exactly one holder (% several, % none)', v_bad, v_multi, v_zero;
  END IF;

  -- 2c. All three commissioners are seated and countywide.
  SELECT count(*) INTO v_seatedcomm
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name = 'Allen County, Indiana, US' AND c.name = 'Board of County Commissioners'
    AND d.geo_id = '18003' AND och.politician_id IS NOT NULL;
  IF v_seatedcomm <> 3 THEN
    RAISE EXCEPTION 'IN-5 probe: % commissioner office(s) are seated on the county polygon, expected 3', v_seatedcomm;
  END IF;

  RAISE NOTICE 'IN-5 PROBE PASSED: a Fort Wayne address returns 3 commissioners + 1 council district member + 3 at-large + 9 officers; 4/4 council districts resolve to exactly one holder';
END $$;
