-- Migration 1484: correct 10 county-board districts that were given a `place:` ocd_id
--
-- Self-inflicted, same day: the LOCAL/LOCAL_EXEC ocd_id backfill
-- (scripts/backfill-district-ocd.ts, applied 2026-07-28) resolves ward layers with a regex that
-- matches "council|supervisor". "Supervisor" is COUNTY-board terminology, so five Pima County and
-- five Riverside County board-of-supervisors districts — typed LOCAL, geo_ids like
-- `pima-az-supervisor-district-1` — were written as
--     ocd-division/country:us/state:az/place:pima/ward:1
-- Pima and Riverside are counties, not places.
--
-- Corrected to the county form already established in the data
-- (county:los_angeles/council_district:1, county:salt_lake/council_district:2):
--     ocd-division/country:us/state:az/county:pima/council_district:1
--
-- The script itself is fixed too, keyed on the LABEL naming a county. That discriminator matters:
-- San Francisco's 11 `sf-supervisor-district-N` rows must KEEP place:san_francisco, because its
-- Board of Supervisors *is* the city council of a consolidated city-county and its labels are bare
-- ("District 1", no "County"). Those rows are pre-existing and are deliberately untouched here.
--
-- A plain re-run of the script cannot fix these: it only writes where
-- `ocd_id IS NULL OR ocd_id NOT LIKE 'ocd-division/%'`, and a wrong-but-well-formed value is
-- therefore sticky. Hence a migration.
--
-- ocd_id is read only by the coverage tracker (coverageService / coverageMapService); address
-- search joins geofence_boundaries.geo_id = districts.geo_id and never reads ocd_id. So this
-- changes coverage grouping only, not who a voter sees.
--
-- Idempotent: matched on the exact wrong value, so re-running is a no-op.

UPDATE essentials.districts
   SET ocd_id = 'ocd-division/country:us/state:az/county:pima/council_district:'
                || split_part(ocd_id, ':', 5)
 WHERE district_type IN ('LOCAL', 'LOCAL_EXEC')
   AND ocd_id ~ '^ocd-division/country:us/state:az/place:pima/ward:[0-9]+$'
   AND label ILIKE '%County%';

UPDATE essentials.districts
   SET ocd_id = 'ocd-division/country:us/state:ca/county:riverside/council_district:'
                || split_part(ocd_id, ':', 5)
 WHERE district_type IN ('LOCAL', 'LOCAL_EXEC')
   AND ocd_id ~ '^ocd-division/country:us/state:ca/place:riverside/ward:[0-9]+$'
   AND label ILIKE '%County%';

-- Post-verify gate.
DO $$
DECLARE
  leftover   int;
  corrected  int;
  sf_intact  int;
BEGIN
  -- No county-labelled LOCAL district may still carry a bare place:<county> ward id.
  SELECT count(*) INTO leftover
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC')
     AND label ILIKE '%County%'
     AND ocd_id ~ '^ocd-division/country:us/state:(az|ca)/place:(pima|riverside)/ward:[0-9]+$';
  IF leftover <> 0 THEN
    RAISE EXCEPTION 'migration 1484: % county board district(s) still carry a place: ocd_id', leftover;
  END IF;

  SELECT count(*) INTO corrected
    FROM essentials.districts
   WHERE ocd_id ~ '^ocd-division/country:us/state:(az|ca)/county:(pima|riverside)/council_district:[0-9]+$';
  IF corrected <> 10 THEN
    RAISE EXCEPTION 'migration 1484: expected 10 corrected county board districts, found %', corrected;
  END IF;

  -- San Francisco must be untouched: consolidated city-county, place: is correct there.
  SELECT count(*) INTO sf_intact
    FROM essentials.districts
   WHERE ocd_id LIKE 'ocd-division/country:us/state:ca/place:san_francisco/ward:%';
  IF sf_intact <> 11 THEN
    RAISE EXCEPTION 'migration 1484: expected San Francisco to keep 11 place: ward rows, found %', sf_intact;
  END IF;
END $$;
