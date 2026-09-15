BEGIN;

-- =============================================================================
-- CA_0116: Brown County (IN) Auditor — the 2026 primary race and its two candidates
-- =============================================================================
-- Created 2026-09-15.
--
-- WHAT THIS ADDS
-- One race under the existing 2026 Indiana Primary election
-- (09fc1b7b-e916-4fc7-ad6b-944fde52cbd2, IN, 2026-05-05), plus the two Republican
-- candidates who contested it and the politician rows behind them.
--
-- WHY IT EXISTS
-- on-the-record holds a repaired hour-long LWV Brown County candidate forum for
-- this exact office (meeting 2026-04-03-lwv-brown-county-candidate-forum-auditor).
-- It CANNOT be published without these rows: src/publish.py::_reconcile_event_races
-- refuses any meeting of kind 'forum' or 'debate' that resolves to zero races, and
-- it resolves them purely from essentials.race_candidates.politician_id of the
-- meeting's linked speakers. No race, no publish. That forum has sat un-publishable
-- since 2026-06-28 for this reason.
--
-- WHY BROWN COUNTY, WHEN THE OTHER 38 RACES IN THIS ELECTION ARE MONROE COUNTY
-- Deliberate, and the policy is: COVERAGE FOLLOWS CONTENT. A race is created when
-- substantive candidate content has actually been captured for it — which is what
-- already happened for Monroe County, where the races exist because the council
-- meetings do. It carries NO commitment to cover Brown County as an ongoing beat.
-- County Auditor is not a new office type here either: Salt Lake County Auditor,
-- Utah County Auditor and Kitsap County Auditor are all already in the corpus.
--
-- NAMES ARE VERIFIED, NOT TRANSCRIBED. The pipeline's ASR renders the second
-- candidate variously as "Teresa Kobian", "Miss Cobian" and "Ms. Kobe", and the
-- first as "Candy Boone". Both spellings below come from the Brown County Democrat's
-- primary result report (bcdemocrat.com/2026/05/15/rudd-bond-and-wert-win-contested-
-- brown-county-primary-races/, fetched 2026-09-15): Andy Vasquez Bond 931,
-- Theresa Cobian 677. Do not "correct" them back toward the transcript.
--
-- 🔴 BOND ALREADY EXISTS — DO NOT MINT A SECOND ROW FOR HER.
-- essentials.politicians ad8edb9f-91dd-47a9-a564-b200f0eba0d1, full_name "Andy V
-- Bond", slug 'andy-vasquez-bond', source 'ballotready', is_incumbent=true. A
-- name search for "Vasquez Bond" does NOT find her, because BallotReady stored the
-- middle name as an initial while deriving the slug from the full form — which is
-- how she stayed invisible until the post-verify gate below caught it. She has
-- ZERO race edges and ZERO quotes today, so she is an orphan row: present, but
-- attached to nothing. This migration attaches her. Both INSERTs below are guarded
-- on slug, so on production the Bond insert is a deliberate no-op.
--
-- HER is_incumbent=true IS LEFT ALONE. It is BallotReady's statement that she
-- currently holds office, which is TRUE — she is the sitting county treasurer. It
-- is not a claim about this race, and flipping a live ballotready-sourced row to
-- suit a race edge is how the is_active/reps-feed incident happened. The
-- incumbency assertion in the gate below therefore covers only Cobian, the row
-- this migration actually creates. essentials.politicians.is_incumbent DEFAULTS TO
-- **true** (unlike race_candidates.is_incumbent, which defaults to false), so
-- Cobian's insert sets it explicitly: she is staff in the Auditor's office, not an
-- officeholder, and the default would publish a false incumbency claim.
--
-- race_candidates.full_name copies the politician row verbatim so the two cannot
-- drift. That means Bond's candidacy reads "Andy V Bond", not the fuller "Andy
-- Vasquez Bond" the county prints. Correcting the politician row is a rename of a
-- live ballotready-sourced record and belongs in its own migration, not here.
--
-- WHY `result` IS LEFT NULL even though the primary is decided
-- Every one of the 590 populated race_candidates.result rows in this database cites
-- a CERTIFIED CANVASS in result_source — a Secretary of State statement of vote, a
-- county registrar's certified tally. The only source in hand here is a newspaper
-- report. That is good enough to spell a name and nowhere near good enough to record
-- an election result, and this migration is not the place to lower that bar. Fill it
-- in a later migration once the Brown County certified canvass is in hand.
-- =============================================================================

