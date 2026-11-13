-- CC_0407 — seed the three Indiana legislative races that CA_0374 seated but that carry no race row.
--
-- WHY. `CA_0374` seated FOUR Indiana winners on 2026-11-04. Only ONE of them — House 62 — shows
--   anywhere in the transition programme, because the programme counts RACES and the other three
--   offices carry no race row at all. House 45, House 63 and Senate 39 have a sitting member whose
--   term our own `office_terms` opened, and no record that anybody was elected to put them there.
--   🔴 THAT IS A DIFFERENT GAP FROM THE 641 UNSEEDED RACES. Those are races with no candidate rows.
--   These are OFFICES WITH NO RACE, which no race-keyed read can see — not the tracker, not the
--   headshot gap count, not the stance gap count, not `check:incumbency`. A seat in this state is
--   invisible rather than incomplete, so nothing reports it as missing.
--   Found 2026-11-12 while checking CA_0374's seating date; EmpoweredVote/ev-accounts#1413.
--
-- 🔴 THIS FILE CREATES CANDIDACIES. IT SEATS NOBODY. All three winners were already seated by
--   CA_0374 at 2026-11-04 and this file does not touch `office_terms`, `offices` or any term.
--   The occupancy baseline is asserted unmoved (294 / 56 / 238).
--
-- SCOPE, AND WHAT IS DELIBERATELY LEFT OUT. Indiana holds 100 House and 50 Senate offices; AP lists
--   100 House and 25 Senate races for 2026-11-03 and we hold FOUR. This file adds the three that
--   already have a seated winner, because those are the ones where our data currently contradicts
--   itself. ⚠ THE OTHER ~118 INDIANA LEGISLATIVE RACES ARE STILL ABSENT and are a separate pass.
--   Do not read "Indiana now has 7 races" as "Indiana is seeded".
--
-- =============================================================================================
-- WHAT WAS READ, AND WHERE THE TWO SOURCES DISAGREE
-- =============================================================================================
-- Two independent sources, both read 2026-11-12, agreeing on every winner and every finishing
-- order, disagreeing on some counts. Neither is the certified canvass, so every row here is
-- `called`, never `certified` — AP itself reports all three as `isCertified: false`.
--
--   A. AP's PER-STATE feed (the national file does not carry legislative races):
--      https://interactives.apelections.org/election-results/data-live/2026-11-03/results/races/IN/
--      metadata.json + progress.json, last updated by AP 2026-11-06T18:24:39Z.
--   B. The Indiana Election Division's own election-night reporting:
--      https://enr.indianavoters.in.gov/ , office categories 1040 (State Representative) and
--      1018 (State Senator), WriteTime 2026-11-12T15:02Z.
--
-- 🔴🔴 AP REPORTS ZERO VOTES FOR AN UNCONTESTED RACE, AND CALLS IT AT POLL CLOSE. Senate 39 has
--   one candidate; AP gives him `voteCount: 0`, `votePct: 0`, `eevp: 0` and
--   `calledAt: 2026-11-03T23:00:00Z` — the minute the polls shut. The state reports 26,609 votes
--   for the same man. A file that took AP's number would have written a winner with no votes.
--   ⚠ THIS IS ALREADY IN OUR DATA: `CC_0381` recorded House 61's Matt Pierce, also unopposed, with
--   "0 votes, 0%, recorded as won" in his `result_source`. The state gives him 12,939. That row is
--   not touched here — it is a correct call with a wrong count beside it — but it is the same trap
--   and somebody should fix the prose.
--
-- ⚠ HOUSE 45 IS THE ONE RACE WHERE THE TWO SOURCES REALLY DIFFER, and AP is HIGHER even though the
--   state's file is six days newer: Streeter 13,410 (AP) vs 12,691 (state), Mayfield 5,856 vs
--   5,517. Both counts are recorded below. The state ENR is not complete — it reported 4,902 of
--   5,067 precincts statewide when read — and neither source is certified. The margin is about
--   7,000 on either set, and both name the same winner, so the ORDER is not in question. On the
--   other four lines (House 63's two candidates, and Senate 39's winner aside from the zero) the
--   two sources agree exactly or within three votes.
--
-- =============================================================================================
-- THE THREE RACES
-- =============================================================================================
-- `position_name` is the Indiana Election Division's own OFFICE_TITLE, verbatim. That is not a
-- style choice: our four existing Indiana House races carry exactly the state's strings
-- ("State Representative, District 046" and so on), so copying the state keeps one convention.
-- ⚠ THE STATE PADS THE TWO CHAMBERS DIFFERENTLY — the House is three digits ("District 045") and
-- the Senate is two ("District 39"). Normalising them would invent a string the state never
-- published, and `races_election_position_party_unique` makes the string load-bearing.
--
--   House 45   AP 20261103IN15325 · state OFFICEID 2524 · "Called" · isCertified false
--     Kellie E. Streeter (R)          WON   AP 13,410 (69.60%) · state 12,691
--     Rebecca Dawn Mayfield (D)       lost  AP  5,856 (30.40%) · state  5,517
--       ballot name on the state's return is "Rebecca Dawn (Becky) Mayfield"
--   House 63   AP 20261103IN15379 · state OFFICEID 1438 · "Called" · isCertified false
--     Amy Kippenbrock (R)             WON   AP 11,718 (61.03%) · state 11,718
--     Tiffanie Arthur (D)             lost  AP  7,482 (38.97%) · state  7,485
--   Senate 39  AP 20261103IN15157 · state OFFICEID 1128 · "Called" · isCertified false
--     Jeff Ellington (R)              WON   AP 0 (see above) · state 26,609 — UNOPPOSED
--
-- 🔴 SENATE 39'S SINGLE CANDIDATE IS THE BALLOT, NOT A SEEDING GAP, and the next reader will
--   assume otherwise. The Democrats had a candidate and lost him to paperwork: Joseph Baughman
--   won the May primary unopposed and withdrew; a 23 July caucus picked Vincennes mayor Joe
--   Yochum; the 8th District Democratic chair did not file the form the Election Division
--   requires within three days, so Yochum never appeared on the ballot. Indiana Capital
--   Chronicle, "Paperwork snafu leaves Democrats without candidate for Indiana Senate seat",
--   2026-08-12, read in full 2026-11-12. Yochum gets NO row because he was never on this ballot,
--   and Baughman gets none because we hold no 2026 Indiana primary race.
--
-- =============================================================================================
-- PEOPLE
-- =============================================================================================
-- All three WINNERS already exist and are already seated; this file only links candidacies to
-- them. ⚠ AND CA_0374 DID NOT CREATE THEM, THOUGH ITS COMMITTED TEXT SAYS IT WOULD: there are
-- ZERO `politicians` rows with `source LIKE 'CA_0374 %'`. All three are `indiana_discovery` rows
-- created 2026-05-22. The committed CA_0374 carries `reuse_id` NULL for all three, and its own
-- pre-gate RAISES when a same-name person exists under another source — so the file as committed
-- would refuse to run, and what was applied must have had the reuse_ids filled in, exactly as its
-- header instructs. The DATA is right; the FILE is not reproducible as committed. Not fixed here.
--
--   Kellie Streeter       65aadaef-c855-4fb7-907a-b7adae5d9559   holds House 45
--   Amy Kippenbrock       d098cb69-71ae-4710-872d-8d43e3f55158   holds House 63
--   Jeffrey Ellington     6a7a36f8-2fa5-4e1b-bdc6-6df3b63a4ac4   holds Senate 39
--
-- 🔴 THE ELLINGTON LINK IS A NAME MATCH AND THE ROW CARRIES NOTHING ELSE TO CHECK. The ballot
--   says "Jeff Ellington"; our row says "Jeffrey Ellington". That row has no `urls`, no
--   `external_id`, no bio and no photo — a name and a party and nothing more. What the link rests
--   on: he is the ONLY Ellington in our Indiana data (the only other rows matching 'ellington'
--   are two pairs of CAL-ACCESS committee strings for a Theo Ellington in California); the party
--   agrees (Republican on both); and `CA_0374` has already placed that same row in this seat, so
--   linking it makes the candidacy and the term AGREE rather than contradict. ⚠ Linking anyone
--   else would assert that the man who won Senate 39 is not the man holding it. The gate below
--   asserts each winner is the person `office_current_holder` names for that office, which is the
--   claim being made and is testable; control V3 watches it fail.
--   ⚠ Independently, the Indiana Capital Chronicle piece above calls him "Greene County
--   Republican Chair Jeff Ellington", and he is a former member for House 62 (2015–2022) — which
--   CA_0374's own header also notes. Our row holds no trace of that earlier service.
--
-- TWO NEW PEOPLE, both losing candidates, neither previously in our data:
--   Rebecca Dawn Mayfield (D)   House 45
--   Tiffanie Arthur (D)         House 63
-- 🔴 "MAYFIELD" IS A NAMESAKE TRAP IN THIS VERY ELECTION: Peggy Mayfield (R) is the sitting member
--   for House 60 and won it on the same night, and there are four other Mayfields in the table
--   (Debbie, Julie, LaWana). The whole table was searched by surname and by `full_name` before
--   inserting; no Rebecca, Becky or Tiffanie of either surname exists. The pre-gate RAISES rather
--   than guessing if one appears between now and the apply.
-- 🔴 `is_incumbent` is written EXPLICITLY on both inserts, as `false`. It defaults false since
--   CA_0188 and `check:occupancy` fails an INSERT that omits it.
--
-- 🔴 NOBODY ON THESE THREE BALLOTS WAS THE INCUMBENT, so every `race_candidates.is_incumbent` here
--   is false and that is a measured claim, not a default. The three outgoing members were not on
--   the ballot at all: Bruce Borders (House 45) lost the May primary to Streeter, Shane Lindauer
--   (House 63) retired, Eric Bassler (Senate 39) retired. Their terms were closed at 2026-11-03 by
--   CA_0374, so `check:incumbency`'s own predicate — a term covering the election date — is false
--   for every person in this file. The incumbency guard block below asserts it rather than
--   assuming it.
--
-- PRIOR VALUES. 🔴 There are none: this file INSERTS only. No UPDATE, no DELETE, no overwrite of
--   any existing column anywhere. The three offices hold no race in this election today (asserted
--   in the pre-gate), so nothing can be replaced.
--
-- WHAT THE PROGRAMME WILL SHOW AFTERWARDS. The tracker's `in_office` count moves 1 → 4 and the
--   Indiana row of wave 4 gains three races. That is the point of the file: three seats whose
--   holders were already in office become visible to the counts instead of being absent from them.
--   ⚠ The three winners have no headshot and no stance research, so `needs_headshot` and
--   `needs_stances` will each RISE by three. A gap only becomes countable once a winner exists;
--   that rise is the gap being revealed, not created.
--
-- Idempotent: every INSERT is guarded on NOT EXISTS, and the pre-gate refuses a second run that
--   would duplicate a race. Dry-run with:
--   node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0407_in_legislature_three_missing_races.sql

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- The plan.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0407_races ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('30451f34-837d-4474-96b2-b75dfc37f7ad'::uuid, 'State Representative, District 045', '20261103IN15325', '2524'),
  ('705ce366-6fb8-45f1-8424-a37725c1d704'::uuid, 'State Representative, District 063', '20261103IN15379', '1438'),
  ('0e0178dc-ea70-415a-a739-880c33e8c9db'::uuid, 'State Senator, District 39',         '20261103IN15157', '1128')
) v(office_id, position_name, ap_race_id, in_office_id);

