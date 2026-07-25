-- Migration 1415: Bend, OR deep seed — November 3, 2026 races + candidates
--
-- Depends on migration 1414 (Bend/Deschutes governments, offices, officials).
--
-- Adds to the existing 'OR 2026 General' election (2026-11-03):
--   8 NEW races: 3 City of Bend (Mayor, Council Positions 5 and 6) +
--                 5 Deschutes County (Commissioner Positions 3 and 5, Clerk, Sheriff, Treasurer)
--   12 NEW candidate politician rows (non-incumbent challengers)
--   18 race_candidates rows, including candidates for the two PRE-EXISTING
--                 OR State House District 53/54 races (both had zero candidates before this)
--   1 dual-PID merge (Patti Adair)
--
-- BALLOT ACCURACY NOTES (sourced in data/stance-research/bend-or/00-ROSTER-RESEARCH.md):
--   * Every county office in Deschutes is NONPARTISAN, as are all City of Bend offices:
--     races.primary_party stays NULL. HD 53/54 are partisan but their party nominees were already
--     settled in the May 19 2026 primary, so these are general-election rows, not primary rows.
--   * City filing closes 2026-08-25 (non-incumbents) and withdrawal closes 2026-08-28, so this
--     candidate field is PROVISIONAL. Incumbent Councilor Mike Riley (Position 6) had NOT filed
--     as of 2026-07-24 — his race therefore carries three non-incumbent candidates and no
--     incumbent. A dated re-check is filed at
--     .planning/todos/2026-07-24-bend-or-postfiling-recheck.md.
--   * Commissioner Position 5 is one of TWO seats created by the 2024 board-expansion measure.
--     Nobody holds it until January 2027, so Step 1 creates VACANT office rows for Positions 4
--     and 5 (politician_id NULL -> they never appear in the officials feed, which INNER JOINs
--     politicians) purely so the race has a non-NULL office_id. Position 4 was decided in the May
--     primary and has no November race; it is created only so the chamber's 5 seats are all
--     represented. Commissioner Position 1 (won outright in May by Jamie Collins) and the
--     Assessor race likewise have NO November row — do not add them.
--   * SD 27 is deliberately absent: Anthony Broadman was elected Nov 2024 to a term running
--     through January 2029, so Bend has no 2026 Senate race. (The DB nonetheless contains
--     2026-11-03 rows for all 30 OR Senate districts — a pre-existing defect logged at
--     .planning/todos/2026-07-24-or-senate-2026-phantom-races.md. Not touched here.)
--
-- DUAL-PID MERGE (Patti Adair): the OR-05 congressional seeding created politician -410501
-- ("Patti Adair", no office, 1 headshot, linked to the U.S. House OR-05 race). Migration 1414
-- created -4101703 for the same person as the sitting Deschutes County Commissioner Position 3.
-- One human must be one politician row, so this migration repoints the OR-05 race_candidates row
-- and the headshot at -4101703 (the row that carries the office) and deactivates -410501.
-- Party is intentionally left NULL: she is the Republican OR-05 nominee, but her county office is
-- nonpartisan and candidate cards never render party.

BEGIN;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.races r
      WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03')
        AND r.position_name LIKE 'Bend %') > 0 THEN
    RAISE EXCEPTION 'Migration 1415 already applied (Bend races exist) — aborting re-run';
  END IF;
  IF (SELECT COUNT(*) FROM essentials.governments WHERE name = 'City of Bend, Oregon, US') <> 1 THEN
    RAISE EXCEPTION 'Migration 1415 requires migration 1414 (City of Bend government missing)';
  END IF;
  IF (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') IS NULL THEN
    RAISE EXCEPTION 'Migration 1415: election OR 2026 General (2026-11-03) not found';
  END IF;
END $$;


-- =============================================================================
-- Step 1: vacant office rows for the two NEW Deschutes commissioner seats,
--         and widen the chamber to its post-2026 authorized size of 5.
-- =============================================================================
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, vacant_since, description)
SELECT gen_random_uuid(), d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Deschutes County, Oregon, US')),
       NULL, v.title, 'OR', NULL, false, true, TIMESTAMPTZ '2026-01-01',
       'Seat created by the 2024 voter-approved expansion of the Deschutes County Board of Commissioners from three to five members; first filled January 2027.'
