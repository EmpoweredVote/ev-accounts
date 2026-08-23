-- verify-buncombe-commission-coupling.sql
--
-- A 2011 local act sets Buncombe County's 3 commission districts EQUAL to NC
-- House districts 114/115/116, two commissioners each. Buncombe is the only one
-- of NC's 100 counties with this arrangement.
--
-- 🔴 THIS IS A LIVE COUPLING, NOT A HISTORICAL NOTE. A future NC House redraw
-- silently moves Buncombe's commission lines. Nothing in the schema expresses
-- the dependency -- `essentials.districts` has no note column -- so this script
-- IS the record. Run it after any NC `sldl` reload, and after any migration that
-- touches the X0034 rows.
--
-- Loaded by: backend/scripts/load-buncombe-commissioner-boundaries.ts
-- Consumed by: CA_0009 (structure), CA_0010 (occupancy) -- wave 3 of the NC
--              deep-seed program, .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THIS IS A TOLERANCE TEST AND NOT `ST_Equals`. READ BEFORE TIGHTENING IT.
--
-- The spec records Buncombe's commission districts as BYTE-IDENTICAL to the
-- state House districts -- same `Shape.STArea()`, `Shape.STLength()` and
-- population. That is true, and it is a comparison between two layers of
-- BUNCOMBE'S OWN GIS (`bcmap_VotingDistricts3/7` vs `/5`).
--
-- Our House polygons are not Buncombe's. They are TIGER 2024 `sldl`. TIGER and
-- the county are two independent digitizations of one legal boundary, so they
-- are NOT geometrically equal. Measured 2026-08-23:
--
--   commission D1 vs TIGER 37114:  ST_Equals FALSE, IoU 99.681%, symdiff 2.09 km2
--   commission D2 vs TIGER 37115:  ST_Equals FALSE, IoU 99.883%, symdiff 1.07 km2
--   commission D3 vs TIGER 37116:  ST_Equals FALSE, IoU 99.969%, symdiff 0.04 km2
--
-- An `ST_Equals` gate therefore FAILS PERMANENTLY on correct data. The danger is
-- not the red build -- it is that the obvious way to "fix" a permanently red gate
-- is to delete it, which discards the only check on the coupling.
--
-- The tolerance has real discriminating power; it is not a rubber stamp.
-- Every WRONG pairing was measured too, and they are not close:
--
--            TIGER 37114   TIGER 37115   TIGER 37116
--   comm D1      99.681%        0.002%        0.002%
--   comm D2       0.000%       99.883%        0.001%
--   comm D3       0.001%        0.002%       99.969%
--
-- Correct pairings cluster at ~99.7-100%, wrong ones at ~0%. Any threshold from
-- 1% to 99% separates them perfectly. 99.0% is chosen because it leaves 0.68
-- percentage points of headroom below the worst correct pairing (D1) for a TIGER
-- vintage change, while a genuine redraw -- which moves whole precincts, tens of
-- km2 -- cannot hide underneath it.

\set MIN_IOU_PCT 99.0

DO $$
DECLARE
  pair    RECORD;
  v_iou   numeric;
  min_iou numeric := 99.0;   -- keep in sync with \set MIN_IOU_PCT above
  n_bad   int := 0;
  n_seen  int := 0;
BEGIN
  FOR pair IN
    SELECT * FROM (VALUES
      ('buncombe-nc-commissioner-district-1', '37114'),
      ('buncombe-nc-commissioner-district-2', '37115'),
      ('buncombe-nc-commissioner-district-3', '37116')
    ) AS t(comm_geo_id, hd_geo_id)
  LOOP
    -- Pair geo_id with mtfcc on BOTH sides. geo_id is not unique across layers:
    -- '37021' alone returns Buncombe County, NC Senate 21 AND NC House 21.
    SELECT 100.0 * public.ST_Area(public.ST_Intersection(c.geometry, h.geometry)::geography)
                 / public.ST_Area(public.ST_Union(c.geometry, h.geometry)::geography)
      INTO v_iou
      FROM essentials.geofence_boundaries c
      JOIN essentials.geofence_boundaries h
        ON h.geo_id = pair.hd_geo_id AND h.mtfcc = 'G5220' AND h.state = '37'
     WHERE c.geo_id = pair.comm_geo_id AND c.mtfcc = 'X0034';

    IF v_iou IS NULL THEN
      -- Either side absent. Distinguish this from a geometry mismatch: before the
      -- loader runs, ALL THREE are absent, and that is not a decoupling.
      n_bad := n_bad + 1;
      RAISE WARNING 'MISSING: % or NC House % not present -- has the loader run?',
        pair.comm_geo_id, pair.hd_geo_id;
    ELSE
      n_seen := n_seen + 1;
      -- NB: build the percent sign into the argument. In RAISE, '%%%' parses as
      -- literal-'%' followed by the placeholder, so it renders "%99.681" rather
      -- than "99.681%".
      IF v_iou < min_iou THEN
        n_bad := n_bad + 1;
        RAISE WARNING 'DECOUPLED: % vs NC House % agree only % (need >= %)',
          pair.comm_geo_id, pair.hd_geo_id,
          round(v_iou, 3)::text || '%', min_iou::text || '%';
      ELSE
        RAISE NOTICE '  ok: % vs NC House % agree %',
          pair.comm_geo_id, pair.hd_geo_id, round(v_iou, 3)::text || '%';
      END IF;
    END IF;
  END LOOP;

  IF n_bad > 0 THEN
    RAISE EXCEPTION 'Buncombe commission coupling broken for % of 3 districts', n_bad;
  END IF;
  IF n_seen <> 3 THEN
    -- Belt and braces: a vacuous pass is the failure mode this whole program
    -- guards against. Three comparisons must actually have been made.
    RAISE EXCEPTION 'Buncombe coupling check was vacuous: % of 3 comparisons ran', n_seen;
  END IF;
  RAISE NOTICE 'Buncombe coupling OK - all 3 commission districts match their NC House twin.';
END $$;
