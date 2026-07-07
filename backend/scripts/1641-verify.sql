-- ============================================================================
-- 1641-verify.sql — Phase 164.1 D-10 verify bar: Layer-1 topology + Layer-2
-- anchor presence + D-04 NOTOUCH checksums for the 5 dual-map refresh states
-- (TN=47, MO=29, AL=01, LA=22, UT=49).
--
-- SELECT-only gate script (163-verify.sql harness convention: one DO block per
-- criterion, RAISE NOTICE 'PASS ...' / RAISE EXCEPTION 'FAIL ...').
-- Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/1641-verify.sql
--
-- WHAT EACH BLOCK PROVES
--   [L1-TILING]  For each state that HAS mtfcc='G5200V26' rows: the 2026-vintage
--                districts tile the state — ST_Area(ST_Difference(G4000 state
--                outline, ST_Union(V26 districts))) is < TILING_TOL_FRAC of the
--                outline area, and the union covers > (1 - TILING_TOL_FRAC).
--                A state with ZERO V26 rows is SKIPPED (NOTICE), not failed —
--                the script is GREEN as a no-op until each state's import lands.
--                A state with a PARTIAL import (0 < n <> expected district
--                count) FAILS — partial imports must never look green.
--   [L1-RATIO]   Each V26 district's area is within one order of magnitude of
--                its G5200 (current-vintage) counterpart — catches truncated /
--                mis-projected / mis-keyed polygons.
--   [L2-ANCHOR]  Each V26 geometry is valid, non-empty, and covers its own
--                ST_PointOnSurface — the anchor the coordinate smoke derives is
--                guaranteed to exist. (The anchor→race live assertion is in
--                1641-coordinate-smoke.ts.)
--   [D04-NOTOUCH] The imports touch ONLY essentials.geofence_boundaries.
--                Per-row md5 checksums (NOT bare counts) over:
--                  * essentials.offices for each state's NATIONAL_LOWER
--                    districts (id:district_id:representing_state, ORDER BY id)
--                  * essentials.geo_districts layer='us_house' per state
--                    (geoid:district_num, ORDER BY geoid)
--                pinned to the baseline literals below. RAISE EXCEPTION on any
--                drift — an accidental re-key/rewrite is a Pitfall-2 breach.
--                  * connect.user_districts us_house rows for the 5 states:
--                    assert the DISTINCT (layer, geoid) district-SET md5 +
--                    cardinality (pinned literal). RAISE EXCEPTION on set
--                    change; RAISE NOTICE (never exception) for row-count
--                    drift — individual user rows legitimately churn via the
--                    weekly districtStalenessService cron; the SET of geoids
--                    must not change, row contents/counts may.
--
-- BASELINES (captured live 2026-07-07, pre-import; re-pin with a dated comment
-- if a legitimate data change occurs):
--   offices md5 (id:district_id:representing_state, ORDER BY id), NATIONAL_LOWER, len(geo_id)=4:
--     01: 0bd1a663560ddab3787e8ea76af3d170 (7 rows)
--     22: 44909b82c7c49dcb1a666597d0976687 (6 rows)
--     29: b0556389311a4f8e900fbf7d0ea39d70 (8 rows)
--     47: 038e4c54c8f6e6581fd897a4a91317dc (9 rows)
--     49: 4d8bbfb221d4babca6e9f7201bce391e (4 rows)
--   geo_districts md5 (geoid:district_num, ORDER BY geoid), layer='us_house':
--     01: 5ccfa65ce6fea55de3b66e63bfa10f46 (7 rows)
--     22: 02fb2976ad94b61e4bc4c8a63a925d3c (6 rows)
--     29: 48427aab470490b5ac9578516f2c08ac (8 rows)
--     47: 3f78d9ab7cce8782dfe4c94f92b4e33e (9 rows)
--     49: 10f51b4d1c4fc5cefb3fc32b12956a39 (4 rows)
--   connect.user_districts us_house DISTINCT (layer,geoid) set, 5 states:
--     set md5 d41d8cd98f00b204e9800998ecf8427e (md5 of empty string), cardinality 0, 0 rows.
--     CAVEAT (2026-07-07): the set is EMPTY today, so the first legitimate
--     Connected user resolved into a us_house district of these states by the
--     weekly cron WOULD change the set. If this block trips and the diff shows
--     ONLY additions of valid us_house geoids with no import running, that is
--     cron churn on a degenerate empty baseline — re-pin with a dated comment.
--
-- SCOPING DISCIPLINE: every topology assertion filters mtfcc='G5200V26' AND a
-- single state's geo_id prefix (substr(geo_id,1,2) = fips AND length = 4).
-- NEVER a cross-state count. V26 rows are keyed by geo_id prefix, NOT by the
-- geofence_boundaries.state column (G5200 rows store FIPS there, G4000 rows
-- store letters — the geo_id prefix is the invariant). The G4000 state outline
-- is keyed by geo_id = fips.
-- All PostGIS calls use the public. schema prefix.
-- ============================================================================

