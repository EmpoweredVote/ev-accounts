-- CA_0142_seed_la_atlarge_unified_school_boards_2026.sql
-- Seed the Nov 3 2026 governing-board contests of the 16 LA-County UNIFIED school districts that
-- elect their board AT LARGE (every voter in the district votes for every open seat), so any
-- address in one of these districts returns its school-board contest.
--
-- SCOPE (at-large unified only; trustee-area districts are a separate slice because they need
-- per-area geometry). Seats = LA County Office of Education Informational Bulletin 7112
-- (2026-04-02), "Biennial Governing Board Member Elections - November 3, 2026", Attachments 1-3
-- (each district's ordered seat count, all marked "At-Large"); cross-checked against the Nov 2022
-- results (same four-year cycle) for the 13 districts that voted in 2022 -- all 13 agree.
-- Montebello Unified is listed at-large in the bulletin but the Registrar's certified November
-- list runs it by Trustee Area 1/2/3, so it is NOT here.
--
-- CANDIDATES = the LA County Registrar-Recorder's certified candidate list for the Nov 3 2026
-- General Election (lavote.gov/Apps/CandidateList/Index?id=4348), read 2026-09-22. Names are the
-- ballot names, re-cased from the Registrar's upper case. is_incumbent = the Registrar's INC flag
-- (E elected / A appointed). Contests with no more candidates than seats are INCLUDED on purpose
-- (decision 2026-09-22: show uncontested seats too).
--   Baldwin Park Unified             2 seat(s)  5 candidate(s)  2 incumbent(s)
--   Bassett Unified                  3 seat(s)  5 candidate(s)  3 incumbent(s)
--   Beverly Hills Unified            2 seat(s)  5 candidate(s)  1 incumbent(s)
--   Culver City Unified              3 seat(s)  4 candidate(s)  3 incumbent(s)
--   El Rancho Unified                3 seat(s)  3 candidate(s)  3 incumbent(s)  (uncontested)
--   El Segundo Unified               3 seat(s)  3 candidate(s)  3 incumbent(s)  (uncontested)
--   La Cañada Unified                3 seat(s)  6 candidate(s)  3 incumbent(s)
--   Las Virgenes Unified             3 seat(s)  4 candidate(s)  2 incumbent(s)
--   Lynwood Unified                  2 seat(s)  7 candidate(s)  2 incumbent(s)
--   Manhattan Beach Unified          3 seat(s)  3 candidate(s)  2 incumbent(s)  (uncontested)
--   Palos Verdes Peninsula Unified   3 seat(s)  6 candidate(s)  0 incumbent(s)
--   San Gabriel Unified              3 seat(s)  5 candidate(s)  3 incumbent(s)
--   San Marino Unified               3 seat(s)  3 candidate(s)  2 incumbent(s)  (uncontested)
--   Walnut Valley Unified            3 seat(s)  3 candidate(s)  3 incumbent(s)  (uncontested)
--   West Covina Unified              2 seat(s)  2 candidate(s)  2 incumbent(s)  (uncontested)
--   Wiseburn Unified                 3 seat(s)  6 candidate(s)  3 incumbent(s)
--
-- OFFICE BINDING. Each district holds N generic 'Board Member' offices (one per member) on ONE
-- whole-district SCHOOL row (TIGER unified polygon, mtfcc G5420). A multi-seat at-large race binds
-- to one of them (lowest id) purely for geography -- the house pattern already used by the
-- at-large 'Glendale City Council' race and the Texas at-large council races. No new office, so
-- no new holder is needed.
--
-- 🔴 KNOWN, NOT FIXED HERE: the sitting members held on these offices are STALE (loaded from an
-- older empowered.vote school-district roster). Of the 37 incumbents the Registrar flags, only one
-- (Triston Ezidore, Culver City) even has a politician row, and none is the DB holder. So
-- candidates are NOT linked to the stale holders; only Ezidore (a unique name) is linked. A roster
-- refresh is a separate task.
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); nonpartisan -> primary_party NULL; party is
-- never stored on candidates.
--
-- IDEMPOTENT: races on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── 1. Races (one per district, bound to an existing whole-district office) ────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, t.office_id, t.position_name, NULL, t.seats
  FROM (
    SELECT v.position_name, v.seats,
           (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
             WHERE d.geo_id = v.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
             ORDER BY o.id LIMIT 1) AS office_id
      FROM (VALUES
    ('0603690', 'Baldwin Park Unified School Board', 2),
    ('0604110', 'Bassett Unified School Board', 3),
    ('0604830', 'Beverly Hills Unified School Board', 2),
    ('0610260', 'Culver City Unified School Board', 3),
    ('0612180', 'El Rancho Unified School Board', 3),
    ('0612210', 'El Segundo Unified School Board', 3),
    ('0620130', 'La Cañada Unified School Board', 3),
    ('0621000', 'Las Virgenes Unified School Board', 3),
    ('0623160', 'Lynwood Unified School Board', 2),
    ('0600025', 'Manhattan Beach Unified School Board', 3),
    ('0629700', 'Palos Verdes Peninsula Unified School Board', 3),
    ('0634425', 'San Gabriel Unified School Board', 3),
    ('0634860', 'San Marino Unified School Board', 3),
    ('0641280', 'Walnut Valley Unified School Board', 3),
    ('0642000', 'West Covina Unified School Board', 2),
    ('0601428', 'Wiseburn Unified School Board', 3)
      ) AS v(geo_id, position_name, seats)
  ) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r
                    WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.position_name);

