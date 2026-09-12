-- verify-in-legislature-probes.sql
-- Knight Foundation program, wave IN-2 acceptance evidence. READ-ONLY: no INSERT, UPDATE or
-- DELETE anywhere in this file. Run it after CC_0088 and CC_0089.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-in-legislature-probes.sql
--
-- 🔴 WHY THIS FILE EXISTS AT ALL. `npm run check:reachability` takes NO per-jurisdiction probe
-- list: it sweeps every district of an addressable district_type and reads its MTFCC mapping out
-- of src/lib/geoIdGuard.ts at runtime. So a green reachability gate after a wave means "no
-- district regressed" -- it does NOT prove this wave's own districts were examined. The acceptance
-- evidence is therefore two things, and both are below:
--
--   PROBE   the required answers at a real street address, at TWO anchors; and
--   CONTROL every one of the 150 districts tested at its own interior point, asserting
--           EXACTLY ONE holder -- which is what distinguishes "swept and clean" from "not swept".
--
-- ⚠ INDIANA SCORES 2 OF 4, DELIBERATELY, AND THE PROBE ASSERTS THAT RATHER THAN HIDING IT.
-- The four-answer test is council member + county commissioner + state representative + state
-- senator. IN-2 is stage 2 only: Indiana's stages 3 and 4 have not run, so Fort Wayne and Gary
-- have no city or county seats yet. Section 3 asserts those slots at ZERO on purpose, the same way
-- FL-5 asserted Palm Beach's city slot at zero because it has no city half. A wave that quietly
-- scored 2 of 4 and called it a pass would be indistinguishable from a wave that broke two tiers.

\echo ''
\echo '=== 1. CONTROL ON THE PROBE ITSELF: do the anchor coordinates land where they claim? ==='
-- A probe whose anchor is in the wrong place proves nothing. Each anchor must fall inside its
-- own city's TIGER place polygon before any answer it returns is worth reading.

WITH anchors(label, lon, lat, expect_place) AS (VALUES
  ('Fort Wayne City Hall, 200 E Berry St', -85.13937, 41.07937, '1825000'),
  ('Gary City Hall, 401 Broadway',         -87.33780, 41.60360, '1827000')
)
SELECT a.label,
       gb.geo_id                  AS place_hit,
       gb.name                    AS place_name,
       (gb.geo_id = a.expect_place) AS anchor_ok
FROM anchors a
LEFT JOIN essentials.geofence_boundaries gb
  ON gb.mtfcc = 'G4110' AND gb.state = '18'
 AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
ORDER BY a.label;

\echo ''
\echo '=== 2. THE PROBE: who does each anchor return? ==='
-- Resolution follows the real address path: point -> geofence polygon -> (geo_id, mtfcc) ->
-- district -> office -> current holder. 🔴 geo_id is ALWAYS paired with district_type: Indiana
-- sldl runs 18001..18100 and sldu 18001..18050, so '18046' is House District 46 AND Senate
-- District 46, and a join on geo_id alone fans out.

WITH anchors(label, lon, lat) AS (VALUES
  ('Fort Wayne City Hall, 200 E Berry St', -85.13937, 41.07937),
  ('Gary City Hall, 401 Broadway',         -87.33780, 41.60360)
)
SELECT a.label,
       d.district_type,
       d.label        AS district,
       o.title,
       p.full_name    AS holder,
       ot.start_precision
FROM anchors a
JOIN essentials.geofence_boundaries gb
  ON gb.mtfcc IN ('G5220', 'G5210') AND gb.state = '18'
 AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
JOIN essentials.districts d
  ON d.geo_id = gb.geo_id
 AND d.district_type = CASE gb.mtfcc WHEN 'G5220' THEN 'STATE_LOWER' ELSE 'STATE_UPPER' END
 AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
ORDER BY a.label, d.district_type;

\echo ''
\echo '=== 3. GATE ==='

DO $$
DECLARE
  r            record;
  v_lower      int;
  v_upper      int;
  v_local      int;
  v_districts  int;
  v_bad        int;
  v_multi      int;
  v_zero       int;