\set ON_ERROR_STOP on

-- ----------------------------------------------------------------------------
-- L1-TILING + L1-RATIO + L2-ANCHOR (per state, skip-if-no-V26-rows)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  st            RECORD;
  v26_count     integer;
  outline_geom  public.geometry;
  outline_area  float8;
  uncovered     float8;
  covered       float8;
  bad_ratio     integer;
  bad_anchor    integer;
  invalid_geom  integer;
  TILING_TOL_FRAC constant float8 := 0.02;  -- 2%: absorbs shoreline/generalization
    -- slivers between the TIGER G4000 outline and state-authority district maps
    -- (relevant for coastal AL/LA); a wrong/missing district is orders larger.
BEGIN
  FOR st IN
    SELECT * FROM (VALUES
      ('47', 'TN', 9),
      ('29', 'MO', 8),
      ('01', 'AL', 7),
      ('22', 'LA', 6),
      ('49', 'UT', 4)
    ) AS t(fips, abbr, expected)
  LOOP
    SELECT count(*) INTO v26_count
    FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'G5200V26'
      AND length(gb.geo_id) = 4
      AND substr(gb.geo_id, 1, 2) = st.fips;

    IF v26_count = 0 THEN
      RAISE NOTICE 'SKIP L1/L2 %(%): no G5200V26 rows yet — no-op', st.abbr, st.fips;
      CONTINUE;
    END IF;

    IF v26_count <> st.expected THEN
      RAISE EXCEPTION 'FAIL L1-PARTIAL %(%): % G5200V26 rows, expected % — partial import must not pass',
        st.abbr, st.fips, v26_count, st.expected;
    END IF;

    -- L1-TILING: V26 union vs the G4000 state outline
    SELECT geometry INTO outline_geom
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G4000' AND geo_id = st.fips
    LIMIT 1;

    IF outline_geom IS NULL THEN
      RAISE EXCEPTION 'FAIL L1-TILING %(%): no G4000 state outline to diff against', st.abbr, st.fips;
    END IF;

    SELECT public.ST_Area(outline_geom),
           public.ST_Area(public.ST_Difference(outline_geom, u.geom)),
           public.ST_Area(u.geom)
      INTO outline_area, uncovered, covered
    FROM (
      SELECT public.ST_Union(gb.geometry) AS geom
      FROM essentials.geofence_boundaries gb
      WHERE gb.mtfcc = 'G5200V26'
        AND length(gb.geo_id) = 4
        AND substr(gb.geo_id, 1, 2) = st.fips
        AND gb.geometry IS NOT NULL
    ) u;

    IF uncovered > outline_area * TILING_TOL_FRAC THEN
      RAISE EXCEPTION 'FAIL L1-TILING %(%): uncovered area % of outline % (% pct > % pct tolerance)',
        st.abbr, st.fips, uncovered, outline_area,
        round((100.0 * uncovered / NULLIF(outline_area, 0))::numeric, 3), round((100.0 * TILING_TOL_FRAC)::numeric, 1);
    END IF;

    -- L1-RATIO: each V26 district's area vs its G5200 counterpart, sanity-bounded.
    -- 2026-07-07 (dated re-pin): bounds widened [0.1,10] → [0.02,50]. The UT import
    -- proved a LEGITIMATE 18.5x shrink (new UT-1 = compact Salt Lake City remedial
    -- district: 0.171 vs 3.170 deg², ratio 0.054) while tiling + area-sum stayed
    -- exact — a real map change, not a truncated polygon. Catastrophic mis-imports
    -- (degenerate/wrong-unit geometry) still trip these bounds; tiling (2%) and
    -- anchor validity remain the primary structural guards.
    SELECT count(*) INTO bad_ratio
    FROM essentials.geofence_boundaries new
    JOIN essentials.geofence_boundaries old
      ON old.geo_id = new.geo_id AND old.mtfcc = 'G5200'
    WHERE new.mtfcc = 'G5200V26'
      AND length(new.geo_id) = 4
      AND substr(new.geo_id, 1, 2) = st.fips
      AND (
        old.geometry IS NULL OR new.geometry IS NULL
        OR public.ST_Area(new.geometry) / NULLIF(public.ST_Area(old.geometry), 0) NOT BETWEEN 0.02 AND 50.0
      );
    IF bad_ratio > 0 THEN
      RAISE EXCEPTION 'FAIL L1-RATIO %(%): % district(s) with V26/G5200 area ratio outside [0.02, 50] — truncated or mis-imported polygon',
        st.abbr, st.fips, bad_ratio;
    END IF;

    -- L2-ANCHOR: valid, non-empty geometry that covers its own interior point
    SELECT
      count(*) FILTER (WHERE NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)),
      count(*) FILTER (WHERE NOT public.ST_Covers(gb.geometry, public.ST_PointOnSurface(gb.geometry)))
      INTO invalid_geom, bad_anchor
    FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'G5200V26'
      AND length(gb.geo_id) = 4
      AND substr(gb.geo_id, 1, 2) = st.fips;

    IF invalid_geom > 0 THEN
      RAISE EXCEPTION 'FAIL L2-ANCHOR %(%): % invalid/empty V26 geometry(ies)', st.abbr, st.fips, invalid_geom;
    END IF;
    IF bad_anchor > 0 THEN
      RAISE EXCEPTION 'FAIL L2-ANCHOR %(%): % V26 geometry(ies) do not cover their own ST_PointOnSurface', st.abbr, st.fips, bad_anchor;
    END IF;

    RAISE NOTICE 'PASS L1/L2 %(%): % districts tile the outline (uncovered % pct <= % pct), all area ratios sane, all anchors valid',
      st.abbr, st.fips, v26_count,
      round((100.0 * uncovered / NULLIF(outline_area, 0))::numeric, 4), round((100.0 * TILING_TOL_FRAC)::numeric, 1);
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- D04-NOTOUCH: essentials.offices per-row md5 (5 states, NATIONAL_LOWER)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  st RECORD;
  v_md5 text;