-- ─── 2. Candidates ──────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, v.politician_id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       'LA County Registrar-Recorder, Nov 3 2026 General Election certified candidate list (lavote.gov/Apps/CandidateList/Index?id=4348); seats per LACOE Informational Bulletin 7112 (2026-04-02). Retrieved 2026-09-22.'
  FROM (VALUES
    ('Baldwin Park Unified School Board', 'John B. De Leon', 'John', 'De Leon', NULL::uuid, true),
    ('Baldwin Park Unified School Board', 'Laura A. Franklin', 'Laura', 'Franklin', NULL::uuid, false),
    ('Baldwin Park Unified School Board', 'Christina Lucero', 'Christina', 'Lucero', NULL::uuid, false),
    ('Baldwin Park Unified School Board', 'Diana E. Miranda-Dzib', 'Diana', 'Miranda-Dzib', NULL::uuid, false),
    ('Baldwin Park Unified School Board', 'Norma Olmos', 'Norma', 'Olmos', NULL::uuid, true),
    ('Bassett Unified School Board', 'Samuel Brown-Vazquez', 'Samuel', 'Brown-Vazquez', NULL::uuid, false),
    ('Bassett Unified School Board', 'Dolores C. Rivera', 'Dolores', 'Rivera', NULL::uuid, true),
    ('Bassett Unified School Board', 'Aaron Simental', 'Aaron', 'Simental', NULL::uuid, true),
    ('Bassett Unified School Board', 'Patrice Stanzione', 'Patrice', 'Stanzione', NULL::uuid, true),
    ('Bassett Unified School Board', 'Carol Tula', 'Carol', 'Tula', NULL::uuid, false),
    ('Beverly Hills Unified School Board', 'David Cienfuegos', 'David', 'Cienfuegos', NULL::uuid, false),
    ('Beverly Hills Unified School Board', 'Jared Gonzales', 'Jared', 'Gonzales', NULL::uuid, false),
    ('Beverly Hills Unified School Board', 'Jackie R. Kruger', 'Jackie', 'Kruger', NULL::uuid, false),
    ('Beverly Hills Unified School Board', 'Kimberly Lifschitz', 'Kimberly', 'Lifschitz', NULL::uuid, false),
    ('Beverly Hills Unified School Board', 'Judith Manouchehri', 'Judith', 'Manouchehri', NULL::uuid, true),
    ('Culver City Unified School Board', 'Triston Ezidore', 'Triston', 'Ezidore', '38aa3e5d-2824-4810-af6d-ad4d8f2bd359'::uuid, true),
    ('Culver City Unified School Board', 'Brian Guerrero', 'Brian', 'Guerrero', NULL::uuid, true),
    ('Culver City Unified School Board', 'Stephanie Loredo', 'Stephanie', 'Loredo', NULL::uuid, true),
    ('Culver City Unified School Board', 'Darrel Menthe', 'Darrel', 'Menthe', NULL::uuid, false),
    ('El Rancho Unified School Board', 'John Contreras', 'John', 'Contreras', NULL::uuid, true),
    ('El Rancho Unified School Board', 'Hector Lafarga Jr.', 'Hector', 'Lafarga', NULL::uuid, true),
    ('El Rancho Unified School Board', 'Esther Mejia', 'Esther', 'Mejia', NULL::uuid, true),
    ('El Segundo Unified School Board', 'Meredith J. Beachly', 'Meredith', 'Beachly', NULL::uuid, true),
    ('El Segundo Unified School Board', 'Frank Christopher Glynn', 'Frank', 'Glynn', NULL::uuid, true),
    ('El Segundo Unified School Board', 'Tracey I. Miller-Zarneke', 'Tracey', 'Miller-Zarneke', NULL::uuid, true),
    ('La Cañada Unified School Board', 'Dan Jeffries', 'Dan', 'Jeffries', NULL::uuid, true),
    ('La Cañada Unified School Board', 'Amarpreet Singh Malik', 'Amarpreet', 'Malik', NULL::uuid, false),
    ('La Cañada Unified School Board', 'Susan Moore', 'Susan', 'Moore', NULL::uuid, false),
    ('La Cañada Unified School Board', 'Joe Radabaugh', 'Joe', 'Radabaugh', NULL::uuid, true),
    ('La Cañada Unified School Board', 'Shilpa Shinde-Garg', 'Shilpa', 'Shinde-Garg', NULL::uuid, false),
    ('La Cañada Unified School Board', 'Octavia Thuss', 'Octavia', 'Thuss', NULL::uuid, true),
    ('Las Virgenes Unified School Board', 'Angela Cutbill', 'Angela', 'Cutbill', NULL::uuid, true),
    ('Las Virgenes Unified School Board', 'Coral Edwardsen', 'Coral', 'Edwardsen', NULL::uuid, false),
    ('Las Virgenes Unified School Board', 'Dallas Lawrence', 'Dallas', 'Lawrence', NULL::uuid, true),
    ('Las Virgenes Unified School Board', 'Sandra Pope', 'Sandra', 'Pope', NULL::uuid, false),
    ('Lynwood Unified School Board', 'Alma Ruby Andrade', 'Alma', 'Andrade', NULL::uuid, false),
    ('Lynwood Unified School Board', 'James M. Bishop Sr.', 'James', 'Bishop', NULL::uuid, false),
    ('Lynwood Unified School Board', 'Julian Del Real-Calleros', 'Julian', 'Del Real-Calleros', NULL::uuid, true),
    ('Lynwood Unified School Board', 'Alfonso Morales', 'Alfonso', 'Morales', NULL::uuid, true),
    ('Lynwood Unified School Board', 'Jose Luis Piña', 'Jose', 'Piña', NULL::uuid, false),
    ('Lynwood Unified School Board', 'Mariela Renteria', 'Mariela', 'Renteria', NULL::uuid, false),
    ('Lynwood Unified School Board', 'Martina Rodriguez', 'Martina', 'Rodriguez', NULL::uuid, false),
    ('Manhattan Beach Unified School Board', 'Nathalie M. Rosen', 'Nathalie', 'Rosen', NULL::uuid, false),
    ('Manhattan Beach Unified School Board', 'Christina "Tina" Shivpuri', 'Christina', 'Shivpuri', NULL::uuid, true),
    ('Manhattan Beach Unified School Board', 'Kristen "Wysh" Weinstein', 'Kristen', 'Weinstein', NULL::uuid, true),
    ('Palos Verdes Peninsula Unified School Board', 'Louis Matthew Harley', 'Louis', 'Harley', NULL::uuid, false),
    ('Palos Verdes Peninsula Unified School Board', 'Allyson Lehrer', 'Allyson', 'Lehrer', NULL::uuid, false),
    ('Palos Verdes Peninsula Unified School Board', 'Liz Peterson', 'Liz', 'Peterson', NULL::uuid, false),
    ('Palos Verdes Peninsula Unified School Board', 'Rick Phillips', 'Rick', 'Phillips', NULL::uuid, false),
    ('Palos Verdes Peninsula Unified School Board', 'Jeremy Vanderhal', 'Jeremy', 'Vanderhal', NULL::uuid, false),
    ('Palos Verdes Peninsula Unified School Board', 'Paul Vidal', 'Paul', 'Vidal', NULL::uuid, false),
    ('San Gabriel Unified School Board', 'Leif Halgard Andersen', 'Leif', 'Andersen', NULL::uuid, false),
    ('San Gabriel Unified School Board', 'Gina L. Chi', 'Gina', 'Chi', NULL::uuid, true),
    ('San Gabriel Unified School Board', 'Rochelle Kate Ongsiako Haas', 'Rochelle', 'Haas', NULL::uuid, true),
    ('San Gabriel Unified School Board', 'Cecilia Reyes Keffer', 'Cecilia', 'Keffer', NULL::uuid, false),
    ('San Gabriel Unified School Board', 'Gary Thomas Scott', 'Gary', 'Scott', NULL::uuid, true),
    ('San Marino Unified School Board', 'C. Joseph Chang', 'C. Joseph', 'Chang', NULL::uuid, true),
    ('San Marino Unified School Board', 'Marisa Kelly', 'Marisa', 'Kelly', NULL::uuid, false),
    ('San Marino Unified School Board', 'Shelley Carolyn Ryan', 'Shelley', 'Ryan', NULL::uuid, true),
    ('Walnut Valley Unified School Board', 'Helen M. Hall', 'Helen', 'Hall', NULL::uuid, true),
    ('Walnut Valley Unified School Board', 'Cindy M. Ruiz', 'Cindy', 'Ruiz', NULL::uuid, true),
    ('Walnut Valley Unified School Board', 'Yi Tony Torng', 'Yi', 'Torng', NULL::uuid, true),
    ('West Covina Unified School Board', 'Rose Lopez', 'Rose', 'Lopez', NULL::uuid, true),
    ('West Covina Unified School Board', 'Eileen Miranda Jimenez', 'Eileen', 'Jimenez', NULL::uuid, true),
    ('Wiseburn Unified School Board', 'Grace Athena Boland Bader', 'Grace', 'Bader', NULL::uuid, false),
    ('Wiseburn Unified School Board', 'Rogelio "Roger" Bañuelos', 'Rogelio', 'Bañuelos', NULL::uuid, true),
    ('Wiseburn Unified School Board', 'Dawson Bruckman', 'Dawson', 'Bruckman', NULL::uuid, false),
    ('Wiseburn Unified School Board', 'Rebecca Hamburg Cappy', 'Rebecca', 'Cappy', NULL::uuid, true),
    ('Wiseburn Unified School Board', 'Nelson E. Martinez', 'Nelson', 'Martinez', NULL::uuid, true),
    ('Wiseburn Unified School Board', 'Jeanne Ogar', 'Jeanne', 'Ogar', NULL::uuid, false)
  ) AS v(position_name, full_name, first_name, last_name, politician_id, is_incumbent)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.position_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Post-verify gate ────────────────────────────────────────────────────────────────
