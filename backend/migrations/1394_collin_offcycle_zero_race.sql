-- =============================================================================
-- Migration 1394: Collin County TX off-cycle zero-race city seeding
-- Josephine (4838068), Lavon (4841800), Saint Paul (4864220)
-- (Phase 219 Plan 03 — elections-candidates-backfill)
--
-- Seeds essentials.races + essentials.race_candidates for the 3 off-cycle-tier zero-race
-- cities resolved in 219-PREFLIGHT.md §4. Unlike migration 1393's shared-election-row
-- cities, these three did NOT hold their most-recent municipal election on the shared
-- 2026-05-02 date (Saint Paul is a SPLIT case — see below) — each mints its OWN election
-- row by (name, election_date, state), resolved via `elections_name_date_state_unique`
-- (migration 044), never a hardcoded literal UUID.
--
-- Melissa (4847496), the 4th city in this plan's original scope, is DELIBERATELY NOT
-- SEEDED by this migration — see the "MELISSA — DOCUMENTED OPEN GAP" comment block below
-- and the apply-script's explicit expected-0 gate for it. No cited election-result roster
-- (winners/losers/declared-elected names tied to an actual ballot) was found for either of
-- Melissa's two reference cycles (fallback-2025-05-03 for Mayor/Place2/Place4;
-- fallback-2024-05-04 for Place1/3/5/6) — only the CURRENT officeholder roster, which is
-- not itself an election-result citation (D-06 no-fabrication; PREFLIGHT backstop).
--
-- ============================================================
-- JOSEPHINE (geo_id 4838068) — own election row, 2025-11-04
-- ============================================================
-- May 2026 ballot = props-only for the city (migration 100's own comment; matches 218's
-- finding that Place 5/Gary Chappell is a continuing incumbent unaffected by any 2026
-- election). The city's real most-recent HELD council election was November 4, 2025:
--   Place 1 — Doug Ewing vs April Aurand
--   Place 2 — Brad Ahlfinger vs Jane Ridgway
--   Place 4 — Kenny McCarty vs Pamela Sardo (DB politician full_name: 'Pam Sardo')
-- Source: official sample ballot
-- `cityofjosephinetx.com/wp-content/uploads/2025/09/Sample-Ballot-November-4-2025-General-Election.pdf`;
-- cross-checked `ballotpedia.org/Jane_Ridgway_(Josephine_City_Council_Place_2,_Texas,_candidate_2025)`
-- and `ballotpedia.org/Pamela_Sardo_(Josephine_City_Council_Place_4,_Texas,_candidate_2025)`.
--
-- WINNER LINKAGE: migration 098 (tier-4 politician seeding) already seated April Aurand
-- (Place 1), Jane Ridgway (Place 2), and Pam Sardo (Place 4) as the CURRENT
-- `offices.politician_id` holders for these exact seats — and each is one of the two
-- cited candidates for that seat (per this plan's rule: reuse `offices.politician_id` for
-- a winner ONLY when the office already holds that exact person AND they are a cited
-- candidate). All three are therefore linked here as the winner, `is_incumbent = true`
-- (migration 098 lists their term as already active pre-dating this Nov-2025 cycle).
-- Their opponents (Ewing, Ahlfinger, McCarty) are seeded as losers with NO politician_id
-- (denormalized name fields only) — no independent winner confirmation exists for them,
-- and per this session's research the actual winner-per-seat was never independently
-- re-verified beyond "office already holds Aurand/Ridgway/Sardo" (a citizenportal.ai
-- snippet naming "April, Dr. Pam Sardo, Jane and Alex Esquivel" as newly installed
-- 403'd on fetch and was NOT used as a citation).
--
-- Mayor + Place 3 (Jason Turney / Alex Esquivel, per migration 098): NO citation of any
-- Nov-2025 (or other) election was found for these two seats this session — left
-- race-less, [OPEN] per PREFLIGHT. Place 5 (Gary Chappell): continuing incumbent, not up
-- this cycle — no seeding action, matches migration 1389/1390's own documentation.
--
-- ============================================================
-- LAVON (geo_id 4841800) — own election row, 2025-11-04
-- ============================================================
-- Most-recent HELD election = November 4, 2025 (NOT the shared May-2026 row):
--   Mayor — Vicki Sanson (592 votes, 54.21%) defeated Joshua Murray (500, 45.79%)
--   Place 4 — Rachel Dumas defeated Ted Dill
--   Place 2 — Mike Cook, uncontested
-- Source: `votes.decisiondeskhq.com/races/2025-11-04/texas-mayor-of-lavon-general-election`;
-- `votes.decisiondeskhq.com/races/2025-11-04/texas-lavon-city-council-place-4-general-election`
-- (cross-checked `ballotpedia.org/Rachel_K._Dumas_(Lavon_City_Council_Place_4,_Texas,_candidate_2025)`);
-- `votes.decisiondeskhq.com/races/2025-11-04/texas-lavon-city-council-place-2-general-election`;
-- roster cross-confirmed via `lavontx.gov` 2025-11-18 City Council minutes.
--
-- WINNER LINKAGE: migration 097 already seated Vicki Sanson (Mayor), Mike Cook (Place 2),
-- and Rachel Dumas (Place 4) as the current `offices.politician_id` holders — each matches
-- the cited winner for that seat, so each is linked here. `is_incumbent` is set to FALSE
-- for all three (and their opponents): no citation this session states these three held
-- their respective seat BEFORE the Nov-2025 election (no "retained"/"re-elected" language
-- found, unlike Van Alstyne's Atchison in migration 1393) — a conservative, evidence-only
-- choice rather than assuming incumbency from "office currently holds this person" alone.
-- Joshua Murray and Ted Dill (losers) are seeded with NO politician_id.
--
-- Places 1, 3, 5 (Mike Shepard, Travis Jacob, Lindsey Hedge, per migration 097): were NOT
-- on the Nov-2025 ballot (their decisiondeskhq.com race routes return no server-rendered
-- result for that date) — left race-less, [OPEN] per PREFLIGHT.
--
-- ============================================================
-- SAINT PAUL (geo_id 4864220) — SPLIT across two real, distinct, cited cycles
-- ============================================================
-- (a) Council Member Place 1 + Place 2 — own election row, 2025-05-03:
--   Place 1 — Larry Nail defeated Jason Sobotka (contested)
--   Place 2 — David Dryden (Mayor Pro-tem), uncontested/declared-elected
--   Source: `stpaultexas.us/local_government/elections.php` (May 3, 2025 General);
--   `stpaultexas.us/local_government/elected_officials/seats_1-5.php` (terms "expires June
--   2027", cross-confirming Nail/Dryden as CONTINUING incumbents not up in the 2026 cycle —
--   migration 098's own header comment states this explicitly: "2 continuing incumbents
--   (Larry Nail Place 1, David Dryden Place 2) keep original valid_from='2024-05-01'").
--   Both are linked via `offices.politician_id` (migration 098 already seated them into
--   these exact seats) with `is_incumbent = true` (migration 098's own "continuing
--   incumbent" language is the citation for this). Jason Sobotka (loser): no politician_id.
--
-- (b) Mayor, Place 3, Place 4, Place 5 — the EXISTING shared 2026-05-02 election row
--   (resolved by name/date/state, `8eaba170-95f5-4c98-849e-19ff93a17680`): the town's own
--   May 2026 General AND Special Elections were CANCELLED due to unopposed candidates —
--   per D-03 this is a real declared-elected race, not a skip. Roster:
--     Mayor — J.T. Trevino (moved up from Place 4, per migration 098's own comment)
--     Place 3 — Gregory Pierson (DB politician full_name: 'Greg Pierson')
--     Place 4 — Kristen Bewley
--     Place 5 — Robert Simmons
--   Source: `stpaultexas.us/local_government/elections.php` ("The May 2nd, 2026 General and
--   Special Elections have been cancelled due to unopposed candidates" + roster table);
--   `seats_1-5.php` cross-confirms terms "expires June 2028". All four are linked via
--   `offices.politician_id` (migration 098 already seated them). `is_incumbent = false` for
--   all four: migration 098's header comment states plainly these "4 newly-elected take
--   office 2026-06-01" — i.e. new to their respective seat this cycle (Trevino himself
--   moved FROM Place 4 TO Mayor, so he is new to the Mayor seat specifically).
--
-- The town's own site uses "Seat"/"Place" interchangeably for the same offices — not a
-- naming conflict. Per the plan's instruction, offices are joined by the ACTUAL stored
-- title confirmed in migration 090: 'Mayor', 'Council Member Place 1'..'Place 5'. No Saint
-- Paul seat is left open — all 6 are seeded across the two cycles above.
--
-- ============================================================
-- MELISSA (geo_id 4847496) — DOCUMENTED OPEN GAP, deliberately NOT seeded
-- ============================================================
-- Real cycles: fallback-2025-05-03 (Mayor/Place2/Place4) + fallback-2024-05-04
-- (Place1/3/5/6) — per PREFLIGHT this conflict (props-only per migration 100 vs. a
-- misread WebSearch snippet) is resolved: Melissa's city council was NOT on the
-- 2026-05-02 ballot (ISD-only that cycle). However, NO cited election-result roster
-- (winners, losers, or declared-elected names tied to an actual ballot/canvass) was
-- found for EITHER of Melissa's two real reference cycles this session — only the
-- CURRENT officeholder roster (Northcut/Taylor/Hendrickson/Conklin/Armstrong/Ackerman/Lehr,
-- live-fetched `cityofmelissa.com/287/Elections`, 2026-07-23), which is a cross-check of
-- who currently holds each seat, NOT an election-result citation, and per D-06/the plan's
-- explicit backstop is NOT sufficient to seed candidate rows. All 7 Melissa offices
-- (Mayor + Place 1-6) remain race-less pending a future canvass-sourced reconcile phase.
-- No SQL runs against Melissa in this migration; see the apply-script's explicit
-- expected-0 gate for geo_id 4847496, which documents this same reason inline.
--
-- Idempotent: races via ON CONFLICT (election_id, position_name) WHERE primary_party IS
-- NULL DO NOTHING (migration 044's real partial-unique constraint); candidates via
-- WHERE NOT EXISTS (race_id, full_name) guard; own election rows via
-- ON CONFLICT (name, election_date, state) DO NOTHING (migration 044's
-- elections_name_date_state_unique constraint), resolved by name/date/state afterward —
-- never a hardcoded literal election UUID as an INSERT target. D-06 antipartisan:
-- primary_party NULL on every race. D-07: zero inform.* writes (verified by the
-- apply-script's before/after gate). position_name is city-prefixed throughout
-- (RESEARCH Pitfall 3).
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_josephine UUID;
  v_election_lavon     UUID;
  v_election_stpaul25  UUID;
  v_election_shared    UUID;
  v_office_id          UUID;
  v_race               UUID;
  v_politician         UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- Mint (or reuse) Josephine's own 2025-11-04 election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level)
  VALUES ('Josephine TX City General 2025', '2025-11-04', 'TX', 'general', 'city')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_josephine FROM essentials.elections
   WHERE name = 'Josephine TX City General 2025' AND election_date = '2025-11-04' AND state = 'TX';

  IF v_election_josephine IS NULL THEN
    RAISE EXCEPTION 'Migration 1394: Josephine TX City General 2025 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Mint (or reuse) Lavon's own 2025-11-04 election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level)
  VALUES ('Lavon TX City General 2025', '2025-11-04', 'TX', 'general', 'city')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_lavon FROM essentials.elections
   WHERE name = 'Lavon TX City General 2025' AND election_date = '2025-11-04' AND state = 'TX';

  IF v_election_lavon IS NULL THEN
    RAISE EXCEPTION 'Migration 1394: Lavon TX City General 2025 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Mint (or reuse) Saint Paul's own 2025-05-03 election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level)
  VALUES ('Saint Paul TX City General 2025', '2025-05-03', 'TX', 'general', 'city')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_stpaul25 FROM essentials.elections
   WHERE name = 'Saint Paul TX City General 2025' AND election_date = '2025-05-03' AND state = 'TX';

  IF v_election_stpaul25 IS NULL THEN
    RAISE EXCEPTION 'Migration 1394: Saint Paul TX City General 2025 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Resolve the EXISTING shared 2026-05-02 TX election row (never minted here).
  -- ------------------------------------------------------------------
  SELECT id INTO v_election_shared FROM essentials.elections
   WHERE name = '2026 Texas Municipal General' AND election_date = '2026-05-02' AND state = 'TX';

  IF v_election_shared IS NULL THEN
    RAISE EXCEPTION 'Migration 1394: shared 2026-05-02 TX election row not found — aborting';
  END IF;

  -- ============================================================
  -- JOSEPHINE (geo_id 4838068) — v_election_josephine, 2025-11-04
  -- ============================================================

  -- Josephine Council Member Place 1 — April Aurand (linked; current officeholder per
  -- migration 098, cited candidate for this seat) vs Doug Ewing (no politician_id)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 1';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_josephine, v_office_id, 'Josephine Council Member Place 1', 1, NULL, 'Contested — winner not independently re-confirmed beyond office-holder linkage; see migration comment')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_josephine AND r.position_name = 'Josephine Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'April Aurand', 'April', 'Aurand', true, 'active', 'cityofjosephinetx.com Sample-Ballot-November-4-2025-General-Election.pdf'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'April Aurand');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Doug Ewing', 'Doug', 'Ewing', false, 'active', 'cityofjosephinetx.com Sample-Ballot-November-4-2025-General-Election.pdf'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Doug Ewing');

  -- Josephine Council Member Place 2 — Jane Ridgway (linked) vs Brad Ahlfinger
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 2';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_josephine, v_office_id, 'Josephine Council Member Place 2', 1, NULL, 'Contested — winner not independently re-confirmed beyond office-holder linkage; see migration comment')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_josephine AND r.position_name = 'Josephine Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Jane Ridgway', 'Jane', 'Ridgway', true, 'active', 'ballotpedia.org Jane_Ridgway (Josephine City Council Place 2, candidate 2025)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Jane Ridgway');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Brad Ahlfinger', 'Brad', 'Ahlfinger', false, 'active', 'cityofjosephinetx.com Sample-Ballot-November-4-2025-General-Election.pdf'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Brad Ahlfinger');

  -- Josephine Council Member Place 4 — Pam Sardo (linked; cited as "Pamela Sardo" on the
  -- sample ballot, DB politician full_name is 'Pam Sardo') vs Kenny McCarty
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 4';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_josephine, v_office_id, 'Josephine Council Member Place 4', 1, NULL, 'Contested — winner not independently re-confirmed beyond office-holder linkage; see migration comment')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_josephine AND r.position_name = 'Josephine Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Pam Sardo', 'Pam', 'Sardo', true, 'active', 'ballotpedia.org Pamela_Sardo (Josephine City Council Place 4, candidate 2025)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Pam Sardo');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Kenny McCarty', 'Kenny', 'McCarty', false, 'active', 'cityofjosephinetx.com Sample-Ballot-November-4-2025-General-Election.pdf'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Kenny McCarty');

  -- ============================================================
  -- LAVON (geo_id 4841800) — v_election_lavon, 2025-11-04
  -- ============================================================

  -- Lavon Mayor — Vicki Sanson (592-500, 54.21%-45.79%; linked, conservative is_incumbent
  -- = false, no "retained" citation found) defeated Joshua Murray
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4841800' AND o.title = 'Mayor';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_lavon, v_office_id, 'Lavon Mayor', 1, NULL, 'Sanson defeated Murray, 592-500 (54.21%-45.79%)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_lavon AND r.position_name = 'Lavon Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Vicki Sanson', 'Vicki', 'Sanson', false, 'active', 'votes.decisiondeskhq.com/races/2025-11-04/texas-mayor-of-lavon-general-election'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Vicki Sanson');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Joshua Murray', 'Joshua', 'Murray', false, 'active', 'votes.decisiondeskhq.com/races/2025-11-04/texas-mayor-of-lavon-general-election'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Joshua Murray');

  -- Lavon Council Member Place 2 — Mike Cook (uncontested, D-03 single candidate; linked,
  -- conservative is_incumbent = false, no "retained" citation found)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 2';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_lavon, v_office_id, 'Lavon Council Member Place 2', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_lavon AND r.position_name = 'Lavon Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Mike Cook', 'Mike', 'Cook', false, 'active', 'votes.decisiondeskhq.com/races/2025-11-04/texas-lavon-city-council-place-2-general-election'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Mike Cook');

  -- Lavon Council Member Place 4 — Rachel Dumas (linked, conservative is_incumbent = false)
  -- defeated Ted Dill
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 4';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_lavon, v_office_id, 'Lavon Council Member Place 4', 1, NULL, 'Dumas defeated Dill')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_lavon AND r.position_name = 'Lavon Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Rachel Dumas', 'Rachel', 'Dumas', false, 'active', 'votes.decisiondeskhq.com/races/2025-11-04/texas-lavon-city-council-place-4-general-election'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Rachel Dumas');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Ted Dill', 'Ted', 'Dill', false, 'active', 'votes.decisiondeskhq.com/races/2025-11-04/texas-lavon-city-council-place-4-general-election'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Ted Dill');

  -- ============================================================
  -- SAINT PAUL (geo_id 4864220) — part (a): v_election_stpaul25, 2025-05-03
  -- ============================================================

  -- Saint Paul Council Member Place 1 — Larry Nail (linked; migration 098's own
  -- "continuing incumbent" language is the citation for is_incumbent=true) defeated
  -- Jason Sobotka
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 1';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_stpaul25, v_office_id, 'Saint Paul Council Member Place 1', 1, NULL, 'Nail defeated Sobotka')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_stpaul25 AND r.position_name = 'Saint Paul Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Larry Nail', 'Larry', 'Nail', true, 'active', 'stpaultexas.us/local_government/elections.php (May 3, 2025 General)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Larry Nail');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Jason Sobotka', 'Jason', 'Sobotka', false, 'active', 'stpaultexas.us/local_government/elections.php (May 3, 2025 General)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Jason Sobotka');

  -- Saint Paul Council Member Place 2 — David Dryden (Mayor Pro-tem; uncontested, D-03
  -- single candidate; linked, is_incumbent=true per migration 098's "continuing incumbent")
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 2';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_stpaul25, v_office_id, 'Saint Paul Council Member Place 2', 1, NULL, 'Declared elected — unopposed (Mayor Pro-tem)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_stpaul25 AND r.position_name = 'Saint Paul Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'David Dryden', 'David', 'Dryden', true, 'active', 'stpaultexas.us/local_government/elected_officials/seats_1-5.php'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'David Dryden');

  -- ============================================================
  -- SAINT PAUL (geo_id 4864220) — part (b): v_election_shared (existing 2026-05-02 row)
  -- ============================================================

  -- Saint Paul Mayor — J.T. Trevino (cancelled-unopposed, D-03; linked; is_incumbent=false
  -- — new to the Mayor seat this cycle, per migration 098's comment he moved up from
  -- Place 4)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Mayor';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_shared, v_office_id, 'Saint Paul Mayor', 1, NULL, 'Declared elected — May 2026 General/Special cancelled, unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_shared AND r.position_name = 'Saint Paul Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'J.T. Trevino', 'J.T.', 'Trevino', false, 'active', 'stpaultexas.us/local_government/elections.php (cancelled due to unopposed candidates)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'J.T. Trevino');

  -- Saint Paul Council Member Place 3 — Gregory Pierson (DB politician full_name: 'Greg
  -- Pierson'; cancelled-unopposed, D-03; linked; is_incumbent=false, newly elected)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 3';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_shared, v_office_id, 'Saint Paul Council Member Place 3', 1, NULL, 'Declared elected — May 2026 General/Special cancelled, unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_shared AND r.position_name = 'Saint Paul Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Greg Pierson', 'Greg', 'Pierson', false, 'active', 'stpaultexas.us/local_government/elections.php (cancelled due to unopposed candidates)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Greg Pierson');

  -- Saint Paul Council Member Place 4 — Kristen Bewley (cancelled-unopposed, D-03; linked;
  -- is_incumbent=false, newly elected)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 4';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_shared, v_office_id, 'Saint Paul Council Member Place 4', 1, NULL, 'Declared elected — May 2026 General/Special cancelled, unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_shared AND r.position_name = 'Saint Paul Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Kristen Bewley', 'Kristen', 'Bewley', false, 'active', 'stpaultexas.us/local_government/elections.php (cancelled due to unopposed candidates)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Kristen Bewley');

  -- Saint Paul Council Member Place 5 — Robert Simmons (cancelled-unopposed, D-03; linked;
  -- is_incumbent=false, newly elected)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 5';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_shared, v_office_id, 'Saint Paul Council Member Place 5', 1, NULL, 'Declared elected — May 2026 General/Special cancelled, unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_shared AND r.position_name = 'Saint Paul Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Robert Simmons', 'Robert', 'Simmons', false, 'active', 'stpaultexas.us/local_government/elections.php (cancelled due to unopposed candidates)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Robert Simmons');

  -- MELISSA (geo_id 4847496): deliberately NO SQL here — see header comment. Documented
  -- open gap, verified by the apply-script's explicit expected-0 gate.

END $$;

COMMIT;