FROM essentials.districts d
CROSS JOIN (VALUES ('Commissioner, Position 4'), ('Commissioner, Position 5')) AS v(title)
WHERE d.geo_id = '41017' AND d.district_type = 'COUNTY' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE o.title = v.title
      AND c.name = 'Board of County Commissioners'
      AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Deschutes County, Oregon, US')
  );

UPDATE essentials.chambers
SET official_count = 5,
    remarks = 'Three members served through 2026; voters expanded the board to five seats effective with the 2026 election (Positions 4 and 5 first filled January 2027).'
WHERE name = 'Board of County Commissioners'
  AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Deschutes County, Oregon, US');


-- =============================================================================
-- Step 2: 8 new races (nonpartisan -> primary_party NULL, single seat each)
-- =============================================================================
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105801)), 'Bend Mayor', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend Mayor');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105806)), 'Bend City Council Position 5', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 5');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105807)), 'Bend City Council Position 6', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101703)), 'Deschutes County Commissioner Position 3', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 3');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE o.title = 'Commissioner, Position 5'
       AND c.name = 'Board of County Commissioners'
       AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Deschutes County, Oregon, US')), 'Deschutes County Commissioner Position 5', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 5');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101711)), 'Deschutes County Clerk', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Clerk');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101714)), 'Deschutes County Sheriff', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Sheriff');

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03'), (SELECT o.id FROM essentials.offices o WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101713)), 'Deschutes County Treasurer', NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Treasurer');


-- =============================================================================
-- Step 3: 12 challenger politician rows
--   is_incumbent=false (they hold none of these offices); no office_id — a candidate is not an
--   officeholder, and seeding officeholder-titled offices for candidates is what caused the
--   Senate candidate-office leak (migs 1323-1327).
-- =============================================================================
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Ron (Rondo) Boozell', 'Ron', 'Boozell', NULL, true, false, false, false, -4105831
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4105831);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Bobbi Cummiskey', 'Bobbi', 'Cummiskey', NULL, true, false, false, false, -4105832
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4105832);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Elana Reinholtz', 'Elana', 'Reinholtz', NULL, true, false, false, false, -4105833
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4105833);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Dan Sorrells', 'Dan', 'Sorrells', NULL, true, false, false, false, -4105834
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4105834);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Lauren Connally', 'Lauren', 'Connally', NULL, true, false, false, false, -4101721
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101721);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Amy Sabbadini', 'Amy', 'Sabbadini', NULL, true, false, false, false, -4101722
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101722);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Rob Imhoff', 'Rob', 'Imhoff', NULL, true, false, false, false, -4101723
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101723);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Morgan Schmidt', 'Morgan', 'Schmidt', NULL, true, false, false, false, -4101724
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101724);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Jonathan Curtis', 'Jonathan', 'Curtis', NULL, true, false, false, false, -4101725
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101725);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'James (Mac) McLaughlin', 'James', 'McLaughlin', NULL, true, false, false, false, -4101726
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101726);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Robert Tintle', 'Robert', 'Tintle', NULL, true, false, false, false, -4101727
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4101727);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), 'Michael Summers', 'Michael', 'Summers', NULL, true, false, false, false, -4129001
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4129001);


