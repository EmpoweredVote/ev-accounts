-- 1845_colorado_springs_city.sql
-- City of Colorado Springs: government, council chamber, 7 districts, 10 offices,
-- and all 10 officeholders (Mayor + 6 district councilmembers + 3 at-large).
--
-- Colorado Springs deep seed. Depends on scripts/load-cos-council-boundaries.ts,
-- which already wrote the seven X0032 geofences this migration's districts key on.
--
-- ─── THE CITY-WIDE DISTRICT DOES NOT USE THE TIGER PLACE POLYGON ─────────────
-- Mayor and the three at-large seats are elected city-wide, so they need a
-- city-wide shape. The obvious choice is TIGER place 0816000 -- what Austin's
-- 'City of Austin' row keys on -- and measured 2026-08-21 it is STALE for this:
--
--     council districts union   538.29 km2
--     TIGER place 0816000       524.34 km2
--     annexed since the snapshot 14.42 km2
--
-- Colorado Springs has annexed aggressively (Karman Line, Amara). Hanging the
-- city-wide seats off TIGER would return a DISTRICT councilmember but no Mayor
-- for ~14.4 km2 of the city, and nothing would error. The city-wide district
-- therefore keys on geo_id 'colorado-springs-co-city-limits', the city's own
-- CityLimits polygon. The government row still carries census place code
-- 0816000 as its identifier, which is what that field is for.
--
-- ─── AT-LARGE NUMBERING IS AN INTERNAL LABEL, NOT A BALLOT POSITION ──────────
-- The three at-large councilmembers run city-wide in a single contest and the
-- top three win. There is no "At-Large Seat 2" on any ballot. But
-- essentials.office_terms' exclusion constraint permits exactly ONE occupant per
-- office, so three at-large holders need three office rows, and three office
-- rows need three distinct titles -- a NOT EXISTS guard keyed on
-- (district_id, title) with one shared title collapses all three into one row
-- and silently lands 8 offices instead of 10 (the Maryland multi-member trap).
-- The numbering is therefore assigned ALPHABETICALLY BY SURNAME for
-- determinism, and each office carries a description saying so, so nobody reads
-- a seniority or district meaning into it that does not exist.
--
-- ─── PARTY IS NULL FOR EVERY SEAT HERE ───────────────────────────────────────
-- Colorado Springs municipal elections are nonpartisan by charter. NULL matches
-- the Austin council rows, which is the closest precedent in the table.
--
-- SOURCES (retrieved 2026-08-21)
--   Roster        coloradosprings.gov/city-council -- all nine councilmembers,
--                 cross-checked against the RepName attribute on the city's own
--                 council-district GIS layer, which matches exactly.
--   Dates         ballotpedia.org Colorado Springs officeholder table
--                 ("Date assumed office"), and Yemi Mobolade's page for the Mayor.
--
-- term_start IS THE ASSUMED-OFFICE DATE, not the start of the current term.
-- Donelson and Henjum have held their seats continuously since 2021-04-20 and
-- were returned in 2025; they carry one term from 2021, not a fresh 2025 one.
--
-- ⚠ DISTRICT 2 IS AN OFF-CYCLE ARRIVAL. Ken Casey assumed office 2026-04-13
-- while every other district seat filled at a regular April election, and
-- Ballotpedia gives his term end as 2027 where the other district seats run to
-- 2029. That shape is a vacancy appointment. It is NOT recorded as one:
-- how_started stays NULL rather than asserting 'appointed', because the
-- appointment was not confirmed against a city record. term_end is NULL for all
-- ten regardless -- office_terms.term_end means the day occupancy ENDED, not a
-- scheduled future expiry.
--
-- IDEMPOTENCY: governments/chambers/districts/offices all guard with NOT EXISTS
-- (none of them has a usable unique index). politicians uses
-- ON CONFLICT (external_id). Occupancy goes through
-- essentials.seat_officeholder(), which closes any predecessor's open term
-- rather than overlapping it.
--
-- EXTERNAL IDS: -(830000 + n), n = 1..10. Verified free 2026-08-21 (zero rows in
-- -830001..-849999).

BEGIN;