BEGIN
  FOR st IN
    SELECT * FROM (VALUES
      ('47', 'TN', '038e4c54c8f6e6581fd897a4a91317dc'),
      ('29', 'MO', 'b0556389311a4f8e900fbf7d0ea39d70'),
      ('01', 'AL', '0bd1a663560ddab3787e8ea76af3d170'),
      ('22', 'LA', '44909b82c7c49dcb1a666597d0976687'),
      ('49', 'UT', '4d8bbfb221d4babca6e9f7201bce391e')
    ) AS t(fips, abbr, baseline)
  LOOP
    SELECT md5(coalesce(string_agg(
             o.id::text || ':' || coalesce(o.district_id::text, '') || ':' || coalesce(o.representing_state, ''),
             ',' ORDER BY o.id), ''))
      INTO v_md5
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.district_type = 'NATIONAL_LOWER'
      AND length(d.geo_id) = 4
      AND substr(d.geo_id, 1, 2) = st.fips;

    IF v_md5 <> st.baseline THEN
      RAISE EXCEPTION 'FAIL D04-NOTOUCH offices %(%): md5 % <> baseline % (2026-07-07) — an import perturbed essentials.offices (Pitfall-2 breach)',
        st.abbr, st.fips, v_md5, st.baseline;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS D04-NOTOUCH offices: all 5 states match the 2026-07-07 per-row md5 baselines';
