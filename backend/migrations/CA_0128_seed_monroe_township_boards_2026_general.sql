-- CA_0128_seed_monroe_township_boards_2026_general.sql
-- Monroe County 2026 general: township BOARD races (3-seat, at-large). The general held
-- none; the primary held per-party board races. This merges each board into ONE 3-seat
-- general race with the certified November field.
--
-- Extends 'IN 2026 Statewide General'. Adds 10 races / 31 candidates. Reuses the 9 existing
-- board offices; creates the Polk board office (the Polk board was missing). Bean Blossom
-- Township Board is OMITTED: no one filed (0 candidates) — the seats fill by caucus later,
-- so there is no race on the printed ballot.
--
-- FIELD = CERTIFIED GENERAL, not primary filers. Three boards had contested party primaries;
-- only the top-3 advanced (confirmed by May-5 vote totals AND the certified ballot):
--   Clear Creek R (4->3): Dillard, Reed, Webb  (Strain lost by 7)
--   Perry D (5->3):       Sturbaum, Olmes-Stevens, Hamilton  (Goodrich, Jack Davis lost)
--   Richland R (4->3):    Thrasher, Willibey, Thomsen  (Conyer lost)
-- Caucus-added candidates who joined AFTER the primary (not in our primary data) are
-- included: Sean McInerney (Benton D), Victoria Streiff (Polk D), Ashlie Kehrberg (Washington D).
-- No independent/petition candidate filed for any township board. Several boards are
-- under-filled (Benton 2, Polk 1, Van Buren exactly 3) — that is the real ballot.
--
-- 3-seat at-large: each board is ONE race, seats=3, primary_party NULL (antipartisan).
-- Candidates link to existing politician rows where one exists; the rest (caucus adds and
-- primary rows that were never linked) get politician_id NULL.
--
-- SOURCE: Monroe County Election Division certified filed-candidate list (July 6, 2026) and
-- May-5 primary vote totals, via B Square Bulletin; cross-checked vs Ballotpedia + county
-- filings PDF for party/incumbency. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: Polk office guard on (district_id,title); races on (election_id,position_name);
-- candidates on (race_id,lower(full_name)).

BEGIN;

-- ─── Polk board office (the only missing one with a candidate) ──────────────────────────
INSERT INTO essentials.offices
  (title, district_id, chamber_id, partisan_type, representing_state, seats,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT 'Polk Township Board', 'ee482f04-5afb-489d-a965-eaa5143b9674'::uuid, NULL, NULL, 'IN', 3, false, false, false
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id='ee482f04-5afb-489d-a965-eaa5143b9674'::uuid AND o.title='Polk Township Board'
);

-- ─── Races (one 3-seat race per board; primary_party NULL) ──────────────────────────────
CREATE TEMP TABLE brd_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO brd_race_seed VALUES
  ('Benton Township Board',      '4f3f3a6d-9f8e-4079-a6f7-93e5c8a2869d'),
  ('Bloomington Township Board', '18102de0-ca85-4957-9e78-5ba098c35660'),
  ('Clear Creek Township Board', '67df2778-1d86-4750-b76f-f4a363af6974'),
  ('Indian Creek Township Board','7d32174c-a987-4163-963e-05fc25f4a551'),
  ('Perry Township Board',       '54cfb4f6-37ff-4c84-bfa1-0695d1147712'),
  ('Richland Township Board',    'ce3b4c4b-3e6b-44fd-bf5d-5dd407e0ac31'),
  ('Salt Creek Township Board',  '128f41d8-bcec-4be1-b04a-62b614168e2b'),
  ('Van Buren Township Board',   'b7c1f2da-733c-4085-a57f-6aa019efbe2b'),
  ('Washington Township Board',  '31b0fb7d-cfeb-4a28-a316-56f2331f3aef');
