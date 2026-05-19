-- =============================================================================
-- Migration 100: Collin County TX May 2, 2026 races + candidates
--
-- Seeds essentials.races + essentials.race_candidates for 10 cities.
-- Source: Collin County Joint Election official results (21/21 vote centers)
-- Election: 2026 Texas Municipal General  election_id = 8eaba170-95f5-4c98-849e-19ff93a17680
--
-- Cities covered: Allen, Anna, Celina, Fairview, Frisco, Lowry Crossing, Lucas,
--                 Murphy, Parker, Princeton, Prosper
-- Cities with no candidate races on May 2 ballot: McKinney (last election 2025),
--   Plano (special election Jan 2026), Richardson (props only), Melissa (ISD only),
--   Josephine (props only)
-- Note: Prosper Place 3 + Place 5 were declared elected before election day
--   (unopposed under TX Election Code Ch. 2) — seeded here for completeness.
-- Note: Parker "At-Large Vote For 2" uses Place 1 office with seats=2.
-- Note: Lowry Crossing "Ward 4 Vote For 2" uses Place 4 office with seats=2.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id UUID := '8eaba170-95f5-4c98-849e-19ff93a17680';
  v_race        UUID;
BEGIN

  -- ============================================================
  -- ALLEN
  -- ============================================================

  -- Allen Mayor (contested: Schulmeister won ~81%, Shafer ~19%)
  -- Incumbent Baine Brooks did not run for re-election
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '684ffdb3-4073-4164-86f6-c151334fccb1', 'Allen Mayor', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Chris Schulmeister', 'Chris', 'Schulmeister', false, 'active', 'collin_county_official'),
    (v_race, 'Dave Shafer', 'Dave', 'Shafer', false, 'active', 'collin_county_official');

  -- Allen Council Member Place 2 (Tommy Baril, unopposed — incumbent re-running)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '56070326-4c8a-441a-9628-faf0e7282c3f', 'Allen Council Member Place 2', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES (v_race, 'Tommy Baril', 'Tommy', 'Baril', '3b15d821-fc1e-4e7b-bda0-13a669a77a27', true, 'active', 'collin_county_official');

  -- ============================================================
  -- ANNA
  -- ============================================================

  -- Anna Council Member Place 3 (open seat, no DB incumbent for Place 3)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'b013077b-e63c-4d07-8f06-7982cd9777e4', 'Anna Council Member Place 3', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Mike Olivarez', 'Mike', 'Olivarez', false, 'active', 'collin_county_official'),
    (v_race, 'Jessica Walden', 'Jessica', 'Walden', false, 'active', 'collin_county_official');

  -- Anna Council Member Place 5 (open seat, no DB incumbent for Place 5)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '343c8a50-dbdc-447d-b812-0a6dd5d400c0', 'Anna Council Member Place 5', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Susan Jones', 'Susan', 'Jones', false, 'active', 'collin_county_official'),
    (v_race, 'Elden Baker', 'Elden', 'Baker', false, 'active', 'collin_county_official');

  -- ============================================================
  -- CELINA
  -- ============================================================

  -- Celina Mayor (Ryan Tubbs running for re-election; Cornelius and Becker challengers)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'f3264377-124c-440d-b650-c67db1e2f2e9', 'Celina Mayor', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Ryan Tubbs', 'Ryan', 'Tubbs', 'cb9d6924-77d1-49c9-ab3d-778b0201e623', true, 'active', 'collin_county_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Erica Cornelius', 'Erica', 'Cornelius', false, 'active', 'collin_county_official'),
    (v_race, 'Eric Becker', 'Eric', 'Becker', false, 'active', 'collin_county_official');

  -- Celina Council Member Place 4 (open seat — Wendie Wigginton not running)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '98ca5ec3-7f1a-42c4-8a02-56d32b68ceb4', 'Celina Council Member Place 4', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Katie Dunn', 'Katie', 'Dunn', false, 'active', 'collin_county_official'),
    (v_race, 'Shea Scott', 'Shea', 'Scott', false, 'active', 'collin_county_official');

  -- Celina Council Member Place 5 (open seat — Mindy Koehne not running)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '09ece103-8350-4e35-861b-118c2b02d985', 'Celina Council Member Place 5', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Shane Lambert', 'Shane', 'Lambert', false, 'active', 'collin_county_official'),
    (v_race, 'Brent Baty', 'Brent', 'Baty', false, 'active', 'collin_county_official');

  -- ============================================================
  -- FAIRVIEW
  -- ============================================================

  -- Fairview Town Council Seat 2 (Joe W. Boggs, unopposed — no DB incumbent for Seat 2)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '0d12efbb-934e-4605-8c6a-b5070c540758', 'Fairview Town Council Seat 2', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES (v_race, 'Joe W. Boggs', 'Joe', 'Boggs', false, 'active', 'collin_county_official');

  -- Fairview Town Council Seat 4
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'b88b9389-e098-4523-ae2f-60f028287268', 'Fairview Town Council Seat 4', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Ricardo Doi', 'Ricardo', 'Doi', false, 'active', 'collin_county_official'),
    (v_race, 'John Stanley', 'John', 'Stanley', false, 'active', 'collin_county_official');

  -- Fairview Town Council Seat 6
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '482c8767-ca2d-4c81-a1b5-a11126e1d5a1', 'Fairview Town Council Seat 6', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Ryan Riyad', 'Ryan', 'Riyad', false, 'active', 'collin_county_official'),
    (v_race, 'Lakia Works', 'Lakia', 'Works', false, 'active', 'collin_county_official');

  -- ============================================================
  -- FRISCO
  -- ============================================================

  -- Frisco Mayor (open seat — Jeff Cheney not running; 4 challengers)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '2087a453-d1c4-47ab-904d-13ca58118fd1', 'Frisco Mayor', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'John Keating', 'John', 'Keating', false, 'active', 'collin_county_official'),
    (v_race, 'Shona Sowell', 'Shona', 'Sowell', false, 'active', 'collin_county_official'),
    (v_race, 'Rod Vilhauer', 'Rod', 'Vilhauer', false, 'active', 'collin_county_official'),
    (v_race, 'Mark Hill', 'Mark', 'Hill', false, 'active', 'collin_county_official');

  -- Frisco Council Member Place 5 (Laura Rummel running for re-election)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'd42e62f2-082c-4b04-a126-b964c94b68a0', 'Frisco Council Member Place 5', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Laura Rummel', 'Laura', 'Rummel', '76c3fa35-a286-4fa1-b6da-40300d91f33e', true, 'active', 'collin_county_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Sreekanth Reddy', 'Sreekanth', 'Reddy', false, 'active', 'collin_county_official'),
    (v_race, 'Vijay Karthik', 'Vijay', 'Karthik', false, 'active', 'collin_county_official');

  -- Frisco Council Member Place 6 (open seat — Brian Livingston not running)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '8f89f8bb-b2d6-4887-a7af-de437a990b9c', 'Frisco Council Member Place 6', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Brittany Colberg', 'Brittany', 'Colberg', false, 'active', 'collin_county_official'),
    (v_race, 'Sai Krishnarajanagar', 'Sai', 'Krishnarajanagar', false, 'active', 'collin_county_official'),
    (v_race, 'Matt Chalmers', 'Matt', 'Chalmers', false, 'active', 'collin_county_official'),
    (v_race, 'Jerry Spencer', 'Jerry', 'Spencer', false, 'active', 'collin_county_official');

  -- ============================================================
  -- LOWRY CROSSING
  -- ============================================================

  -- Lowry Crossing Council Ward 4 (Vote For 2 — 3 candidates, seats=2)
  -- Mapped to Place 4 office (no DB incumbent for Place 4)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '85447790-30ab-4ff4-88d8-1c13517c1f77', 'Lowry Crossing Council Ward 4', 2)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Donna Crenshaw Outland', 'Donna', 'Crenshaw Outland', false, 'active', 'collin_county_official'),
    (v_race, 'Ollie Simpson', 'Ollie', 'Simpson', false, 'active', 'collin_county_official'),
    (v_race, 'G Hijazen', 'G', 'Hijazen', false, 'active', 'collin_county_official');

  -- ============================================================
  -- LUCAS
  -- ============================================================

  -- Lucas City Council Seat 1 (Place 1 — no DB incumbent)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '00590b6f-f920-48d1-9532-43458c787fe5', 'Lucas City Council Place 1', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Richard Alan', 'Richard', 'Alan', false, 'active', 'collin_county_official'),
    (v_race, 'Jonathan Underhill', 'Jonathan', 'Underhill', false, 'active', 'collin_county_official');

  -- Lucas City Council Seat 2 (Place 2 — no DB incumbent)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'e03b5463-a8aa-4e67-b310-1567d2b5eb92', 'Lucas City Council Place 2', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'John Awezec', 'John', 'Awezec', false, 'active', 'collin_county_official'),
    (v_race, 'Rebecca B. Orr', 'Rebecca', 'Orr', false, 'active', 'collin_county_official');

  -- ============================================================
  -- MURPHY
  -- ============================================================

  -- Murphy Council Member Place 3 (Andrew Chase re-running; Debbie Ison challenger)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'cd6919fe-2792-433e-8a3e-44f56878b89e', 'Murphy Council Member Place 3', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Andrew Chase', 'Andrew', 'Chase', 'b6cc39bb-f246-4e2b-8f90-252d907badd5', true, 'active', 'collin_county_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Debbie Ison', 'Debbie', 'Ison', false, 'active', 'collin_county_official');

  -- Murphy Council Member Place 5 (Laura Deel re-running; 3 challengers)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, 'd7109e9a-8147-4935-a160-7e2af7b2b2b9', 'Murphy Council Member Place 5', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Laura Deel', 'Laura', 'Deel', '24d1c9c9-b496-4562-87a8-548430f26663', true, 'active', 'collin_county_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Sarah Fincanon', 'Sarah', 'Fincanon', false, 'active', 'collin_county_official'),
    (v_race, 'Manoj Varghese', 'Manoj', 'Varghese', false, 'active', 'collin_county_official'),
    (v_race, 'Kevin Kelley', 'Kevin', 'Kelley', false, 'active', 'collin_county_official');

  -- ============================================================
  -- PARKER
  -- ============================================================

  -- Parker Mayor (3 candidates, no DB incumbent)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '057bfe7a-5bb1-4e00-a664-131cfddda3cc', 'Parker Mayor', 1)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Lee Pettle', 'Lee', 'Pettle', false, 'active', 'collin_county_official'),
    (v_race, 'Marcos Arias', 'Marcos', 'Arias', false, 'active', 'collin_county_official'),
    (v_race, 'Melissa Tierce', 'Melissa', 'Tierce', false, 'active', 'collin_county_official');

  -- Parker Councilmember-At-Large (Vote For 2 — 4 candidates, seats=2, mapped to Place 1)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, '9d7ccc6b-12f5-47e0-97f8-cf634148e9a8', 'Parker Councilmember At-Large', 2)
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Billy Barron', 'Billy', 'Barron', false, 'active', 'collin_county_official'),
    (v_race, 'Buddy Pilgrim', 'Buddy', 'Pilgrim', false, 'active', 'collin_county_official'),
    (v_race, 'Alan Meyer', 'Alan', 'Meyer', false, 'active', 'collin_county_official'),
    (v_race, 'Amanda Noe', 'Amanda', 'Noe', false, 'active', 'collin_county_official');

  -- ============================================================
  -- PRINCETON
  -- ============================================================

  -- Princeton Council Place 4 Unexpired Term (4 candidates, open seat, no DB incumbent)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, description)
  VALUES (v_election_id, '327a50dd-e40f-4892-a3c2-208b1cc0d9b9', 'Princeton Council Member Place 4', 1, 'Unexpired term')
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES
    (v_race, 'Sharad Ramani', 'Sharad', 'Ramani', false, 'active', 'collin_county_official'),
    (v_race, 'Jan Goria', 'Jan', 'Goria', false, 'active', 'collin_county_official'),
    (v_race, 'Jaisen Rutledge', 'Jaisen', 'Rutledge', false, 'active', 'collin_county_official'),
    (v_race, 'Hassan Abdulkareem', 'Hassan', 'Abdulkareem', false, 'active', 'collin_county_official');

  -- ============================================================
  -- PROSPER (declared elected before election day — no ballot issued)
  -- ============================================================

  -- Prosper Council Member Place 3 (Amy Bartley, incumbent running unopposed)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, description)
  VALUES (v_election_id, '5925b2fe-a484-4882-ac66-bb2cb2661ec8', 'Prosper Council Member Place 3', 1, 'Declared elected — unopposed')
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, politician_id, is_incumbent, candidate_status, source)
  VALUES (v_race, 'Amy Bartley', 'Amy', 'Bartley', '3631dd31-cb1a-46e1-ae2d-da54ea911411', true, 'active', 'collin_county_official');

  -- Prosper Council Member Place 5 (Doug Charles, non-incumbent running unopposed — Jeff Hodges not running)
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, description)
  VALUES (v_election_id, '2b5e76a8-4152-4f97-a918-a18c99ddf478', 'Prosper Council Member Place 5', 1, 'Declared elected — unopposed')
  RETURNING id INTO v_race;

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  VALUES (v_race, 'Doug Charles', 'Doug', 'Charles', false, 'active', 'collin_county_official');

END $$;

COMMIT;