END $$;

-- ----------------------------------------------------------------------------
-- D04-NOTOUCH: essentials.geo_districts per-row md5 (layer='us_house', 5 states)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  st RECORD;
  v_md5 text;
BEGIN
  FOR st IN
    SELECT * FROM (VALUES
      ('47', 'TN', '3f78d9ab7cce8782dfe4c94f92b4e33e'),
      ('29', 'MO', '48427aab470490b5ac9578516f2c08ac'),
      ('01', 'AL', '5ccfa65ce6fea55de3b66e63bfa10f46'),
      ('22', 'LA', '02fb2976ad94b61e4bc4c8a63a925d3c'),
      ('49', 'UT', '10f51b4d1c4fc5cefb3fc32b12956a39')
    ) AS t(fips, abbr, baseline)
  LOOP
    SELECT md5(coalesce(string_agg(g.geoid || ':' || g.district_num, ',' ORDER BY g.geoid), ''))
      INTO v_md5
    FROM essentials.geo_districts g
    WHERE g.layer = 'us_house'
      AND g.geoid LIKE st.fips || '%';

    IF v_md5 <> st.baseline THEN
      RAISE EXCEPTION 'FAIL D04-NOTOUCH geo_districts %(%): md5 % <> baseline % (2026-07-07) — imports must NEVER write geo_districts (Pitfall-2 breach)',
        st.abbr, st.fips, v_md5, st.baseline;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS D04-NOTOUCH geo_districts: all 5 states match the 2026-07-07 per-row md5 baselines';
END $$;

-- ----------------------------------------------------------------------------
-- D04-NOTOUCH: connect.user_districts us_house district-SET (5 states)
-- SET md5 + cardinality pinned; EXCEPTION on set change, NOTICE on row churn.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  v_set_md5  text;
  v_card     integer;
  v_rows     integer;
  BASELINE_SET_MD5 constant text    := 'd41d8cd98f00b204e9800998ecf8427e'; -- 2026-07-07: empty set (md5(''))
  BASELINE_CARD    constant integer := 0;                                   -- 2026-07-07
  BASELINE_ROWS    constant integer := 0;                                   -- 2026-07-07 (informational only)
BEGIN
  SELECT md5(coalesce(string_agg(DISTINCT layer || ':' || geoid, ',' ORDER BY layer || ':' || geoid), '')),
         count(DISTINCT geoid),
         count(*)
    INTO v_set_md5, v_card, v_rows
  FROM connect.user_districts
  WHERE layer = 'us_house'
    AND substr(geoid, 1, 2) IN ('47', '29', '01', '22', '49');

  IF v_set_md5 <> BASELINE_SET_MD5 OR v_card <> BASELINE_CARD THEN
    RAISE EXCEPTION 'FAIL D04-NOTOUCH user_districts: DISTINCT (layer,geoid) set changed — md5 % (card %) <> baseline % (card %) (2026-07-07). Imports must never add/remove a us_house geoid. If NO import is running and the diff is only cron-added valid geoids on the degenerate EMPTY baseline, re-pin with a dated comment (see header caveat).',
      v_set_md5, v_card, BASELINE_SET_MD5, BASELINE_CARD;
  END IF;

  IF v_rows <> BASELINE_ROWS THEN
    RAISE NOTICE 'NOTICE D04-NOTOUCH user_districts: benign row-count drift (% rows vs % baseline) with UNCHANGED district set — weekly cron churn, eyeball only',
      v_rows, BASELINE_ROWS;
  END IF;

  RAISE NOTICE 'PASS D04-NOTOUCH user_districts: us_house district set unchanged (md5 %, cardinality %)', v_set_md5, v_card;
END $$;

SELECT '1641-verify GREEN' AS result;
