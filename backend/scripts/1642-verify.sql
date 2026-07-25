-- ============================================================================
-- 1642-verify.sql — Phase 164.2 D-10 verify bar: Layer-1 topology + Layer-2
-- anchor presence + D-04 NOTOUCH checksums for the 5 enacted-2026 backfill states
-- (FL=12, CA=06, NC=37, OH=39, TX=48).
--
-- Clone of scripts/1641-verify.sql retargeted to FIPS 12/06/37/39/48. SELECT-only
-- gate; one DO block per criterion, RAISE NOTICE 'PASS ...' / RAISE EXCEPTION 'FAIL ...'.
-- Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/1642-verify.sql
--
-- WHAT EACH BLOCK PROVES
--   [L1-TILING]  For each state that HAS mtfcc='G5200V26' rows: the 2026-vintage
--                districts tile the state — uncovered area < TILING_TOL_FRAC of the
--                G4000 outline. Zero V26 rows = SKIP (NOTICE), GREEN no-op until
--                each import lands. PARTIAL import (0 < n <> expected) = hard FAIL.
--   [L1-RATIO]   Each V26 district's area within [0.02, 50]x its G5200 counterpart —
--                catches truncated / mis-projected / mis-keyed polygons.
--   [L2-ANCHOR]  Each V26 geometry valid, non-empty, and covers its own
--                ST_PointOnSurface (the anchor the coordinate smoke derives).
--   [D04-NOTOUCH] The imports touch ONLY essentials.geofence_boundaries. Per-row
--                md5 checksums over essentials.offices (NATIONAL_LOWER) and
--                essentials.geo_districts (layer='us_house'), plus the
--                connect.user_districts us_house DISTINCT (layer,geoid) SET md5 +
--                cardinality, pinned to the baselines below. EXCEPTION on drift.
--
-- BASELINES (captured live 2026-07-22, PRE-import; re-pin with a dated comment
-- if a legitimate data change occurs):
--   offices md5 (id:district_id:representing_state, ORDER BY id), NATIONAL_LOWER, len(geo_id)=4:
--     12 FL: 0e634c33c1a7f20e4960d8ff4f0ee3f9 (28 rows)
--     06 CA: e209e214e319d3b521288c40abbf7cf6 (52 rows)
--     37 NC: a2d4698c5d36a537ead7e7ea1ada6ab5 (14 rows)
--     39 OH: 35b8c30e77ab3af564e738450644b7db (15 rows)
--     48 TX: 6c538916cb1302274b7b764effbcd845 (38 rows)
--   geo_districts md5 (geoid:district_num, ORDER BY geoid), layer='us_house':
--     12 FL: 77873331d627a82d14490d1a3a04a9da (28 rows)
--     06 CA: d4c1655a4f36f885bfcb33026923d99a (52 rows)
--     37 NC: 631d4f6f5abd7a3997a3027b7b5b2e10 (14 rows)
--     39 OH: cdf81c0a6f3ccf906f93f9099cd3d0fb (15 rows)
--     48 TX: 92d80e694080cc050f77a7d40db3f0eb (38 rows)
--   connect.user_districts us_house DISTINCT (layer,geoid) set, 5 states:
--     set md5 f8f381c5216c5f9aa3b18f89ce88af47, cardinality 1, 1 row.
--     CAVEAT (2026-07-22): the set is small (1 geoid). The weekly
--     districtStalenessService cron can add/remove user rows; the DISTINCT
--     (layer,geoid) SET must not change under an IMPORT. If this block trips and
--     the diff shows only cron churn (valid us_house geoids of these states) with
--     NO import running, re-pin with a dated comment.
--
-- SCOPING DISCIPLINE: every topology assertion filters mtfcc='G5200V26' AND a
-- single state's geo_id prefix (substr(geo_id,1,2)=fips AND length=4). NEVER a
-- cross-state count. V26 rows are keyed by geo_id prefix, NOT the state column.
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
    -- (relevant for coastal FL/NC/TX); a wrong/missing district is orders larger.