-- =============================================================================
-- Step 4: 18 race_candidates rows
-- =============================================================================
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend Mayor'), (SELECT id FROM essentials.politicians WHERE external_id = -4105801),
       'Melanie Kebler', 'Melanie', 'Kebler', true, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend Mayor') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105801)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend Mayor'), (SELECT id FROM essentials.politicians WHERE external_id = -4105831),
       'Ron (Rondo) Boozell', 'Ron', 'Boozell', false, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend Mayor') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105831)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 5'), (SELECT id FROM essentials.politicians WHERE external_id = -4105806),
       'Ariel Méndez', 'Ariel', 'Méndez', true, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 5') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105806)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6'), (SELECT id FROM essentials.politicians WHERE external_id = -4105832),
       'Bobbi Cummiskey', 'Bobbi', 'Cummiskey', false, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105832)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6'), (SELECT id FROM essentials.politicians WHERE external_id = -4105833),
       'Elana Reinholtz', 'Elana', 'Reinholtz', false, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105833)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6'), (SELECT id FROM essentials.politicians WHERE external_id = -4105834),
       'Dan Sorrells', 'Dan', 'Sorrells', false, 'active', 'https://bendoregon.gov/city-council/elections/', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4105834)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 3'), (SELECT id FROM essentials.politicians WHERE external_id = -4101721),
       'Lauren Connally', 'Lauren', 'Connally', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 3') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101721)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 3'), (SELECT id FROM essentials.politicians WHERE external_id = -4101722),
       'Amy Sabbadini', 'Amy', 'Sabbadini', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 3') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101722)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 5'), (SELECT id FROM essentials.politicians WHERE external_id = -4101723),
       'Rob Imhoff', 'Rob', 'Imhoff', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 5') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101723)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 5'), (SELECT id FROM essentials.politicians WHERE external_id = -4101724),
       'Morgan Schmidt', 'Morgan', 'Schmidt', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Commissioner Position 5') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101724)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Clerk'), (SELECT id FROM essentials.politicians WHERE external_id = -4101711),
       'Steve Dennison', 'Steve', 'Dennison', true, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Clerk') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101711)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Clerk'), (SELECT id FROM essentials.politicians WHERE external_id = -4101725),
       'Jonathan Curtis', 'Jonathan', 'Curtis', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Clerk') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101725)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Sheriff'), (SELECT id FROM essentials.politicians WHERE external_id = -4101714),
       'Ty Rupert', 'Ty', 'Rupert', true, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Sheriff') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101714)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Sheriff'), (SELECT id FROM essentials.politicians WHERE external_id = -4101726),
       'James (Mac) McLaughlin', 'James', 'McLaughlin', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Sheriff') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101726)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Treasurer'), (SELECT id FROM essentials.politicians WHERE external_id = -4101727),
       'Robert Tintle', 'Robert', 'Tintle', false, 'active', 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Deschutes County Treasurer') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101727)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 53'), (SELECT id FROM essentials.politicians WHERE external_id = -4120053),
       'Emerson Levy', 'Emerson', 'Levy', true, 'active', 'https://ballotpedia.org/Oregon_House_of_Representatives_District_53', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 53') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4120053)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 53'), (SELECT id FROM essentials.politicians WHERE external_id = -4129001),
       'Michael Summers', 'Michael', 'Summers', false, 'active', 'https://ballotpedia.org/Oregon_House_of_Representatives_District_53', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 53') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4129001)
);
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 54'), (SELECT id FROM essentials.politicians WHERE external_id = -4120054),
       'Jason Kropf', 'Jason', 'Kropf', true, 'active', 'https://ballotpedia.org/Oregon_House_of_Representatives_District_54', NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 54') AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4120054)
);


-- =============================================================================
-- Step 5: Patti Adair dual-PID merge (-410501 -> -4101703)
-- =============================================================================
UPDATE essentials.race_candidates
SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101703), updated_at = NOW()
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410501);

UPDATE essentials.politician_images
SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101703)
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410501)
  AND NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi2
    WHERE pi2.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101703)
  );

UPDATE essentials.politicians
SET photo_origin_url = COALESCE(photo_origin_url, (SELECT photo_origin_url FROM essentials.politicians WHERE external_id = -410501))
WHERE external_id = -4101703;

UPDATE essentials.politicians
SET is_active = false,
    notes = COALESCE(notes, ARRAY[]::text[]) ||
            ARRAY['Duplicate identity retired 2026-07-24 by migration 1415: merged into external_id -4101703 (Patti Adair, Deschutes County Commissioner Position 3 and Republican nominee for U.S. House OR-05).']::text[]
WHERE external_id = -410501;