-- The race. position_name is the join key humans read; there is no natural unique
-- constraint on (election_id, position_name), so the guard is an explicit NOT EXISTS.
INSERT INTO essentials.races (election_id, position_name, primary_party, seats)
SELECT '09fc1b7b-e916-4fc7-ad6b-944fde52cbd2', 'Brown County Auditor', 'Republican', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races
   WHERE election_id = '09fc1b7b-e916-4fc7-ad6b-944fde52cbd2'
     AND position_name = 'Brown County Auditor'
);

-- The politicians. source/slug/is_active follow the Monroe County rows already in
-- this election (source 'indiana_primary_2026', a kebab slug, no synthetic
-- external_id) so the whole Indiana set stays one shape.
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, party, source, slug, is_incumbent, is_active)
SELECT 'Andy Vasquez Bond', 'Andy', 'Vasquez Bond', 'Republican',
       'indiana_primary_2026', 'andy-vasquez-bond', false, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE slug = 'andy-vasquez-bond');

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, party, source, slug, is_incumbent, is_active)
SELECT 'Theresa Cobian', 'Theresa', 'Cobian', 'Republican',
       'indiana_primary_2026', 'theresa-cobian', false, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE slug = 'theresa-cobian');

-- The candidacies. politician_id is the column publish.py resolves races through,
-- so a row without it would leave the forum exactly as un-publishable as before.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name,
   is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name,
       false, 'active', 'indiana_primary_2026'
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.politicians p ON p.slug IN ('andy-vasquez-bond', 'theresa-cobian')
 WHERE e.id = '09fc1b7b-e916-4fc7-ad6b-944fde52cbd2'
   AND r.position_name = 'Brown County Auditor'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.race_candidates rc
      WHERE rc.race_id = r.id AND rc.politician_id = p.id
   );

DO $$
DECLARE
  v_race uuid;
  v_n    int;
BEGIN
  SELECT id INTO v_race FROM essentials.races
   WHERE election_id = '09fc1b7b-e916-4fc7-ad6b-944fde52cbd2'
     AND position_name = 'Brown County Auditor';
  IF v_race IS NULL THEN
    RAISE EXCEPTION 'CA_0116: the Brown County Auditor race was not created';
  END IF;

  -- Exactly one race: a second would split the forum's speakers across two races
  -- and publish the meeting under both.
  SELECT count(*) INTO v_n FROM essentials.races
   WHERE election_id = '09fc1b7b-e916-4fc7-ad6b-944fde52cbd2'
     AND position_name = 'Brown County Auditor';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0116: expected 1 Brown County Auditor race, found %', v_n;
  END IF;

  -- Exactly two candidacies, both carrying a politician_id. Without that column
  -- publish.py resolves no race and the forum stays blocked — the one failure this
  -- migration exists to prevent, so it is asserted rather than assumed.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE race_id = v_race AND politician_id IS NOT NULL;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0116: expected 2 linked candidacies, found %', v_n;
  END IF;

  -- Cobian must not claim incumbency: politicians.is_incumbent defaults to TRUE,
  -- and she is staff in the Auditor's office, not an officeholder. Bond is
  -- deliberately excluded — her is_incumbent=true is BallotReady's true statement
  -- that she is the sitting county treasurer, and is not this migration's to flip.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE slug = 'theresa-cobian' AND is_incumbent;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0116: Cobian defaulted to is_incumbent=true';
  END IF;

  -- Exactly one Bond row. Two would strand her forum quotes on whichever row has
  -- no race edge, which is invisible in Read & Rank rather than merely wrong.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE slug = 'andy-vasquez-bond';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0116: expected exactly 1 Andy Bond row, found %', v_n;
  END IF;

  -- Both politician rows exist exactly once; a duplicate slug would strand quotes
  -- on the row that has no race edge.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE slug IN ('andy-vasquez-bond', 'theresa-cobian');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0116: expected 2 politician rows for these slugs, found %', v_n;
  END IF;

  -- result stays NULL until a certified canvass backs it.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE race_id = v_race AND result IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0116: % result(s) recorded without a certified canvass', v_n;
  END IF;

  RAISE NOTICE 'CA_0116 OK — Brown County Auditor staged (1 race, 2 linked candidacies, Bond reused from ballotready with her is_incumbent untouched, Cobian created with is_incumbent=false, result NULL pending certified canvass)';
END $$;

COMMIT;