-- ─── Government + chamber ────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Colorado Springs, Colorado, US', 'LOCAL', 'CO', 'Colorado Springs', '0816000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Colorado Springs, Colorado, US'
);

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'City Council', 'Colorado Springs City Council', 10, 4, true, 'full'
FROM essentials.governments g
WHERE g.name = 'City of Colorado Springs, Colorado, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'City Council'
  );

-- ─── Districts ───────────────────────────────────────────────────────────────
-- state is LOWERCASE 'co': it is the LOCAL-tier routing join key.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT v.geo_id, v.label, 'LOCAL', 'co', 'X0032'
FROM (VALUES
  ('colorado-springs-co-city-limits',      'City of Colorado Springs'),
  ('colorado-springs-co-council-district-1','Colorado Springs City Council District 1'),
  ('colorado-springs-co-council-district-2','Colorado Springs City Council District 2'),
  ('colorado-springs-co-council-district-3','Colorado Springs City Council District 3'),
  ('colorado-springs-co-council-district-4','Colorado Springs City Council District 4'),
  ('colorado-springs-co-council-district-5','Colorado Springs City Council District 5'),
  ('colorado-springs-co-council-district-6','Colorado Springs City Council District 6')
) AS v(geo_id, label)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = 'LOCAL'
);

-- Every district row above must have a matching polygon, or its officeholder is
-- unreachable by address and NOTHING errors.
DO $$
DECLARE v_missing int;
BEGIN
  SELECT count(*) INTO v_missing
  FROM essentials.districts d
  WHERE d.mtfcc = 'X0032' AND d.district_type = 'LOCAL'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.geofence_boundaries g
      WHERE g.geo_id = d.geo_id AND g.mtfcc = 'X0032'
    );
  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'Colorado Springs districts with no X0032 geofence: % — run scripts/load-cos-council-boundaries.ts first', v_missing;
  END IF;
END $$;

-- ─── Offices ─────────────────────────────────────────────────────────────────

-- City-wide: Mayor + 3 at-large. Numbering is alphabetical-by-surname bookkeeping.
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, is_appointed_position, seats, description)
SELECT c.id, d.id, v.title, 'CO', 'Colorado Springs', false, 1, v.descr
FROM (VALUES
  ('Mayor', NULL::text),
  ('Council Member (At-Large 1)', 'Elected city-wide. Colorado Springs elects its three at-large councilmembers in a single city-wide contest in which the top three candidates win; there is no numbered at-large seat on the ballot. The number here is an internal seat label assigned alphabetically by surname so that three distinct offices can exist, and carries no district, seniority or ballot meaning.'),
  ('Council Member (At-Large 2)', 'Elected city-wide. Colorado Springs elects its three at-large councilmembers in a single city-wide contest in which the top three candidates win; there is no numbered at-large seat on the ballot. The number here is an internal seat label assigned alphabetically by surname so that three distinct offices can exist, and carries no district, seniority or ballot meaning.'),
  ('Council Member (At-Large 3)', 'Elected city-wide. Colorado Springs elects its three at-large councilmembers in a single city-wide contest in which the top three candidates win; there is no numbered at-large seat on the ballot. The number here is an internal seat label assigned alphabetically by surname so that three distinct offices can exist, and carries no district, seniority or ballot meaning.')
) AS v(title, descr)
CROSS JOIN essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'City of Colorado Springs, Colorado, US' AND ch.name = 'City Council'
) c
WHERE d.geo_id = 'colorado-springs-co-city-limits' AND d.district_type = 'LOCAL'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = v.title
  );

-- Six district seats.
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, is_appointed_position, seats)
SELECT c.id, d.id, 'Council Member, District ' || right(d.geo_id, 1), 'CO', 'Colorado Springs', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'City of Colorado Springs, Colorado, US' AND ch.name = 'City Council'
) c
WHERE d.district_type = 'LOCAL' AND d.mtfcc = 'X0032'
  AND d.geo_id LIKE 'colorado-springs-co-council-district-%'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Council Member, District ' || right(d.geo_id, 1)
  );

-- ─── People + occupancy ──────────────────────────────────────────────────────

CREATE TEMP TABLE cos_city_seed (
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  geo_id          text,
  office_title    text,
  term_start      date,
  start_precision text
) ON COMMIT DROP;