-- The ballot, in the state's own order. `person_id` NULL means "insert this person".
CREATE TEMP TABLE cc0407_cands ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('State Representative, District 045', 'Kellie E. Streeter',    'Kellie',   'Streeter',
   'Republican', '65aadaef-c855-4fb7-907a-b7adae5d9559'::uuid, 'won',  '163167',
   'Kellie E. Streeter (GOP) — AP 13,410 votes, 69.60% of the House 45 count; Indiana Election Division 12,691. WON.'),
  ('State Representative, District 045', 'Rebecca Dawn Mayfield', 'Rebecca',  'Mayfield',
   'Democratic', NULL::uuid,                                     'lost', '170686',
   'Rebecca Dawn Mayfield (Dem), on the state''s return as "Rebecca Dawn (Becky) Mayfield" — AP 5,856 votes, 30.40%; Indiana Election Division 5,517. LOST. She is on AP''s and the state''s own candidate list for this race; the loss is not inferred from not being the winner.'),
  ('State Representative, District 063', 'Amy Kippenbrock',       'Amy',      'Kippenbrock',
   'Republican', 'd098cb69-71ae-4710-872d-8d43e3f55158'::uuid, 'won',  '170715',
   'Amy Kippenbrock (GOP) — AP 11,718 votes, 61.03% of the House 63 count; Indiana Election Division 11,718, the same figure. WON.'),
  ('State Representative, District 063', 'Tiffanie Arthur',       'Tiffanie', 'Arthur',
   'Democratic', NULL::uuid,                                     'lost', '170712',
   'Tiffanie Arthur (Dem) — AP 7,482 votes, 38.97%; Indiana Election Division 7,485, three more. LOST. She is on AP''s and the state''s own candidate list for this race; the loss is not inferred from not being the winner.'),
  ('State Senator, District 39',         'Jeff Ellington',        'Jeff',     'Ellington',
   'Republican', '6a7a36f8-2fa5-4e1b-bdc6-6df3b63a4ac4'::uuid, 'won',  '113324',
   'Jeff Ellington (GOP), UNOPPOSED — the only name on this ballot. Indiana Election Division 26,609 votes. AP reports 0 votes and 0% with eevp 0 and called it at poll close, 2026-11-03T23:00:00Z: that is AP''s handling of an uncontested race, NOT a count. The state''s figure is the one to read.')
) v(position_name, full_name, first_name, last_name, party, person_id, result, ap_candidate_id, result_note);

