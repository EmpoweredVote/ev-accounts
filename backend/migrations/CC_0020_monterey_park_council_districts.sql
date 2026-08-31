-- CC_0020_monterey_park_council_districts.sql
-- Correct the Monterey Park, CA city council: five DISTRICT seats, the right people in them,
-- and the mayoralty recorded as the ROTATING ROLE it is.
--
-- FOUND BY A HEADSHOT PASS. Repairing Henry Lo's portrait meant reading the city's own roster,
-- which disagreed with us four ways. Going to a body's roster for a picture is a redundancy
-- check on occupancy -- see .planning/todos/2026-08-30-headshot-check-found-two-stale-rosters.md.
--
-- WHAT THE CITY PUBLISHES (https://www.montereypark.ca.gov/917/City-Council, read 2026-08-30):
--     Henry Lo      Mayor,          District 4
--     Jose Sanchez  Mayor Pro Tem,  District 3
--     Thomas Wong   Council Member, District 1
--     Vinh T. Ngo   Council Member, District 5
--     Elizabeth Yang Council Member, District 2
--   "Council Members are elected by districts for four-year, overlapping terms of office. The
--    Mayor, who is selected during each Council reorganization every nine and half months,
--    presides over all Council meetings and is the ceremonial head of the City."
--
-- WHAT WE HELD: three At-Large 'Council Member' seats (Lo, Sanchez, Wong), plus a standing
-- LOCAL_EXEC 'Mayor' office with VINH NGO in it. So: Elizabeth Yang absent entirely, the mayor
-- wrong, the mayoralty modelled as a permanent office, and every seat mislabelled At-Large.
--
-- 🔴 THE MAYORALTY IS A ROLE, NOT AN OFFICE, AND THE CORPUS ALREADY HAS A SHAPE FOR THAT:
-- a parenthetical on the SEAT's title -- 'Council Member (Vice Mayor)', 'Commissioner (Chair)',
-- 'County Council (Logan Seat 3, Chair)'. A role that turns over every ~9.5 months must never
-- become a dated office_terms row, which would imply a four-year tenure.
--
-- 🔴 THE FIVE DISTRICTS CARRY THE PLACE geo_id (0648914), NOT district polygons, because we do
-- not have Monterey Park's council district boundaries. This is the existing house pattern, not
-- a shortcut: Long Beach (0643000) holds nine 'District N' LOCAL rows on one place geo_id, and
-- so do at least five other CA cities. Creating district rows WITHOUT geometry would make every
-- one of these seats unreachable from an address, which is strictly worse than the status quo.
-- Loading the real boundaries stays open work.
--
-- 🔴 NO DATE IS INVENTED HERE. All four existing terms are open-ended with
-- start_precision 'unknown' (from the phase-2 backfill), and they are NOT touched: the offices
-- are REPOINTED to the correct district rows, so office_id never changes and occupancy carries
-- over untouched. Elizabeth Yang gets an open-ended term with start_precision 'unknown' too --
-- the city publishes no term dates, so a real date would be a guess. Her seat is NEW, so there
-- is no predecessor to close and seat_officeholder (which demands a real term_start) is not
-- needed.
--
-- Nothing is deleted. The now-empty 'At-Large' and 'Monterey Park Mayor' district rows are left
-- in place; they carry no offices, so they hold no occupancy and cannot strand anyone.

BEGIN;

-- 1. Five district rows on the place geo_id.
INSERT INTO essentials.districts (label, ocd_id, geo_id, mtfcc, district_type, district_id, state)
SELECT v.label, 'ocd-division/country:us/state:ca/place:monterey_park', '0648914', 'G4110',
       'LOCAL', '0', 'CA'
  FROM (VALUES ('District 1'), ('District 2'), ('District 3'),
               ('District 4'), ('District 5')) AS v(label)
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
      AND d.label = v.label AND d.district_type = 'LOCAL');

-- 2. Elizabeth Yang. Party is deliberately NULL: this council is nonpartisan, and party lives on
--    races.primary_party in this schema, never on the person.
INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, is_active, is_incumbent,
        alternate_names, photo_custom_url_manual_override, bio_text_manual_override,
        full_name_manual_override)
SELECT -202378, 'Elizabeth Yang', 'Elizabeth', 'Yang', true, true,
       '{}', false, false, false
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -202378);

