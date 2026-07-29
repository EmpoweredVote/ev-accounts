-- 1485_dc_ward_geo_ids.sql
--
-- Point DC's 16 ward districts at their REAL ward geofences so address search can find them.
--
-- Problem: the 8 Council ward districts carry geo_id 'dc-ward-1'..'dc-ward-8' and the 8 State Board
-- of Education ward districts carry 'dc-sboe-ward-1'..'-8'. Neither value exists in
-- essentials.geofence_boundaries. Address search joins geofence_boundaries.geo_id = districts.geo_id
-- (never ocd_id), so all 16 districts were unreachable by address: a DC address returned only the
-- Delegate district (3 officials) out of DC's 27 seated officials.
--
-- The real ward polygons are already loaded and correct: mtfcc G5220, geo_id 11001..11008, named
-- "Ward 1".."Ward 8". Verified by point-in-polygon against known addresses before writing this:
--   White House (-77.0365, 38.8977) -> Ward 2   Capitol (-77.0091, 38.8899) -> Ward 6
--   Anacostia   (-76.9847, 38.8637) -> Ward 8
-- TIGER models DC's wards as the SLDL (lower-chamber) layer because the DC Council IS DC's
-- legislature; that is why they are G5220 rather than a place/ward layer.
--
-- 11001 is ALSO the G4020 county geo_id for the District of Columbia, so geo_id alone is ambiguous.
-- That is safe because every consumer pairs geo_id WITH mtfcc and requires district_type to match
-- (MTFCC_DISTRICT_TYPE_GUARD in src/lib/geoIdGuard.ts, mirrored inline in
-- getRepresentativesByAddress): G4020 only matches COUNTY/JUDICIAL, so a CITY_COUNCIL or
-- SCHOOL_BOARD district can never pick up the county-wide polygon.
--
-- CODE DEPENDENCY: this migration alone is NOT sufficient. The guard maps G5220 exclusively to
-- district_type STATE_LOWER, so these rows still would not join. The same commit adds a
-- DC-scoped clause allowing G5220 to match CITY_COUNCIL/SCHOOL_BOARD, in BOTH copies of the guard.
-- Deploy the API for this to take effect.
--
-- Ward N -> geo_id 1100N for N in 1..8: DC has exactly 8 wards, so the mapping is total and
-- unambiguous, taken from the district's own ward number rather than any name matching.
--
-- Idempotent: guarded on the old slug values, so a re-run is a no-op. Reversible by restoring
-- 'dc-ward-' || n and 'dc-sboe-ward-' || n for the same rows.

BEGIN;

-- Council wards: dc-ward-N -> 1100N
UPDATE essentials.districts d
   SET geo_id = '1100' || substring(d.geo_id from 'dc-ward-([0-9]+)$')
 WHERE d.district_type = 'CITY_COUNCIL'
   AND lower(d.state) = 'dc'
   AND d.geo_id ~ '^dc-ward-[1-8]$';

-- SBOE wards: dc-sboe-ward-N -> 1100N (same 8 polygons; both bodies are elected by ward)
UPDATE essentials.districts d
   SET geo_id = '1100' || substring(d.geo_id from 'dc-sboe-ward-([0-9]+)$')
 WHERE d.district_type = 'SCHOOL_BOARD'
   AND lower(d.state) = 'dc'
   AND d.geo_id ~ '^dc-sboe-ward-[1-8]$';

-- Post-verify gate. Asserts the outcome, not the statement count, so it is meaningful on a re-run.
DO $$
DECLARE
  v_council   int;
  v_sboe      int;
  v_leftover  int;
  v_unmatched int;
BEGIN
  SELECT count(*) INTO v_council
    FROM essentials.districts
   WHERE district_type = 'CITY_COUNCIL' AND lower(state) = 'dc' AND geo_id ~ '^1100[1-8]$';
  SELECT count(*) INTO v_sboe
    FROM essentials.districts
   WHERE district_type = 'SCHOOL_BOARD' AND lower(state) = 'dc' AND geo_id ~ '^1100[1-8]$';
  -- No district may still carry an old slug.
  SELECT count(*) INTO v_leftover
    FROM essentials.districts
   WHERE geo_id LIKE 'dc-ward-%' OR geo_id LIKE 'dc-sboe-ward-%';
  -- Every rewritten geo_id must correspond to a real G5220 ward geofence. This is the check that
  -- would catch a typo'd or off-by-one prefix, which a count alone cannot.
  SELECT count(*) INTO v_unmatched
    FROM essentials.districts d
   WHERE lower(d.state) = 'dc'
     AND d.district_type IN ('CITY_COUNCIL','SCHOOL_BOARD')
     AND d.geo_id ~ '^1100[1-8]$'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries g
        WHERE g.geo_id = d.geo_id AND g.mtfcc = 'G5220'
     );

  IF v_council <> 8 THEN
    RAISE EXCEPTION '1485: expected 8 CITY_COUNCIL ward districts on 1100N, found %', v_council;
  END IF;
  IF v_sboe <> 8 THEN
    RAISE EXCEPTION '1485: expected 8 SCHOOL_BOARD ward districts on 1100N, found %', v_sboe;
  END IF;
  IF v_leftover <> 0 THEN
    RAISE EXCEPTION '1485: % district(s) still carry a dc-ward-/dc-sboe-ward- geo_id', v_leftover;
  END IF;
  IF v_unmatched <> 0 THEN
    RAISE EXCEPTION '1485: % rewritten geo_id(s) have no matching G5220 ward geofence', v_unmatched;
  END IF;

  RAISE NOTICE '1485 OK: 8 council + 8 SBOE ward districts now on G5220 geo_ids 11001..11008';
END $$;

COMMIT;