-- ---------------------------------------------------------------------------------------------
-- Pre-gate: the world is still the one this file was written against.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad text; v_n int; v_election uuid;
BEGIN
  SELECT id INTO v_election FROM essentials.elections
   WHERE election_date = DATE '2026-11-03' AND state = 'IN';
  IF v_election IS DISTINCT FROM '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: the 2026-11-03 Indiana election is %, expected 21190350-91e3-4c2c-938d-9cf8f4ac9d5c', coalesce(v_election::text, '(none)');
  END IF;

  -- Each office exists, is an Indiana legislative seat, and carries NO race in this election.
  -- 🔴 That last clause is the whole premise of the file. If it is false, somebody else seeded
  -- these and this file must not add a second race for the same seat.
  SELECT string_agg(s.position_name, '; ') INTO v_bad
    FROM cc0407_races s
   WHERE NOT EXISTS (
           SELECT 1 FROM essentials.offices o
             JOIN essentials.districts d ON d.id = o.district_id
            WHERE o.id = s.office_id
              AND lower(d.state) = 'in'
              AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: not an Indiana legislative office: %', v_bad;
  END IF;

  SELECT string_agg(s.position_name, '; ') INTO v_bad
    FROM cc0407_races s
   WHERE EXISTS (SELECT 1 FROM essentials.races r
                  WHERE r.office_id = s.office_id AND r.election_id = v_election);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: these offices ALREADY carry a race in this election, so the premise of this file is gone: %', v_bad;
  END IF;

  -- The position_name is free. The unique constraint would throw anyway; this says why.
  SELECT string_agg(s.position_name, '; ') INTO v_bad
    FROM cc0407_races s
   WHERE EXISTS (SELECT 1 FROM essentials.races r
                  WHERE r.election_id = v_election AND r.position_name = s.position_name
                    AND r.primary_party IS NULL);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: position_name already used in this election: %', v_bad;
  END IF;

  -- Each named winner exists, under the name this file expects, and holds that very office.
  SELECT string_agg(format('%s -> %s', c.full_name, coalesce(p.full_name, '(no such person)')), '; ')
    INTO v_bad
    FROM cc0407_cands c
    JOIN cc0407_races s ON s.position_name = c.position_name
    LEFT JOIN essentials.politicians p ON p.id = c.person_id
   WHERE c.person_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = s.office_id AND och.politician_id = c.person_id);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: a named winner does not hold the seat this file says they won: %', v_bad;
  END IF;

  -- 🔴 Neither new person may already exist, under any spelling this file can see. Raise rather
  -- than guess: a same-name row may be a different person, and "Mayfield" is a live namesake here.
  SELECT string_agg(format('%s (existing: %s)', c.full_name,
           (SELECT string_agg(p.id::text || ' ' || p.full_name, ', ')
              FROM essentials.politicians p
             WHERE lower(p.first_name) = lower(c.first_name)
               AND lower(p.last_name) = lower(c.last_name))), '; ')
    INTO v_bad
    FROM cc0407_cands c
   WHERE c.person_id IS NULL
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.first_name) = lower(c.first_name)
                    AND lower(p.last_name) = lower(c.last_name));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0407 pre-gate: a losing candidate this file would insert already exists — read the row before reusing it: %', v_bad;
  END IF;

  SELECT count(*) INTO v_n FROM cc0407_cands;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CC_0407 pre-gate: expected 5 candidacies in the plan, found %', v_n; END IF;