-- 3. Repoint the four existing seats. office_id is unchanged, so every current term rides along.
UPDATE essentials.offices o
   SET district_id = d.id, title = v.title, normalized_position_name = 'Council Member',
       chamber_id = '6fb72f66-0e8e-40a4-82f1-2491e3b617fb'
  FROM (VALUES
      ('2c4ee673-4205-4d4e-bffe-38355ac66aaa'::uuid, 'District 1', 'Council Member'),                  -- Thomas Wong
      ('b744af7d-3936-45d6-8853-7e40497c42fd'::uuid, 'District 3', 'Council Member (Mayor Pro Tem)'),   -- Jose Sanchez
      ('edd182e0-6b20-4a82-af1c-84655cc88598'::uuid, 'District 4', 'Council Member (Mayor)'),           -- Henry Lo
      ('ab4c8de3-a889-457a-b983-891238e50179'::uuid, 'District 5', 'Council Member')                    -- Vinh T. Ngo, off the old 'Mayor' office
  ) AS v(office_id, label, title)
  JOIN essentials.districts d
    ON d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
   AND d.label = v.label AND d.district_type = 'LOCAL'
 WHERE o.id = v.office_id;

-- 4. District 2 is a seat we never had. Create it, then seat Yang with an UNASSERTED start date.
INSERT INTO essentials.offices
       (chamber_id, district_id, title, representing_state, seats,
        normalized_position_name, is_appointed_position, is_vacant, faces_retention_vote,
        voting_powers)
SELECT '6fb72f66-0e8e-40a4-82f1-2491e3b617fb', d.id, 'Council Member', 'CA', 1,
       'Council Member', false, false, false, 'full'
  FROM essentials.districts d
 WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
   AND d.label = 'District 2' AND d.district_type = 'LOCAL'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

INSERT INTO essentials.office_terms
       (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT o.id, p.id, NULL, 'unknown', 'unknown',
       'City of Monterey Park council roster, https://www.montereypark.ca.gov/917/City-Council, read 2026-08-30 (CC_0020)'
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  CROSS JOIN essentials.politicians p
 WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
   AND d.label = 'District 2' AND d.district_type = 'LOCAL'
   AND p.external_id = -202378
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

DO $$
DECLARE
  n_districts int;
  n_offices   int;
  n_seated    int;
  n_wrong     int;
  n_stranded  int;
BEGIN
  SELECT count(*) INTO n_districts
    FROM essentials.districts d
   WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
     AND d.district_type = 'LOCAL' AND d.label LIKE 'District %';
  IF n_districts <> 5 THEN
    RAISE EXCEPTION 'expected 5 Monterey Park district rows, got %', n_districts;
  END IF;

  SELECT count(*), count(och.politician_id) INTO n_offices, n_seated
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
     AND d.district_type = 'LOCAL' AND d.label LIKE 'District %';
  IF n_offices <> 5 THEN
    RAISE EXCEPTION 'expected 5 Monterey Park district seats, got %', n_offices;
  END IF;
  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL politician_id and a
  -- bare count(*) would pass vacuously. Count the politician_id.
  IF n_seated <> 5 THEN
    RAISE EXCEPTION 'expected 5 seated Monterey Park council members, got %', n_seated;
  END IF;

  -- The right person in the right seat, exactly as the city publishes it.
  SELECT count(*) INTO n_wrong
    FROM (VALUES ('District 1', 'Thomas Wong'), ('District 2', 'Elizabeth Yang'),
                 ('District 3', 'Jose Sanchez'), ('District 4', 'Henry Lo'),
                 ('District 5', 'Vinh Ngo')) AS want(label, who)
    LEFT JOIN essentials.districts d
           ON d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
          AND d.district_type = 'LOCAL' AND d.label = want.label
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM want.who;
  IF n_wrong <> 0 THEN
    RAISE EXCEPTION '% Monterey Park seat(s) hold the wrong person', n_wrong;
  END IF;

  -- No standing 'Mayor' office may survive: the mayoralty is a role on a seat title.
  SELECT count(*) INTO n_stranded
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.ocd_id = 'ocd-division/country:us/state:ca/place:monterey_park'
     AND (o.title = 'Mayor' OR d.label IN ('At-Large', 'Monterey Park Mayor'));
  IF n_stranded <> 0 THEN
    RAISE EXCEPTION '% Monterey Park office(s) still sit on a retired district or title', n_stranded;
  END IF;

  RAISE NOTICE 'OK: Monterey Park now holds 5 district seats, all seated, mayoralty as a role';
END $$;

COMMIT;
