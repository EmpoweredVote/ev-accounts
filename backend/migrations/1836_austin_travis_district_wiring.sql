-- 1836_austin_travis_district_wiring.sql
-- Austin City Council + Travis County Commissioner precincts: give the districted
-- seats their own geography.
--
-- THE DEFECT THIS FIXES
--
-- All 11 City of Austin offices hung off ONE district row (geo_id 4805000, the
-- citywide TIGER place polygon), and all 12 Travis County offices off the county
-- polygon. Nothing errored: an address in Austin simply returned ALL TEN council
-- members plus the Mayor, and every Travis address returned all FOUR precinct
-- commissioners. Measured 2026-08-19 from Austin City Hall with the geoIdGuard
-- collision scoping applied: LOCAL=11 (should be 2), COUNTY=12 (should be 9).
--
-- Seattle already had this right — 7 council districts on X0025 and 9 King County
-- council districts on X0026 — so this migration mirrors that structure rather
-- than inventing one.
--
-- GEOMETRY is loaded SEPARATELY and must be in place before this runs:
--   scripts/load-austin-council-boundaries.ts        -> 10 rows, mtfcc X0030
--   scripts/load-travis-commissioner-boundaries.ts   ->  4 rows, mtfcc X0031
-- Both refuse to write unless their positive controls pass. The Austin loader's
-- control matters most: FOUR published Austin layers each return exactly 10
-- polygons and the plainest-named one (`Council_Districts`) is the superseded
-- 2016 map, differing from the current map across 11.6% of the city's area.
--
-- REPOINT, DO NOT RECREATE. The 11 city and 12 county offices already exist and
-- already carry office_terms, headshots and 58 stances. This migration only moves
-- offices.district_id. Dropping and re-inserting the offices would orphan the
-- terms (an office with no term row is INVISIBLE and nothing errors) and detach
-- the stance corpus.
--
-- WHAT STAYS PUT
--   Mayor of Austin stays on 'City of Austin' (LOCAL, 4805000) — elected citywide,
--   so the citywide polygon is the correct geography.
--   The 8 countywide Travis offices (County Judge, Sheriff, DA, County/District
--   Clerk, County Attorney, Treasurer, Tax Assessor-Collector) stay on
--   'Travis County' (COUNTY, 48453) for the same reason.
--
-- DISTRICT NUMBER PARSING: split_part(geo_id, '-', 5). Austin has TEN districts,
-- so the right(geo_id, 1) idiom used by the 7-district Seattle migration is wrong
-- here — it maps district 10 onto '0'.
--
-- Idempotency: NOT EXISTS on inserts, and the UPDATEs are guarded so a re-run is
-- a no-op.

BEGIN;

-- ─── District rows: 10 Austin council districts on the X0030 geofences ────────

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(), gb.geo_id,
       'Austin City Council District ' || split_part(gb.geo_id, '-', 5),
       'LOCAL', 'tx', 'X0030'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0030'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0030'
  );

-- ─── District rows: 4 Travis commissioner precincts on the X0031 geofences ────

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(), gb.geo_id,
       'Travis County Commissioner Precinct ' || split_part(gb.geo_id, '-', 5),
       'LOCAL', 'tx', 'X0031'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0031'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0031'
  );

-- ─── Repoint the 10 council seats off the citywide district ──────────────────

UPDATE essentials.offices o
SET district_id = nd.id
FROM essentials.districts nd
WHERE nd.mtfcc = 'X0030'
  AND o.title = 'Council Member District ' || split_part(nd.geo_id, '-', 5)
  AND o.district_id IN (
    SELECT id FROM essentials.districts
    WHERE geo_id = '4805000' AND district_type = 'LOCAL' AND state = 'tx'
  );

-- ─── Repoint the 4 precinct commissioners off the countywide district ────────

UPDATE essentials.offices o
SET district_id = nd.id
FROM essentials.districts nd
WHERE nd.mtfcc = 'X0031'
  AND o.title = 'Commissioner, Precinct ' || split_part(nd.geo_id, '-', 5)
  AND o.district_id IN (
    SELECT id FROM essentials.districts
    WHERE geo_id = '48453' AND district_type = 'COUNTY' AND state = 'tx'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_austin_districts   int;
  v_travis_districts   int;
  v_council_repointed  int;
  v_commish_repointed  int;
  v_city_remaining     int;
  v_county_remaining   int;
  v_council_seated     int;
  v_commish_seated     int;
BEGIN
  SELECT count(*) INTO v_austin_districts
    FROM essentials.districts WHERE mtfcc = 'X0030';
  SELECT count(*) INTO v_travis_districts
    FROM essentials.districts WHERE mtfcc = 'X0031';

  IF v_austin_districts <> 10 THEN
    RAISE EXCEPTION 'Expected 10 Austin council districts (X0030), found %', v_austin_districts;
  END IF;
  IF v_travis_districts <> 4 THEN
    RAISE EXCEPTION 'Expected 4 Travis commissioner precincts (X0031), found %', v_travis_districts;
  END IF;

  -- Every council seat sits on the district whose number matches its title.
  SELECT count(*) INTO v_council_repointed
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
   WHERE o.title = 'Council Member District ' || split_part(d.geo_id, '-', 5);
  IF v_council_repointed <> 10 THEN
    RAISE EXCEPTION 'Expected 10 council seats on their own district, found %', v_council_repointed;
  END IF;

  SELECT count(*) INTO v_commish_repointed
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0031'
   WHERE o.title = 'Commissioner, Precinct ' || split_part(d.geo_id, '-', 5);
  IF v_commish_repointed <> 4 THEN
    RAISE EXCEPTION 'Expected 4 commissioners on their own precinct, found %', v_commish_repointed;
  END IF;

  -- The citywide/countywide rows keep exactly the at-large seats and nothing else.
  SELECT count(*) INTO v_city_remaining
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '4805000' AND d.district_type = 'LOCAL' AND d.state = 'tx';
  IF v_city_remaining <> 1 THEN
    RAISE EXCEPTION 'Expected only the Mayor left on City of Austin, found % offices', v_city_remaining;
  END IF;

  SELECT count(*) INTO v_county_remaining
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY' AND d.state = 'tx';
  IF v_county_remaining <> 8 THEN
    RAISE EXCEPTION 'Expected 8 countywide Travis offices remaining, found %', v_county_remaining;
  END IF;

  -- Occupancy survived the repoint. A seat with no term row is invisible and
  -- silent, so assert the POSITIVE fact rather than the absence of an error.
  SELECT count(*) INTO v_council_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE och.politician_id IS NOT NULL;
  IF v_council_seated <> 10 THEN
    RAISE EXCEPTION 'Expected 10 seated council members after repoint, found %', v_council_seated;
  END IF;

  SELECT count(*) INTO v_commish_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0031'
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE och.politician_id IS NOT NULL;
  IF v_commish_seated <> 4 THEN
    RAISE EXCEPTION 'Expected 4 seated commissioners after repoint, found %', v_commish_seated;
  END IF;

  RAISE NOTICE 'OK: 10 Austin council districts + 4 Travis precincts wired; 14 seats repointed, all seated.';
END $$;

COMMIT;