DO $$
DECLARE n_races int; n_cands int; n_null int; n_party int; n_badgeo int; n_ambig int; n_overinc int; n_unreach int;
BEGIN
  CREATE TEMP TABLE ca0142_pos ON COMMIT DROP AS
  SELECT r.id, r.position_name, r.seats, r.office_id, r.primary_party FROM essentials.races r
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name LIKE '% Unified School Board'
     AND r.position_name IN ('Baldwin Park Unified School Board', 'Bassett Unified School Board', 'Beverly Hills Unified School Board', 'Culver City Unified School Board', 'El Rancho Unified School Board', 'El Segundo Unified School Board', 'La Cañada Unified School Board', 'Las Virgenes Unified School Board', 'Lynwood Unified School Board', 'Manhattan Beach Unified School Board', 'Palos Verdes Peninsula Unified School Board', 'San Gabriel Unified School Board', 'San Marino Unified School Board', 'Walnut Valley Unified School Board', 'West Covina Unified School Board', 'Wiseburn Unified School Board');

  SELECT count(*) INTO n_races FROM ca0142_pos;
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN ca0142_pos p ON p.id = rc.race_id;
  SELECT count(*) INTO n_null  FROM ca0142_pos WHERE office_id IS NULL;
  SELECT count(*) INTO n_party FROM ca0142_pos WHERE primary_party IS NOT NULL;
  -- every race resolves to a real whole-district polygon
  SELECT count(*) INTO n_badgeo FROM ca0142_pos p JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  -- exactly one SCHOOL/G5420 district row per targeted geo_id (binding is unambiguous)
  SELECT count(*) INTO n_ambig FROM (
    SELECT d.geo_id FROM essentials.districts d
     WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
       AND d.geo_id IN ('0603690', '0604110', '0604830', '0610260', '0612180', '0612210', '0620130', '0621000', '0623160', '0600025', '0629700', '0634425', '0634860', '0641280', '0642000', '0601428')
     GROUP BY d.geo_id HAVING count(*) <> 1) x;
  -- no race has more incumbents than seats
  SELECT count(*) INTO n_overinc FROM ca0142_pos p
   WHERE (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = p.id AND rc.is_incumbent) > p.seats;
  -- END TO END: an interior point of each district's polygon reaches its race
  SELECT count(*) INTO n_unreach FROM ca0142_pos p JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries me ON me.geo_id = d.geo_id AND me.mtfcc = d.mtfcc
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.races r2 JOIN essentials.offices o2 ON o2.id = r2.office_id
       JOIN essentials.districts d2 ON d2.id = o2.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d2.geo_id AND (d2.mtfcc IS NULL OR gb.mtfcc = d2.mtfcc)
      WHERE r2.id = p.id AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry)));

  IF n_races <> 16 THEN RAISE EXCEPTION 'expected 16 races, got %', n_races; END IF;
  IF n_cands <> 70 THEN RAISE EXCEPTION 'expected 70 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badgeo <> 0 THEN RAISE EXCEPTION '% race(s) not resolvable to a polygon', n_badgeo; END IF;
  IF n_ambig <> 0 THEN RAISE EXCEPTION '% district geo_id(s) with <> 1 SCHOOL/G5420 row', n_ambig; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own district', n_unreach; END IF;
  RAISE NOTICE 'CA_0142 applied: % races, % candidates', n_races, n_cands;
END $$;

COMMIT;