BEGIN
  -- ── 3a. Anchor control ────────────────────────────────────────────────────
  FOR r IN
    WITH anchors(label, lon, lat, expect_place) AS (VALUES
      ('Fort Wayne City Hall', -85.13937, 41.07937, '1825000'),
      ('Gary City Hall',       -87.33780, 41.60360, '1827000')
    )
    SELECT a.label, a.expect_place,
           (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='G4110' AND gb.state='18'
               AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
             LIMIT 1) AS hit
    FROM anchors a
  LOOP
    IF r.hit IS DISTINCT FROM r.expect_place THEN
      RAISE EXCEPTION 'IN-2 probe: anchor % lands in place %, expected % -- the coordinate is wrong, so every answer below it is meaningless',
        r.label, coalesce(r.hit,'NOTHING'), r.expect_place;
    END IF;
  END LOOP;

  -- ── 3b. Two of four at each anchor, and the other two asserted at zero ─────
  FOR r IN
    WITH anchors(label, lon, lat) AS (VALUES
      ('Fort Wayne City Hall', -85.13937, 41.07937),
      ('Gary City Hall',       -87.33780, 41.60360)
    )
    SELECT a.label,
           count(*) FILTER (WHERE d.district_type='STATE_LOWER' AND och.politician_id IS NOT NULL) AS lower_held,
           count(*) FILTER (WHERE d.district_type='STATE_UPPER' AND och.politician_id IS NOT NULL) AS upper_held
    FROM anchors a
    JOIN essentials.geofence_boundaries gb
      ON gb.mtfcc IN ('G5220','G5210') AND gb.state='18'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
    JOIN essentials.districts d
      ON d.geo_id = gb.geo_id
     AND d.district_type = CASE gb.mtfcc WHEN 'G5220' THEN 'STATE_LOWER' ELSE 'STATE_UPPER' END
     AND lower(d.state)='in'
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    GROUP BY a.label
  LOOP
    IF r.lower_held <> 1 OR r.upper_held <> 1 THEN
      RAISE EXCEPTION 'IN-2 probe: % returns % representative(s) and % senator(s), expected exactly 1 and 1',
        r.label, r.lower_held, r.upper_held;
    END IF;
  END LOOP;

  -- Stages 3 and 4 have not run for Indiana. Assert the absence rather than ignoring it, so the
  -- day a city wave lands this number is expected to change and someone has to look.
  SELECT count(*) INTO v_local
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in'
    AND d.district_type IN ('CITY_COUNCIL','COUNTY','LOCAL')
    AND d.geo_id IN ('1825000','1827000','18003','18089');
  IF v_local <> 0 THEN
    RAISE EXCEPTION 'IN-2 probe: expected 0 city/county offices for Fort Wayne, Gary, Allen and Lake (stages 3 and 4 have not run), found %', v_local;
  END IF;

  -- ── 3c. Per-district positive control: all 150, each at its own interior point ──
  SELECT count(*) INTO v_districts
  FROM essentials.districts
  WHERE lower(state)='in' AND district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_districts <> 150 THEN
    RAISE EXCEPTION 'IN-2 probe: expected 150 Indiana legislative districts, found %', v_districts;
  END IF;

  -- Every district's own interior point must resolve to exactly one seated holder, and it must be
  -- THAT district. This is what a green check:reachability cannot tell you.
  SELECT
    count(*) FILTER (WHERE hits <> 1),
    count(*) FILTER (WHERE hits > 1),
    count(*) FILTER (WHERE hits = 0)
  INTO v_bad, v_multi, v_zero
  FROM (
    SELECT d.geo_id, d.district_type,
           (SELECT count(och2.politician_id)
              FROM essentials.geofence_boundaries gb2
              JOIN essentials.districts d2
                ON d2.geo_id = gb2.geo_id
               AND d2.district_type = CASE gb2.mtfcc WHEN 'G5220' THEN 'STATE_LOWER' ELSE 'STATE_UPPER' END
               AND lower(d2.state) = 'in'
              JOIN essentials.offices o2 ON o2.district_id = d2.id
              LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = o2.id
             WHERE gb2.mtfcc = gb.mtfcc AND gb2.state = '18'
               AND ST_Covers(gb2.geometry, ST_PointOnSurface(gb.geometry))
               AND d2.geo_id = d.geo_id) AS hits
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb
      ON gb.geo_id = d.geo_id AND gb.state = '18'
     AND gb.mtfcc = CASE d.district_type WHEN 'STATE_LOWER' THEN 'G5220' ELSE 'G5210' END
    WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
  ) s;

  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'IN-2 probe: % of 150 districts do not resolve to exactly one holder at their own interior point (% return several, % return none)',
      v_bad, v_multi, v_zero;
  END IF;

  -- ── 3d. The repair itself ─────────────────────────────────────────────────
  SELECT count(DISTINCT o.chamber_id) INTO v_lower
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state)='in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_lower <> 2 THEN
    RAISE EXCEPTION 'IN-2 probe: Indiana legislative offices span % chambers, expected exactly 2', v_lower;
  END IF;

  SELECT count(*) INTO v_upper FROM essentials.chambers
   WHERE name LIKE 'Indiana House of Representatives - District%'
      OR name LIKE 'Indiana State Senate - District%';
  IF v_upper <> 0 THEN
    RAISE EXCEPTION 'IN-2 probe: % pseudo-chambers survive', v_upper;
  END IF;

  RAISE NOTICE 'IN-2 PROBE PASSED: 2 anchors validated, 2 of 2 state answers at each, city/county asserted at 0, 150/150 districts resolve to exactly one holder, 2 chambers, 0 pseudo-chambers';
END $$;
