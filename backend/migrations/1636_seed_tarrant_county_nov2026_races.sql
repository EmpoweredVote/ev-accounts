-- 1636: seed the three Tarrant County races on the November 3, 2026 ballot.
--
-- Tarrant County's countywide offices were seeded as officeholders (1622) but had NO
-- race rows, so the app showed no election for them with the ballot ~3 months out.
--
--   Tarrant County Judge                    Tim O'Hare (R, incumbent) v Alisa Simmons (D)
--   Tarrant County Commissioner Precinct 2  Jared Williams (D) v Tony Tinderholt (R)   [OPEN SEAT]
--   Tarrant County Commissioner Precinct 4  Manny Ramirez (R, incumbent) v Nydia Cardenas (D)
--
-- NOTE THE CROSSOVER: Alisa Simmons is our sitting Commissioner, Precinct 2 and is running
-- for County Judge, which is why Precinct 2 is an open seat with no incumbent. She is linked
-- to the County Judge race by her EXISTING politician_id -- do not create a second record for
-- her, and do not mark her is_incumbent in that race: she is the incumbent of a different office.
--
-- Precincts 1 and 3 (Miles, Krause) are NOT on this ballot; they were last elected in 2024.
--
-- Races attach to the existing 'TX 2026 Statewide General' election row rather than a new
-- county election, matching how Racine County hangs off 'WI 2026 Statewide General' and the
-- Deschutes/Washington county races hang off 'OR 2026 General'. position_name carries the
-- county prefix, same convention as 'Racine County Sheriff'.
--
-- Party is deliberately NOT stored: race_candidates has no party column and party never
-- displays on profiles. Parties above are recorded here only to document the sourcing.
--
-- Sources (both fetched 2026-08-08):
--   https://ballotpedia.org/Municipal_elections_in_Tarrant_County,_Texas_(2026)
--   https://en.wikipedia.org/wiki/2026_Tarrant_County_Judge_election
-- Ballotpedia carries a standing "candidate list may not be complete" notice; the March 3
-- primaries are decided, so the major-party nominees are settled, but a late independent or
-- write-in would not appear here. last_verified_at is stamped so staleness is visible.
--
-- NOT IN SCOPE: the rest of the county ballot (DA, county clerk, district clerk, JPs and the
-- judicial slate) has no office rows in essentials.offices yet; seeding those means creating
-- the offices first and is a separate, larger piece of work.

BEGIN;

DO $$
DECLARE v_elec uuid; v_off int; v_races int;
BEGIN
  SELECT id INTO v_elec FROM essentials.elections WHERE name = 'TX 2026 Statewide General';
  IF v_elec IS NULL THEN
    RAISE EXCEPTION 'Pre-flight FAILED: election "TX 2026 Statewide General" not found';
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Tarrant County, Texas, US'
     AND o.title IN ('County Judge', 'Commissioner, Precinct 2', 'Commissioner, Precinct 4');
  IF v_off <> 3 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 3 Tarrant offices, found %', v_off;
  END IF;

  SELECT count(*) INTO v_races
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Tarrant County, Texas, US';
  IF v_races <> 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: % Tarrant race rows already exist', v_races;
  END IF;
END $$;

-- 1. The two challengers who hold no office and have no record yet. is_incumbent is
--    explicitly false: the column DEFAULTS TO TRUE on politicians, which would be wrong here.
--    office_id NULL - neither holds office. party NULL (antipartisan).
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_incumbent, is_vacant,
   office_id, data_source)
VALUES
  (gen_random_uuid(), 'Jared Williams',  'Jared',  'Williams', NULL, true, false, false, NULL,
   'Tarrant County Nov-2026 race seed 2026-08-08'),
  (gen_random_uuid(), 'Nydia Cardenas',  'Nydia',  'Cardenas', NULL, true, false, false, NULL,
   'Tarrant County Nov-2026 race seed 2026-08-08');

-- 2. The three races.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'TX 2026 Statewide General'),
       o.id, v.position_name, NULL, 1
  FROM (VALUES
    ('County Judge',              'Tarrant County Judge'),
    ('Commissioner, Precinct 2',  'Tarrant County Commissioner Precinct 2'),
    ('Commissioner, Precinct 4',  'Tarrant County Commissioner Precinct 4')
  ) AS v(office_title, position_name)
  JOIN essentials.offices o ON o.title = v.office_title
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'Tarrant County, Texas, US';

-- 3. The six candidates, every one linked to a politician row. The four existing people are
--    matched by their known ids; the two created above are matched on the seed data_source so
--    a same-named person elsewhere in the table cannot be picked up by mistake.
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, last_verified_at, source)
SELECT gen_random_uuid(), r.id, v.pid::uuid, v.full_name, v.first_name, v.last_name,
       v.is_incumbent, 'active', now(),
       'Ballotpedia Municipal elections in Tarrant County, Texas (2026), fetched 2026-08-08'
  FROM (VALUES
    ('Tarrant County Judge',                   '4811aa62-3e47-4187-83ef-bc664c253652', 'Tim O''Hare',      'Tim',     'O''Hare',   true),
    ('Tarrant County Judge',                   '2c35b4b4-0683-488e-81a1-7790f5966db0', 'Alisa Simmons',    'Alisa',   'Simmons',  false),
    ('Tarrant County Commissioner Precinct 2', (SELECT id::text FROM essentials.politicians WHERE full_name = 'Jared Williams' AND data_source = 'Tarrant County Nov-2026 race seed 2026-08-08'), 'Jared Williams', 'Jared', 'Williams', false),
    ('Tarrant County Commissioner Precinct 2', '054a67f5-74b5-469b-bba2-0722834bac12', 'Tony Tinderholt',  'Tony',    'Tinderholt', false),
    ('Tarrant County Commissioner Precinct 4', '24eac07a-5542-41b2-9164-72a55ea11d77', 'Manny Ramirez',    'Manny',   'Ramirez',  true),
    ('Tarrant County Commissioner Precinct 4', (SELECT id::text FROM essentials.politicians WHERE full_name = 'Nydia Cardenas' AND data_source = 'Tarrant County Nov-2026 race seed 2026-08-08'), 'Nydia Cardenas', 'Nydia', 'Cardenas', false)
  ) AS v(position_name, pid, full_name, first_name, last_name, is_incumbent)
  JOIN essentials.races r ON r.position_name = v.position_name
  JOIN essentials.elections e ON e.id = r.election_id AND e.name = 'TX 2026 Statewide General';

DO $$
DECLARE v_races int; v_cands int; v_unlinked int; v_inc int;
BEGIN
  SELECT count(DISTINCT r.id), count(rc.id),
         count(*) FILTER (WHERE rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.is_incumbent)
    INTO v_races, v_cands, v_unlinked, v_inc
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE g.name = 'Tarrant County, Texas, US';

  IF v_races <> 3 OR v_cands <> 6 OR v_unlinked <> 0 OR v_inc <> 2 THEN
    RAISE EXCEPTION 'Post-check FAILED: races=% candidates=% unlinked=% incumbents=% (want 3/6/0/2)',
      v_races, v_cands, v_unlinked, v_inc;
  END IF;
END $$;

COMMIT;
