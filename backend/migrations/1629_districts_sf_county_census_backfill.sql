-- 1629_districts_sf_county_census_backfill.sql
--
-- Fills the one CA county left NULL by migration 1619: San Francisco.
--
-- WHY IT WAS MISSED. 1619 backfilled essentials.districts from the Census Government Units
-- Listing 2025, keying counties on FIPS_STATE||FIPS_COUNTY. San Francisco has NO separate county
-- government -- it is a consolidated city-county, and the GUS file carries it exactly once, as
-- "CITY AND COUNTY OF SAN FRANCISCO" under the PLACE FIPS 0667000. So 1619's county key '06075'
-- matched no GUS record and the county row was left NULL, while the LOCAL_EXEC row carrying
-- geo_id '0667000' received the record normally. The data was never absent -- the join shape
-- excluded it.
--
-- NOTHING NEW IS SOURCED HERE. Every value below is copied verbatim from migration 1619 line 317
-- -- same GUS record, same 2023 vintage, same CENSUS_ID_PID6 (161258). This migration only widens
-- which rows that one record is written to, which is the rule 1619 states for itself: rows sharing
-- a FIPS describe the same place, so updating each of them is correct.
--
-- 🔴 SCOPED BY district_type ON PURPOSE -- DO NOT SIMPLIFY THIS TO A geo_id-ONLY PREDICATE.
-- geo_id is not unique and is not always a FIPS. The row (STATE_LOWER, 'Assembly District 75')
-- also carries geo_id='06075' -- a synthesized '06'||'075' built from the district NUMBER, which
-- collides with San Francisco County's real county FIPS. Assembly District 75 is in San Diego
-- County. An UPDATE keyed on geo_id alone would write San Francisco's population and sfgov.org
-- onto a San Diego district and report success. That collision is a separate defect and is
-- deliberately left untouched here.
--
-- Consequence of the fix: San Francisco (808,988) ranks 13th among CA counties rather than being
-- sorted last behind Alpine (1,141) by a population of 0.
--
-- Idempotent. Re-running writes the same values and re-passes the gate.

BEGIN;

UPDATE essentials.districts d
   SET population             = 808988,
       population_source_year = 2023,
       official_web_url       = 'http://www.sfgov.org',
       census_unit_id         = '161258'
 WHERE d.district_type = 'COUNTY'
   AND lower(d.state)  = 'ca'
   AND d.geo_id        = '06075'
   AND (d.population             IS DISTINCT FROM 808988
     OR d.population_source_year IS DISTINCT FROM 2023
     OR d.official_web_url       IS DISTINCT FROM 'http://www.sfgov.org'
     OR d.census_unit_id         IS DISTINCT FROM '161258');

DO $$
DECLARE
  v_sf_pop        integer;
  v_sf_url        text;
  v_sf_unit       text;
  v_sf_rows       integer;
  v_ad75_pop      integer;
  v_null_counties integer;
BEGIN
  -- 1. The San Francisco county row now carries the GUS record.
  SELECT count(*), max(population), max(official_web_url), max(census_unit_id)
    INTO v_sf_rows, v_sf_pop, v_sf_url, v_sf_unit
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'ca' AND geo_id = '06075';

  IF v_sf_rows <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 CA COUNTY row for geo_id 06075, found %', v_sf_rows;
  END IF;
  IF v_sf_pop IS DISTINCT FROM 808988
     OR v_sf_url IS DISTINCT FROM 'http://www.sfgov.org'
     OR v_sf_unit IS DISTINCT FROM '161258' THEN
    RAISE EXCEPTION 'San Francisco county row not backfilled: pop=%, url=%, unit=%',
      v_sf_pop, v_sf_url, v_sf_unit;
  END IF;

  -- 2. THE COLLISION GUARD. Assembly District 75 shares geo_id '06075' and must be untouched.
  SELECT max(population) INTO v_ad75_pop
    FROM essentials.districts
   WHERE district_type = 'STATE_LOWER' AND geo_id = '06075';

  IF v_ad75_pop IS NOT NULL THEN
    RAISE EXCEPTION
      'Assembly District 75 (geo_id 06075) was written to -- population is now %. The UPDATE leaked past its district_type scope.',
      v_ad75_pop;
  END IF;

  -- 3. No CA county is left without a population.
  SELECT count(*) INTO v_null_counties
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'ca'
     AND (population IS NULL OR population = 0);

  IF v_null_counties <> 0 THEN
    RAISE EXCEPTION 'Expected 0 CA counties without a population, found %', v_null_counties;
  END IF;
END $$;

COMMIT;
