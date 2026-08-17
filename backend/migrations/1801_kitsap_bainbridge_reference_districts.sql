-- Migration 1801: reference district rows for the Kitsap commissioner districts
--                 and the Bainbridge Island council wards.
--
-- PREREQUISITE: scripts/load-kitsap-bainbridge-boundaries.ts must have run first.
-- It writes the six essentials.geofence_boundaries rows this migration reads
-- (mtfcc X0027 = 3 commissioner districts, X0028 = 3 council wards). Same split
-- of responsibilities as 1744 + load-kingcounty-council-boundaries.ts: the loader
-- owns geometry, the migration owns the districts rows.
--
-- ============================================================================
-- 🔴 THESE ROWS DELIBERATELY CARRY NO OFFICE. DO NOT "FINISH" THEM.
-- ============================================================================
-- Every other X-series district in this corpus (X0025 Seattle, X0026 King County,
-- X0005 LA supervisors, X-DC-SUP Dane, ...) exists because an office routes from
-- it. These six do not, and an empty district_id column here is the finished
-- state, not a to-do.
--
-- Kitsap commissioners and Bainbridge ward councilmembers are NOMINATED by
-- district/ward in the August primary and ELECTED JURISDICTION-WIDE in the
-- November general — RCW 36.32.040(1) + 36.32.050(1) for the county, BIMC 2.06
-- for the city. Migration 1800 carries the full statutory quotations and the
-- consequence table; read that header before changing anything here. In short:
-- pointing an office at one of these polygons would delete two of three
-- commissioners, and four of seven councilmembers, from every address that
-- elects them — and would hide a countywide November race from about two thirds
-- of Kitsap voters.
--
-- They are loaded because the residency district is a real, published, currently
-- true fact about each seat that the corpus otherwise has nowhere to put, and
-- because if Kitsap ever crosses the RCW 36.32.052 threshold of 400,000 (or
-- charters, or Bainbridge amends BIMC 2.06) the boundary is already here and
-- correct. Wiring them on that day is a one-line UPDATE.
--
-- Inert in every read path, verified against the backend: essentialsService,
-- essentialsBrowseService, coverageService and electionService all reach
-- districts through `JOIN essentials.offices o ON o.district_id = d.id`, so a
-- district with no office contributes zero rows to browse, address lookup,
-- elections and coverage. locationSearchService never searches geofence names —
-- it joins geofence_boundaries only on an already-resolved geo_id — so these do
-- not appear in the location combobox either.
--
-- ⚠ WHAT THEY DO COST: resolveOverlappingGeoPairs branch 1 has no MTFCC filter,
-- so a Kitsap or Bainbridge seed WILL return these six as overlapping pairs.
-- They then resolve to nothing (no office). The polygons are shoreline-detailed
-- and large — Kitsap District 1 alone is ~146k vertices against King County's
-- worst of ~30k — so the exact predicate is not free. It is bounding-box
-- pre-filtered per branch, so the cost lands only on queries whose bbox already
-- touches Kitsap. See project_geofence_overlap_perf; do NOT collapse those
-- UNION ALL branches back into an OR.
--
-- ⚠ THE SOUTH WARD IS NOT SHAPED LIKE ITS NAME. Bainbridge's South Ward reaches
-- up the WEST shore to about 47.67N — precincts 320 and 333, the Battle Point /
-- Arrow Point / Fletcher Bay area — which is north of the whole Central Ward.
-- Central Ward is only the compact Winslow core. Confirmed against the city's
-- own published map (bainbridgewa.gov/DocumentCenter/View/18763/
-- Current-Wards-with-Precincts) before loading. A point-in-polygon result that
-- "looks wrong by compass" here is right.
--
-- Idempotency: NOT EXISTS on (geo_id, mtfcc); re-running is a no-op.

BEGIN;

-- ─── Kitsap County Commissioner Districts (X0027) ────────────────────────────
--
-- geo_id is the loader's slug 'kitsapcounty-wa-commissioner-district-N'; the
-- label is taken from geofence_boundaries.name, which the loader derived from
-- the layer's stable DISTRICT code and never from a member name.

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(),
       gb.geo_id,
       gb.name,
       'COUNTY',        -- a subdivision of the county, and the X% guard maps
                        -- X-series mtfccs to LOCAL/COUNTY
       'wa',            -- lowercase: LOCAL-tier routing join key
       'X0027'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0027'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0027'
  );

-- ─── Bainbridge Island Council Wards (X0028) ─────────────────────────────────

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(),
       gb.geo_id,
       gb.name,
       'LOCAL',
       'wa',
       'X0028'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0028'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0028'
  );

-- ─── Guards ──────────────────────────────────────────────────────────────────

DO $$
DECLARE
  gb_27 int; gb_28 int; d_27 int; d_28 int; attached int;
BEGIN
  SELECT count(*) INTO gb_27 FROM essentials.geofence_boundaries WHERE mtfcc = 'X0027';
  SELECT count(*) INTO gb_28 FROM essentials.geofence_boundaries WHERE mtfcc = 'X0028';
  IF gb_27 <> 3 OR gb_28 <> 3 THEN
    RAISE EXCEPTION 'Migration 1801: expected 3 X0027 and 3 X0028 geofences, found % and %. Run scripts/load-kitsap-bainbridge-boundaries.ts first.', gb_27, gb_28;
  END IF;

  SELECT count(*) INTO d_27 FROM essentials.districts WHERE mtfcc = 'X0027';
  SELECT count(*) INTO d_28 FROM essentials.districts WHERE mtfcc = 'X0028';
  IF d_27 <> 3 OR d_28 <> 3 THEN
    RAISE EXCEPTION 'Migration 1801: expected 3 X0027 and 3 X0028 districts, got % and %', d_27, d_28;
  END IF;

  -- The whole point of the migration: these stay unattached.
  SELECT count(*) INTO attached
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc IN ('X0027', 'X0028');
  IF attached <> 0 THEN
    RAISE EXCEPTION 'Migration 1801: % office(s) attached to a reference-only Kitsap/Bainbridge district — read the 1800 header', attached;
  END IF;
END $$;

COMMIT;