-- Polk board office was just created; resolve its id by (district,title).
INSERT INTO brd_race_seed
SELECT 'Polk Township Board', o.id
FROM essentials.offices o
WHERE o.district_id='ee482f04-5afb-489d-a965-eaa5143b9674'::uuid AND o.title='Polk Township Board';

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, s.office_id, s.position_name, NULL, 3
FROM brd_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified Nov field; top-3 winners only for contested boards) ───────────
CREATE TEMP TABLE brd_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO brd_cand_seed VALUES
  ('Benton Township Board',      'Joe Husk',            'Joe',     'Husk',        false, '04d2e529-5456-44bb-a20f-b1ec676c2c22'::uuid),
  ('Benton Township Board',      'Sean McInerney',      'Sean',    'McInerney',   false, NULL::uuid),
  ('Bloomington Township Board', 'Dorothy Granger',     'Dorothy', 'Granger',     true,  '06464416-e8f4-4df1-af4c-2d785863721e'::uuid),
  ('Bloomington Township Board', 'Barbara E. McKinney', 'Barbara', 'McKinney',    true,  'c8a73d2a-205d-482e-bc78-8c81d965a28c'::uuid),
  ('Bloomington Township Board', 'Elizabeth Sensenstein','Elizabeth','Sensenstein',true, '15c278e1-20d8-4a2c-9575-2e130a0ec37f'::uuid),
  ('Clear Creek Township Board', 'Joann Calabrese',     'Joann',   'Calabrese',   true,  NULL::uuid),
  ('Clear Creek Township Board', 'Rachael Himsel',      'Rachael', 'Himsel',      false, NULL::uuid),
  ('Clear Creek Township Board', 'Kat Reynolds',        'Kat',     'Reynolds',    false, NULL::uuid),
  ('Clear Creek Township Board', 'Dustin Cole Dillard', 'Dustin',  'Dillard',     true,  NULL::uuid),
  ('Clear Creek Township Board', 'R. Shannon Reed',     'R. Shannon','Reed',      false, NULL::uuid),
  ('Clear Creek Township Board', 'Steven E. Webb',      'Steven',  'Webb',        false, NULL::uuid),
  ('Indian Creek Township Board','Katrina W. Ladwig',   'Katrina', 'Ladwig',      true,  '8d4c84a6-d928-42c1-b9c6-6a1433a161da'::uuid),
  ('Indian Creek Township Board','Wendi Reynolds',      'Wendi',   'Reynolds',    true,  'd5c43411-143e-4a1c-a5d4-4ea346f638b5'::uuid),
  ('Indian Creek Township Board','Roger L. Taylor',     'Roger',   'Taylor',      true,  '4e020b4f-662b-4f9e-adc1-6635311f6b6b'::uuid),
  ('Perry Township Board',       'Barbara Sturbaum',    'Barbara', 'Sturbaum',    true,  '0af9a347-846e-441e-b575-a187d8c0528f'::uuid),
  ('Perry Township Board',       'Jenny Olmes-Stevens', 'Jenny',   'Olmes-Stevens',false,'06c0727a-c17c-47b0-9aa8-bb8e6e78b70e'::uuid),
  ('Perry Township Board',       'Susie Hamilton',      'Susie',   'Hamilton',    true,  '09ae2145-53d0-4def-a32b-0d18d020aed5'::uuid),
  ('Polk Township Board',        'Victoria Streiff',    'Victoria','Streiff',     false, NULL::uuid),
  ('Richland Township Board',    'Jay Thrasher',        'Jay',     'Thrasher',    true,  '6caa511c-7051-4974-b86f-f112ca3ada2b'::uuid),
  ('Richland Township Board',    'David Willibey',      'David',   'Willibey',    true,  '53a867be-2009-4139-aca4-6371dd05cb6a'::uuid),
  ('Richland Township Board',    'Elaine Thomsen',      'Elaine',  'Thomsen',     false, NULL::uuid),
  ('Salt Creek Township Board',  'Sharon A. Green',     'Sharon',  'Green',       false, NULL::uuid),
  ('Salt Creek Township Board',  'Sean P. Hall',        'Sean',    'Hall',        true,  'c2e83228-1f15-4fb6-a1a2-8b11714afe4c'::uuid),
  ('Salt Creek Township Board',  'Joseph Hickman',      'Joseph',  'Hickman',     true,  '3bf35f73-452e-4879-bff4-1bba4e515d8e'::uuid),
  ('Van Buren Township Board',   'William E. Smith III','William', 'Smith III',   false, NULL::uuid),
  ('Van Buren Township Board',   'Theresa Oatman',      'Theresa', 'Oatman',      true,  '3a65723a-7531-4712-8a7f-e4233a5aadfb'::uuid),
  ('Van Buren Township Board',   'John Wilson',         'John',    'Wilson',      true,  '1c0afd7e-f476-4784-920f-f328a5c5d348'::uuid),
  ('Washington Township Board',  'Ashlie Kehrberg',     'Ashlie',  'Kehrberg',    false, NULL::uuid),
  ('Washington Township Board',  'Andrew Spriggs',      'Andrew',  'Spriggs',     true,  '15c77faa-dfb6-485e-8b83-4611727d1eb3'::uuid),
  ('Washington Township Board',  'Jerry Ayers',         'Jerry',   'Ayers',       true,  'ad773a1b-a007-4b7f-a1fe-2091db751d0d'::uuid),
  ('Washington Township Board',  'Kenny L. Bryant',     'Kenny',   'Bryant',      true,  '664899b9-9002-410b-b42a-40dbaf050d12'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'Monroe County Election Division certified filed-candidate list (2026-07-06) + May-5 primary vote totals, via B Square Bulletin; cross-checked vs Ballotpedia + county filings PDF. Retrieved 2026-09-21.'
FROM brd_cand_seed cs
JOIN essentials.races r
  ON r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_seats int; v_nogeo int; v_dup int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races r JOIN brd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN brd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN brd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN brd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.primary_party IS NOT NULL;
  SELECT count(*) INTO v_seats FROM essentials.races r JOIN brd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.seats<>3;
  SELECT count(*) INTO v_nogeo FROM essentials.races r JOIN brd_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id);
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN brd_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 10 THEN RAISE EXCEPTION 'board races: expected 10, got %', v_races; END IF;
  IF v_cands  <> 31 THEN RAISE EXCEPTION 'board candidates: expected 31, got %', v_cands; END IF;
  IF v_orphan <> 0  THEN RAISE EXCEPTION '% board race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0  THEN RAISE EXCEPTION '% board race(s) carry primary_party', v_party; END IF;
  IF v_seats  <> 0  THEN RAISE EXCEPTION '% board race(s) not seats=3', v_seats; END IF;
  IF v_nogeo  <> 0  THEN RAISE EXCEPTION '% board race(s) on a district with no geofence', v_nogeo; END IF;
  IF v_dup    <> 0  THEN RAISE EXCEPTION '% duplicate candidate name(s) within a board', v_dup; END IF;
END $$;

COMMIT;