-- =============================================================================
-- Post-verification
-- =============================================================================
DO $$
DECLARE
  v_races     INTEGER;
  v_null_off  INTEGER;
  v_cands     INTEGER;
  v_hd53      INTEGER;
  v_hd54      INTEGER;
  v_p6_inc    INTEGER;
  v_adair_dup INTEGER;
  v_adair_or5 INTEGER;
  v_vacant    INTEGER;
BEGIN
  -- Bend + Deschutes races created
  SELECT COUNT(*) INTO v_races FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03')
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %');
  IF v_races <> 8 THEN
    RAISE EXCEPTION 'FAILED: Bend/Deschutes race count=%, expected 8', v_races;
  END IF;

  -- no race may have a NULL office_id
  SELECT COUNT(*) INTO v_null_off FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03')
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %')
    AND r.office_id IS NULL;
  IF v_null_off <> 0 THEN
    RAISE EXCEPTION 'FAILED: % Bend/Deschutes races have NULL office_id', v_null_off;
  END IF;

  -- candidate rows, all politician-linked
  SELECT COUNT(*) INTO v_cands FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03')
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %')
    AND rc.politician_id IS NOT NULL;
  IF v_cands <> 15 THEN
    RAISE EXCEPTION 'FAILED: Bend/Deschutes candidate count=%, expected 15', v_cands;
  END IF;

  -- the two previously-empty state house races are now populated
  SELECT COUNT(*) INTO v_hd53 FROM essentials.race_candidates rc
  WHERE rc.race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 53');
  IF v_hd53 <> 2 THEN RAISE EXCEPTION 'FAILED: HD 53 candidates=%, expected 2', v_hd53; END IF;

  SELECT COUNT(*) INTO v_hd54 FROM essentials.race_candidates rc
  WHERE rc.race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'OR State House District 54');
  IF v_hd54 <> 1 THEN RAISE EXCEPTION 'FAILED: HD 54 candidates=%, expected 1', v_hd54; END IF;

  -- Position 6 must have NO incumbent candidate (Riley had not filed as of 2026-07-24)
  SELECT COUNT(*) INTO v_p6_inc FROM essentials.race_candidates rc
  WHERE rc.race_id = (SELECT id FROM essentials.races WHERE election_id = (SELECT id FROM essentials.elections WHERE name = 'OR 2026 General' AND election_date = DATE '2026-11-03') AND position_name = 'Bend City Council Position 6') AND rc.is_incumbent;
  IF v_p6_inc <> 0 THEN
    RAISE EXCEPTION 'FAILED: Bend Position 6 has % incumbent candidate(s), expected 0', v_p6_inc;
  END IF;

  -- dual-PID merge complete: the retired row is inactive and holds no race links
  SELECT COUNT(*) INTO v_adair_dup FROM essentials.race_candidates rc
  WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -410501);
  IF v_adair_dup <> 0 THEN
    RAISE EXCEPTION 'FAILED: retired Adair row still has % race link(s)', v_adair_dup;
  END IF;

  SELECT COUNT(*) INTO v_adair_or5 FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.position_name = 'U.S. House OR-05' AND rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101703);
  IF v_adair_or5 <> 1 THEN
    RAISE EXCEPTION 'FAILED: canonical Adair row has % OR-05 candidate link(s), expected 1', v_adair_or5;
  END IF;

  -- vacant commissioner seats exist and are unfilled
  SELECT COUNT(*) INTO v_vacant FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE c.name = 'Board of County Commissioners'
    AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Deschutes County, Oregon, US')
    AND o.is_vacant AND o.politician_id IS NULL;
  IF v_vacant <> 2 THEN
    RAISE EXCEPTION 'FAILED: vacant commissioner offices=%, expected 2', v_vacant;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: races=8, candidates=18 (HD53=2, HD54=1), P6 incumbents=0, Adair merged, 2 vacant commissioner seats';
END $$;

-- Ledger entry for '1415' is registered separately as the postgres role (the Session pooler
-- role used by psql has no privileges on the supabase_migrations schema).

COMMIT;