END $$;

-- Occupancy snapshot, so the post-gate can prove this file seated nobody.
CREATE TEMP TABLE cc0407_occupancy ON COMMIT DROP AS
SELECT count(*) AS total,
       count(*) FILTER (WHERE o.is_vacant)     AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

CREATE TEMP TABLE cc0407_terms_before ON COMMIT DROP AS
SELECT count(*) AS n FROM essentials.office_terms;

-- ---------------------------------------------------------------------------------------------
-- The two losing candidates, as people.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, party, is_active, is_incumbent, is_appointed, source)
SELECT c.full_name, c.first_name, c.last_name, c.party, true, false, false,
       'CC_0407 ' || c.position_name || ', 2026-11-03 Indiana general: losing candidate, read from the '
       || 'Indiana Election Division''s election-night reporting (enr.indianavoters.in.gov, office '
       || 'category ' || CASE WHEN c.position_name LIKE 'State Senator%' THEN '1018' ELSE '1040' END
       || ', WriteTime 2026-11-12T15:02Z) and from AP''s per-state feed '
       || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/races/IN/, '
       || 'candidate ' || c.ap_candidate_id || '), both read 2026-11-12.'
  FROM cc0407_cands c
 WHERE c.person_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE lower(p.first_name) = lower(c.first_name)
                      AND lower(p.last_name) = lower(c.last_name));