INSERT INTO cos_city_seed VALUES
  (-830001, 'Yemi Mobolade',        'Yemi',    'Mobolade',      'colorado-springs-co-city-limits',       'Mayor',                        DATE '2023-06-06', 'day'),
  (-830002, 'Lynette Crow-Iverson', 'Lynette', 'Crow-Iverson',  'colorado-springs-co-city-limits',       'Council Member (At-Large 1)',  DATE '2023-04-18', 'day'),
  (-830003, 'David Leinweber',      'David',   'Leinweber',     'colorado-springs-co-city-limits',       'Council Member (At-Large 2)',  DATE '2023-04-18', 'day'),
  (-830004, 'Brian Risley',         'Brian',   'Risley',        'colorado-springs-co-city-limits',       'Council Member (At-Large 3)',  DATE '2023-04-18', 'day'),
  (-830005, 'Dave Donelson',        'Dave',    'Donelson',      'colorado-springs-co-council-district-1','Council Member, District 1',   DATE '2021-04-20', 'day'),
  (-830006, 'Ken Casey',            'Ken',     'Casey',         'colorado-springs-co-council-district-2','Council Member, District 2',   DATE '2026-04-13', 'day'),
  (-830007, 'Brandy Williams',      'Brandy',  'Williams',      'colorado-springs-co-council-district-3','Council Member, District 3',   DATE '2025-04-15', 'day'),
  (-830008, 'Kimberly Gold',        'Kimberly','Gold',          'colorado-springs-co-council-district-4','Council Member, District 4',   DATE '2025-04-15', 'day'),
  (-830009, 'Nancy Henjum',         'Nancy',   'Henjum',        'colorado-springs-co-council-district-5','Council Member, District 5',   DATE '2021-04-20', 'day'),
  (-830010, 'Roland Rainey Jr.',    'Roland',  'Rainey Jr.',    'colorado-springs-co-council-district-6','Council Member, District 6',   DATE '2025-04-15', 'day');

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM cos_city_seed;
  IF v_n <> 10 THEN RAISE EXCEPTION 'city seed payload: expected 10 rows, got %', v_n; END IF;
END $$;

-- party stays NULL: Colorado Springs municipal elections are nonpartisan by charter.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, true, true,
       'coloradosprings.gov/city-council for the roster (cross-checked against the RepName attribute on the city council-district GIS layer); ballotpedia.org for assumed-office dates. Retrieved 2026-08-21.'
FROM cos_city_seed s
ON CONFLICT (external_id) DO NOTHING;

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, o.id AS office_id, p.id AS politician_id
    FROM cos_city_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = 'LOCAL' AND d.mtfcc = 'X0032'
    JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = o.id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      'coloradosprings.gov/city-council + ballotpedia.org assumed-office dates. Retrieved 2026-08-21.',
      NULL,                -- how_started: District 2 looks like a vacancy appointment but was not confirmed
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % Colorado Springs city official(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_held int; v_orphan int; v_dup int;
BEGIN
  SELECT count(*) INTO v_off
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0032' AND d.district_type = 'LOCAL';

  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL
  -- politician_id, not an absent row. Without IS NOT NULL this passes vacuously.
  SELECT count(*) INTO v_held
  FROM essentials.office_current_holder och
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0032' AND d.district_type = 'LOCAL'
    AND och.politician_id IS NOT NULL;

  -- An office with no term row is invisible: no holder, and nothing errors.
  SELECT count(*) INTO v_orphan
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0032' AND d.district_type = 'LOCAL'
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

  -- Two districts sharing a geo_id at the same type would fan out address search.
  SELECT count(*) INTO v_dup
  FROM (
    SELECT geo_id FROM essentials.districts
    WHERE mtfcc = 'X0032' AND district_type = 'LOCAL'
    GROUP BY geo_id HAVING count(*) > 1
  ) x;

  IF v_off <> 10 THEN RAISE EXCEPTION 'Colorado Springs city offices: expected 10, got %', v_off; END IF;
  IF v_held <> 10 THEN RAISE EXCEPTION 'Colorado Springs city seats with a current holder: expected 10, got %', v_held; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION 'Colorado Springs city offices with NO term row (invisible seats): %', v_orphan; END IF;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'duplicate X0032 LOCAL district geo_id(s): %', v_dup; END IF;
END $$;

COMMIT;