BEGIN
  FOR st IN
    SELECT * FROM (VALUES
      ('12', 'FL', 28),
      ('06', 'CA', 52),
      ('37', 'NC', 14),
      ('39', 'OH', 15),
      ('48', 'TX', 38)
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

    -- L1-RATIO: each V26 district's area vs its G5200 counterpart, sanity-bounded [0.02,50].
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
      ('12', 'FL', '0e634c33c1a7f20e4960d8ff4f0ee3f9'),
      ('06', 'CA', 'e209e214e319d3b521288c40abbf7cf6'),
      ('37', 'NC', 'a2d4698c5d36a537ead7e7ea1ada6ab5'),
      ('39', 'OH', '35b8c30e77ab3af564e738450644b7db'),
      ('48', 'TX', '6c538916cb1302274b7b764effbcd845')
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
      RAISE EXCEPTION 'FAIL D04-NOTOUCH offices %(%): md5 % <> baseline % (2026-07-22) — an import perturbed essentials.offices (Pitfall-2 breach)',
        st.abbr, st.fips, v_md5, st.baseline;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS D04-NOTOUCH offices: all 5 states match the 2026-07-22 per-row md5 baselines';
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
      ('12', 'FL', '77873331d627a82d14490d1a3a04a9da'),
      ('06', 'CA', 'd4c1655a4f36f885bfcb33026923d99a'),
      ('37', 'NC', '631d4f6f5abd7a3997a3027b7b5b2e10'),
      ('39', 'OH', 'cdf81c0a6f3ccf906f93f9099cd3d0fb'),
      ('48', 'TX', '92d80e694080cc050f77a7d40db3f0eb')
    ) AS t(fips, abbr, baseline)
  LOOP
    SELECT md5(coalesce(string_agg(g.geoid || ':' || g.district_num, ',' ORDER BY g.geoid), ''))
      INTO v_md5
    FROM essentials.geo_districts g
    WHERE g.layer = 'us_house'
      AND g.geoid LIKE st.fips || '%';

    IF v_md5 <> st.baseline THEN
      RAISE EXCEPTION 'FAIL D04-NOTOUCH geo_districts %(%): md5 % <> baseline % (2026-07-22) — imports must NEVER write geo_districts (Pitfall-2 breach)',
        st.abbr, st.fips, v_md5, st.baseline;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS D04-NOTOUCH geo_districts: all 5 states match the 2026-07-22 per-row md5 baselines';
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
  BASELINE_SET_MD5 constant text    := 'f8f381c5216c5f9aa3b18f89ce88af47'; -- 2026-07-22
  BASELINE_CARD    constant integer := 1;                                   -- 2026-07-22
  BASELINE_ROWS    constant integer := 1;                                   -- 2026-07-22 (informational only)
BEGIN
  SELECT md5(coalesce(string_agg(DISTINCT layer || ':' || geoid, ',' ORDER BY layer || ':' || geoid), '')),
         count(DISTINCT geoid),
         count(*)
    INTO v_set_md5, v_card, v_rows
  FROM connect.user_districts
  WHERE layer = 'us_house'
    AND substr(geoid, 1, 2) IN ('12', '06', '37', '39', '48');

  IF v_set_md5 <> BASELINE_SET_MD5 OR v_card <> BASELINE_CARD THEN
    RAISE EXCEPTION 'FAIL D04-NOTOUCH user_districts: DISTINCT (layer,geoid) set changed — md5 % (card %) <> baseline % (card %) (2026-07-22). Imports must never add/remove a us_house geoid. If NO import is running and the diff is only cron churn on valid geoids, re-pin with a dated comment (see header caveat).',
      v_set_md5, v_card, BASELINE_SET_MD5, BASELINE_CARD;
  END IF;

  IF v_rows <> BASELINE_ROWS THEN
    RAISE NOTICE 'NOTICE D04-NOTOUCH user_districts: benign row-count drift (% rows vs % baseline) with UNCHANGED district set — weekly cron churn, eyeball only',
      v_rows, BASELINE_ROWS;
  END IF;

  RAISE NOTICE 'PASS D04-NOTOUCH user_districts: us_house district set unchanged (md5 %, cardinality %)', v_set_md5, v_card;
END $$;

SELECT '1642-verify GREEN' AS result;