-- Resolve every candidate to a person id.
ALTER TABLE cc0407_cands ADD COLUMN politician_id uuid;

UPDATE cc0407_cands c SET politician_id = c.person_id WHERE c.person_id IS NOT NULL;

UPDATE cc0407_cands c
   SET politician_id = (SELECT p.id FROM essentials.politicians p
                         WHERE lower(p.first_name) = lower(c.first_name)
                           AND lower(p.last_name) = lower(c.last_name)
                           AND p.source LIKE 'CC_0407 %')
 WHERE c.person_id IS NULL;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM cc0407_cands WHERE politician_id IS NULL) THEN
    RAISE EXCEPTION 'CC_0407: a candidate did not resolve to a person: %',
      (SELECT string_agg(full_name, ', ') FROM cc0407_cands WHERE politician_id IS NULL);
  END IF;
END $$;

CREATE TEMP TABLE cc0407_people ON COMMIT DROP AS
SELECT DISTINCT politician_id FROM cc0407_cands;

-- ---------------------------------------------------------------------------------------------
-- The three races.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, s.office_id, s.position_name, NULL, 1
  FROM cc0407_races s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r
                    WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
                      AND r.position_name = s.position_name
                      AND r.primary_party IS NULL);

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼
-- 🔴 This file writes NO office_terms row at all. The block is kept because the guard it feeds is
-- about `race_candidates.is_incumbent` agreeing with `office_terms`, and this file creates five
-- race rows — so it can create exactly the drift the guard exists to catch, without touching a
-- single term. An absent term is as capable of disagreeing with a race row as a new one.

-- @incumbency-decision: gated — creates five race_candidates rows, all is_incumbent = false, on
-- three seats whose outgoing members (Borders, Lindauer, Bassler) were not on the 2026 ballot and
-- whose terms CA_0374 closed at 2026-11-03; no person in this file holds a term covering the
-- election date, so `expected` is false for all five and the stored value matches it.

CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0407_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block: `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column, and CC_0394 turned the "static guards" job red on exactly that. Here `o2` is only ever
-- read for `chamber_id`.
-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- The five candidacies.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at,
   last_verified_at)
SELECT r.id,
       c.politician_id,
       c.full_name,
       c.first_name,
       c.last_name,
       false,
       'active',
       false,
       'CC_0407: Indiana Election Division election-night reporting (enr.indianavoters.in.gov, '
         || 'office category ' || CASE WHEN c.position_name LIKE 'State Senator%' THEN '1018' ELSE '1040' END
         || ', OFFICEID ' || s.in_office_id || ', WriteTime 2026-11-12T15:02Z), cross-checked '
         || 'against AP''s per-state candidate list for race ' || s.ap_race_id
         || ' (candidate ' || c.ap_candidate_id || '). Both read 2026-11-12.',
       c.result,
       'called',
       'CC_0407 — TWO SOURCES, BOTH READ 2026-11-12, NEITHER CERTIFIED. ' || c.result_note
         || ' AP race ' || s.ap_race_id || ' reports raceCallStatus "Called" and isCertified false '
         || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/races/IN/, '
         || 'AP last updated 2026-11-06T18:24:39Z). The Indiana Election Division''s own return is '
         || 'at enr.indianavoters.in.gov, OFFICEID ' || s.in_office_id
         || ', and was still incomplete statewide when read (4,902 of 5,067 precincts). '
         || 'This is a race call and a partial state return, NOT the certified canvass.',
       now(),
       now()
  FROM cc0407_cands c
  JOIN cc0407_races s ON s.position_name = c.position_name
  JOIN essentials.races r ON r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
                         AND r.position_name = c.position_name
                         AND r.primary_party IS NULL
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates x
                    WHERE x.race_id = r.id AND x.politician_id = c.politician_id);

-- ▼▼ BLOCK B — PASTE AFTER YOUR LAST WRITE TO essentials.office_terms, BEFORE COMMIT ▼▼
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0407_people;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES: nobody
  -- you touched has run recently, or your plan table is not the one the scope subquery reads.
  -- Counting the PLAN separately is what tells them apart.
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s)) BEFORE this file',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.politician_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
       AND rc.politician_id IS NOT NULL
       AND rc.politician_id IN (SELECT politician_id FROM cc0407_people)
  )
  SELECT count(*) FILTER (WHERE a.stored IS DISTINCT FROM a.expected),
         0,
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms say %s',
                  coalesce(p.full_name, '(unnamed)'), a.race_candidate_id, a.stored, a.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE a.stored IS DISTINCT FROM a.expected)
    INTO v_created, v_repaired, v_detail
    FROM after_state a
    LEFT JOIN essentials.politicians p ON p.id = a.politician_id;

  -- 🔴 This file ADDS the rows in scope, so "drifted before" cannot apply to them — they did not
  -- exist before. Every disagreement after the write is one this file created.
  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) contradict essentials.office_terms.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;
-- ▲▲ END OF BLOCK B ▲▲

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_won int; v_lost int; v_all int; v_bad text; v_n int;
BEGIN
  -- Exactly three races, on the three offices, each one seat, each a general (no primary_party).
  SELECT count(*) INTO v_n
    FROM essentials.races r JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;
  IF v_n <> 3 THEN RAISE EXCEPTION 'CC_0407 gate: % race(s) on the three offices, expected 3', v_n; END IF;

  SELECT string_agg(r.position_name, '; ') INTO v_bad
    FROM essentials.races r JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND (r.seats <> 1 OR r.primary_party IS NOT NULL OR r.position_name <> s.position_name);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0407 gate: race written wrong: %', v_bad; END IF;

  -- Indiana now holds exactly 7 legislative races in this election: the 4 that existed and these 3.
  SELECT count(*) INTO v_n
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF v_n <> 7 THEN RAISE EXCEPTION 'CC_0407 gate: % Indiana legislative race(s) in this election, expected 7 (4 before + 3 here)', v_n; END IF;

  -- Exactly five candidacies, three won and two lost.
  SELECT count(*) FILTER (WHERE rc.result = 'won'),
         count(*) FILTER (WHERE rc.result = 'lost'),
         count(*)
    INTO v_won, v_lost, v_all
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;
  IF v_all <> 5 OR v_won <> 3 OR v_lost <> 2 THEN
    RAISE EXCEPTION 'CC_0407 gate: % candidacies (% won, % lost), expected 5 (3 won, 2 lost)', v_all, v_won, v_lost;
  END IF;

  -- Every row decided, sourced, called, not an incumbent, and linked to a person.
  SELECT string_agg(rc.full_name, '; ') INTO v_bad
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND (rc.result IS NULL
          OR rc.result_certainty <> 'called'
          OR rc.result_source IS NULL OR btrim(rc.result_source) = ''
          OR rc.source IS NULL OR btrim(rc.source) = ''
          OR rc.is_incumbent
          OR rc.politician_id IS NULL
          OR rc.candidate_status <> 'active');
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0407 gate: candidacy row written wrong: %', v_bad; END IF;

  -- 🔴 NOT ONE OF THESE IS `certified`. The certified count for the whole 2026-11-03 general must
  -- still be the six SC-01/SC-02 rows CC_0406 wrote, repo-wide.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03' AND rc.result_certainty = 'certified';
  IF v_n <> 6 THEN RAISE EXCEPTION 'CC_0407 gate: % certified row(s) in the 2026-11-03 general, expected 6', v_n; END IF;

  -- 🔴 THE WINNER OF EACH RACE IS THE PERSON WHO HOLDS THAT SEAT. This is the claim the file makes
  -- about identity, and it is the only check that can catch a transposed outcome: every other gate
  -- reads the result column beside the name and agrees with itself.
  SELECT string_agg(format('%s won %s but %s holds it', rc.full_name, r.position_name,
                           coalesce((SELECT p.full_name FROM essentials.office_current_holder och
                                       JOIN essentials.politicians p ON p.id = och.politician_id
                                      WHERE och.office_id = r.office_id), '(nobody)')), '; ')
    INTO v_bad
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND rc.result = 'won'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = r.office_id AND och.politician_id = rc.politician_id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0407 gate: a winner is not the holder of the seat: %', v_bad; END IF;

  -- No loser holds any of these three seats.
  SELECT string_agg(rc.full_name, '; ') INTO v_bad
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN cc0407_races s ON s.office_id = r.office_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND rc.result = 'lost'
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = r.office_id AND och.politician_id = rc.politician_id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0407 gate: a loser holds the seat: %', v_bad; END IF;

  -- Exactly two people inserted, both with is_incumbent false and holding no seat.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CC_0407 %';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0407 gate: % person row(s) created, expected exactly 2', v_n; END IF;

  SELECT string_agg(p.full_name, '; ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.source LIKE 'CC_0407 %'
     AND (p.is_incumbent
          OR NOT p.is_active
          OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0407 gate: a created person is flagged or seated wrongly: %', v_bad; END IF;

  -- 🔴 THIS FILE SEATS NOBODY. Not one office_terms row was added, removed or changed.
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> (SELECT n FROM cc0407_terms_before) THEN
    RAISE EXCEPTION 'CC_0407 gate: office_terms moved from % to % — this file must not seat anyone',
      (SELECT n FROM cc0407_terms_before), v_n;
  END IF;

  -- The occupancy drift measurement is unmoved, all three numbers.
  PERFORM 1 FROM cc0407_occupancy b
    JOIN (SELECT count(*) AS total,
                 count(*) FILTER (WHERE o.is_vacant)     AS flagged,
                 count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
            FROM essentials.offices_missing_terms m
            JOIN essentials.offices o ON o.id = m.office_id) a
      ON a.total = b.total AND a.flagged = b.flagged AND a.unflagged = b.unflagged;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0407 gate: the offices_missing_terms measurement moved; it was % / % / %',
      (SELECT total FROM cc0407_occupancy), (SELECT flagged FROM cc0407_occupancy),
      (SELECT unflagged FROM cc0407_occupancy);
  END IF;

  RAISE NOTICE 'CC_0407 OK: 3 races, 5 candidacies (3 won, 2 lost), 2 people created, 0 terms touched';
END $$;

COMMIT;
