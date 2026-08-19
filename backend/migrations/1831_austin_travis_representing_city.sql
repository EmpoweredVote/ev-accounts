-- 1831_austin_travis_representing_city.sql
--
-- Backfill offices.representing_city / representing_state for the 23 Austin/Travis seats created
-- by 1827. They were seeded with both columns NULL, which every comparable seeded city sets.
--
-- WHY THIS MATTERS — and an honest statement of how much
-- The Essentials city banner is resolved in the FRONTEND by
-- `getBuildingImages(representingCity, userState)` (essentials repo, src/lib/buildingImages.js),
-- and Results.jsx derives `representingCity` in this order for an address search:
--   1. the first LOCAL official carrying `representing_city`   <- NULL for us today
--   2. a city name parsed out of `chamber_name`                <- cannot work for us: the API
--      returns `chambers.name` ('City Council'), and the regex needs text BEFORE "City"
--      (it matches 'Bloomington City Council' and 'City of Bloomington', not 'City Council')
--   3. the city parsed out of the typed address string         <- would yield 'Austin'
--
-- So the Austin banner would probably still have rendered, via step 3, for a typed address.
-- This is therefore a ROBUSTNESS fix, not a rescue: it moves the banner onto its primary,
-- data-driven path instead of depending on the shape of whatever the user typed. Step 3 does
-- nothing in ZIP mode (deliberately null — a ZIP spans several cities) or coordinate mode.
--
-- CONVENTION, verified against every comparable row rather than assumed:
--   * CITIES set BOTH columns —
--       City of Fort Worth (11) 'Fort Worth'/'TX', City of Plano (8) 'Plano'/'TX',
--       City of Arlington (9) 'Arlington'/'TX', Bainbridge Island (7) 'Bainbridge Island'/'WA',
--       City of Seattle 'Seattle'/'WA'.
--   * COUNTIES set representing_state ONLY and leave representing_city NULL —
--       Tarrant (47), Collin (5), King (5), Dane (7) are all NULL/'<ST>'. That is deliberate:
--       a county is not a city, and a stray county-level representing_city would hijack the
--       city banner for every address in the county. Travis therefore gets state only.
--
-- 🔴 The Texas STATE banner was never affected by this gap. `userState` in Results.jsx is
--    derived from the typed address or the geo_id's FIPS prefix — NOT from
--    offices.representing_state — so Texas rendered correctly all along. Recorded because the
--    opposite is the easy assumption to make from the column name.
--
-- 🔴 Keys on (geo_id, district_type), never a label match: geo_id '48015' is shared by
--    Austin County, TX Senate District 15 and TX House District 15.
--
-- Idempotent: guarded UPDATEs, so a re-run changes nothing.

BEGIN;

-- City of Austin — both columns.
UPDATE essentials.offices o
   SET representing_city = 'Austin',
       representing_state = 'TX'
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND d.geo_id = '4805000'
   AND d.district_type = 'LOCAL'
   AND (o.representing_city IS DISTINCT FROM 'Austin'
     OR o.representing_state IS DISTINCT FROM 'TX');

-- Travis County — state ONLY. representing_city stays NULL on purpose (see header).
UPDATE essentials.offices o
   SET representing_state = 'TX'
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND d.geo_id = '48453'
   AND d.district_type = 'COUNTY'
   AND o.representing_state IS DISTINCT FROM 'TX';

DO $$
DECLARE
  city_ok     int;
  county_ok   int;
  county_bad  int;
  other_touch int;
BEGIN
  SELECT count(*) INTO city_ok
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '4805000' AND d.district_type = 'LOCAL'
     AND o.representing_city = 'Austin' AND o.representing_state = 'TX';
  IF city_ok <> 11 THEN
    RAISE EXCEPTION 'expected 11 Austin city offices tagged Austin/TX, found %', city_ok;
  END IF;

  SELECT count(*) INTO county_ok
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY'
     AND o.representing_state = 'TX';
  IF county_ok <> 12 THEN
    RAISE EXCEPTION 'expected 12 Travis County offices tagged TX, found %', county_ok;
  END IF;

  -- The positive assertion that matters more than the count: no county office may carry a
  -- representing_city, or it will hijack the city banner for every address in Travis County.
  SELECT count(*) INTO county_bad
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY'
     AND o.representing_city IS NOT NULL;
  IF county_bad <> 0 THEN
    RAISE EXCEPTION '% Travis County office(s) carry a representing_city; that hijacks the city banner', county_bad;
  END IF;

  -- Austin County (48015) and the two district-15 rows must be untouched.
  SELECT count(*) INTO other_touch
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48015' AND o.representing_city = 'Austin';
  IF other_touch <> 0 THEN
    RAISE EXCEPTION 'tagged % office(s) on geo_id 48015 as Austin — wrong county', other_touch;
  END IF;

  RAISE NOTICE 'OK: 11 Austin city offices tagged Austin/TX; 12 Travis County offices tagged TX with representing_city left NULL.';
END $$;

COMMIT;
