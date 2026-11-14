-- CC_0425: Wood Village, Oregon -- map our two council seats onto the city's own numbering, and
--          seed the 2026-11-03 ballot. The last two of the 50 empty races.
--
-- ▶ APPLY CC_0424 FIRST. Its gate clears Wisconsin; this file's last gate asserts that NO race
--   anywhere carries an empty ballot for 2026-11-03, which is only true once both have run.
--
-- CC_0423 deliberately left these two rows alone and said why: "two rows, two unknowns, and no
-- mapping that would not be a guess". The unknowns were real. The city's own charter and roster
-- answer all of them, and they turn out to answer a different question than the one that was asked.
--
-- === WHAT THE CITY SAYS ===
-- Charter Chapter III (current as amended 2015-05-19; committed under
-- backend/data/local-races-2026-audit/sources/or-wood-village-charter-2026-11-14.txt):
--   Section 8.  "The council shall be composed of five councilors elected from the city at large."
--   Section 9.  "Councilors shall be elected at the biennial general election for a term of office
--                of four years. Terms shall be staggered so that three councilors are elected at
--                one general election and two at next general election."
--   Section 10. "The council, from its members shall elect a mayor at the first meeting of the
--                council in each odd numbered year for a term of two years."
--   Section 25. "The term of office of a person elected at a regular city election shall commence
--                the first of the year immediately following the election."
-- The council roster at woodvillageor.gov, retrieved 2026-11-14, lists five people:
--   Jairo Rios-Campos  Mayor              term ends 12/31/2028
--   Dara Tan           Council President  term ends 12/31/2028
--   John Miner                            term ends 12/31/2026
--   Charlene Gothard                      term ends 12/31/2026
--   Patricia Smith                        term ends 12/31/2028
--
-- === THE THREE UNKNOWNS, ANSWERED ===
--
-- 1. "WE HOLD 2 OFFICES FOR A COUNCIL THAT NUMBERS AT LEAST 4 POSITIONS." We do not. We hold FIVE
--    offices in this chamber and the charter prescribes FIVE councilors; our roster and the city's
--    are the same five people. The appearance of a gap came from looking only at the two offices
--    that carried an empty race.
--
-- 2. "OUR SEAT 1'S HOLDER JOHN MINER WAS MADE MAYOR BY THE COUNCIL IN JANUARY 2023, WHICH EATS A
--    COUNCIL SEAT." Both halves are true and they do not conflict. Section 10 has the council
--    elect a mayor FROM ITS MEMBERS at the first meeting of each odd-numbered year for two years,
--    so January 2023 is exactly when a mayor is chosen, and the office is a chair a sitting
--    councilor holds -- it eats nothing. That mayoralty ran to early 2025, when Rios-Campos took
--    it; Miner is a plain councilor now and the city lists him as one.
--    🔴 A ROTATING CHAIR DOES NOT ALWAYS EAT A SEAT, AND WHICH IT DOES IS A COUNTING QUESTION.
--      In the Maine cities a phantom "Mayor" office consumed one of the council's seats because
--      the body's size was already accounted for. Here five offices hold five councilors, so the
--      chair costs nothing. ▶ Count the body before concluding the chair is a phantom.
--    WARNING: our office TITLES still read "Mayor" and "Council President" for two of the five,
--      and under this charter neither is a separately elected seat -- all five are councilors.
--      That is a labelling defect on offices this migration does not touch, and it is left to its
--      own pass rather than widened into this one. It changes no race and no occupancy.
--
-- 3. "OUR SEAT 2'S HOLDER CHARLENE GOTHARD IS ON THE BALLOT FOR THE CITY'S POSITION 1, SO OUR
--    NUMBERING IS NOT THE CITY'S." Correct, and that mismatch is what identifies the mapping
--    rather than what blocks it:
--      (a) Section 9 staggers five seats three-and-two, so this cycle elects two.
--      (b) The roster says exactly two terms end 12/31/2026 -- Miner's and Gothard's. The charter
--          predicts the count and the roster supplies the names; two independent things agreeing.
--      (c) Multnomah County's export carries exactly two Wood Village contests, Councilor
--          Position 1 and Councilor Position 4.
--      (d) Gothard, a sitting councilor whose term ends this year, is the candidate for Position
--          1. A numbered at-large position is the ballot's label for one seat, so the seat she
--          holds IS Position 1 -> our "Seat 2" is the city's Position 1.
--      (e) Two expiring seats, two contests, one of them identified: by elimination Miner's seat
--          is Position 4, where Christine Bierman stands unopposed and Miner does not stand at all.
--    🟢 The charter also predicts a NEGATIVE that the ballot confirms: because the mayor is chosen
--      by the council, there can be no mayoral contest, and the export carries none. A rule that
--      says which contests must be ABSENT is worth more than one that only says what may appear --
--      the same shape as Wis. Stat. 59.20 predicting Racine's missing Register of Deeds.
--
-- === WHAT THIS MIGRATION OVERWRITES ===
-- 🔴 The two races are RENAMED, and there is no history table for races.position_name, so the old
--    values are recorded here and nowhere else:
--      2f0f5ed0-b654-47eb-8a43-9074847bb097  'Wood Village City Council Seat 1' -> 'Wood Village City Council Position 4'
--      9ab007a0-2f9a-4247-a8bf-9fcc8705eb15  'Wood Village City Council Seat 2' -> 'Wood Village City Council Position 1'
--    Our "Seat N" labels name seats the city does not have, and a voter reading one of these rows
--    would be shown a number that was on no ballot. The office rows these races point at do not
--    move: Gothard's office keeps the contest Gothard stood in, Miner's keeps the other.
--
-- === RESULTS ===
-- Multnomah County export, pulled 2026-11-13, committed as
-- sources/or-multnomah-export-2026-11-13.csv:
--   Councilor, Position 1   Charlene Gothard  802   write-in 32
--   Councilor, Position 4   Christine Bierman 810   write-in 28
-- Both are FORCED on CC_0423's test: the ballot carried no more names than seats, and the whole
-- aggregate write-in line read as if it were one person still loses to the named candidate. Oregon
-- publishes no winner flag, so forced arithmetic is the basis, exactly as for that wave's other 8.
--
-- WARNING: no politician is created or linked. politician_id stays NULL, matching CC_0423. Under
--   Charter Section 25 these terms begin 2027-01-01; seating the two winners is a separate act,
--   and Bierman is a new person who will need one.

BEGIN;

-- 1. Rename the two races to the numbering the city and the ballot actually use.
UPDATE essentials.races
   SET position_name = 'Wood Village City Council Position 4'
 WHERE id = '2f0f5ed0-b654-47eb-8a43-9074847bb097'
   AND position_name = 'Wood Village City Council Seat 1';

UPDATE essentials.races
   SET position_name = 'Wood Village City Council Position 1'
 WHERE id = '9ab007a0-2f9a-4247-a8bf-9fcc8705eb15'
   AND position_name = 'Wood Village City Council Seat 2';

-- 2. Seed the ballot.
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, external_id, source,
   result, result_source, result_certainty)
VALUES
  -- Position 1 -- Gothard's own seat, she stood for it, unopposed.
  ('9ab007a0-2f9a-4247-a8bf-9fcc8705eb15', 'Charlene Gothard', 'Charlene', 'Gothard', true, 'active',
   'or-2026-11-03-wood-village-city-council-position-1-charlene-gothard',
   'Oregon Secretary of State, 2026-11-03 General Election county results export (Multnomah)',
   'won',
   'Oregon Secretary of State, 2026-11-03 General Election county results export (Multnomah); the ballot carried no more candidates than seats and the aggregate write-in line did not exceed the lowest named winner',
   'called'),
  -- Position 4 -- the seat John Miner is leaving; he is on no line of this ballot.
  ('2f0f5ed0-b654-47eb-8a43-9074847bb097', 'Christine Bierman', 'Christine', 'Bierman', false, 'active',
   'or-2026-11-03-wood-village-city-council-position-4-christine-bierman',
   'Oregon Secretary of State, 2026-11-03 General Election county results export (Multnomah)',
   'won',
   'Oregon Secretary of State, 2026-11-03 General Election county results export (Multnomah); the ballot carried no more candidates than seats and the aggregate write-in line did not exceed the lowest named winner',
   'called')
-- The unique index on external_id is PARTIAL, so the conflict target repeats its predicate.
ON CONFLICT (external_id) WHERE external_id IS NOT NULL DO NOTHING;

DO $$
DECLARE
  v_rows int; v_won int; v_named int; v_empty_all int; v_unflagged int; v_old int;
BEGIN
  SELECT count(*) INTO v_rows FROM essentials.race_candidates
   WHERE external_id LIKE 'or-2026-11-03-wood-village-%';
  IF v_rows <> 2 THEN RAISE EXCEPTION 'CC_0425: % Wood Village candidacies, expected 2.', v_rows; END IF;

  SELECT count(*) FILTER (WHERE result = 'won' AND result_certainty = 'called') INTO v_won
    FROM essentials.race_candidates WHERE external_id LIKE 'or-2026-11-03-wood-village-%';
  IF v_won <> 2 THEN RAISE EXCEPTION 'CC_0425: % won/called rows, expected 2.', v_won; END IF;

  -- Both races carry the city's numbering, and neither keeps a "Seat N" name.
  SELECT count(*) INTO v_named FROM essentials.races
   WHERE id IN ('2f0f5ed0-b654-47eb-8a43-9074847bb097','9ab007a0-2f9a-4247-a8bf-9fcc8705eb15')
     AND position_name IN ('Wood Village City Council Position 4','Wood Village City Council Position 1');
  SELECT count(*) INTO v_old FROM essentials.races
   WHERE position_name LIKE 'Wood Village City Council Seat%';
  IF v_named <> 2 OR v_old <> 0 THEN
    RAISE EXCEPTION 'CC_0425: % races renamed and % still named "Seat N", expected 2 and 0.', v_named, v_old;
  END IF;

  -- 🔴 THE MAPPING IS THE CLAIM, SO GATE ON IT. Gothard's candidacy must sit on the race attached
  --    to the office GOTHARD HOLDS, and Position 4 on the office JOHN MINER holds. If the two
  --    races had been mapped the other way round, both of these fail.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE rc.external_id = 'or-2026-11-03-wood-village-city-council-position-1-charlene-gothard'
       AND r.position_name = 'Wood Village City Council Position 1'
       AND p.full_name = 'Charlene Gothard'
  ) THEN RAISE EXCEPTION 'CC_0425: Position 1 is not on the office Charlene Gothard holds.'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE rc.external_id = 'or-2026-11-03-wood-village-city-council-position-4-christine-bierman'
       AND r.position_name = 'Wood Village City Council Position 4'
       AND p.full_name = 'John Miner'
  ) THEN RAISE EXCEPTION 'CC_0425: Position 4 is not on the office John Miner holds.'; END IF;

  -- No citation may carry a vote count (CC_0423's rule).
  IF EXISTS (SELECT 1 FROM essentials.race_candidates
              WHERE external_id LIKE 'or-2026-11-03-wood-village-%' AND result_source ~ '[0-9][0-9,]* votes') THEN
    RAISE EXCEPTION 'CC_0425: a result_source carries a vote count.';
  END IF;

  -- 🟢 The point of the whole wave: NOT ONE race anywhere still carries an empty ballot for
  --    2026-11-03. Requires CC_0424 to have run.
  SELECT count(*) INTO v_empty_all
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = '2026-11-03'
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id);
  IF v_empty_all <> 0 THEN
    RAISE EXCEPTION 'CC_0425: % races for 2026-11-03 still carry no candidate (apply CC_0424 first).', v_empty_all;
  END IF;

  -- Recording a ballot seats nobody.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN RAISE EXCEPTION 'CC_0425: drift baseline reads %, not 238.', v_unflagged; END IF;

  RAISE NOTICE 'CC_0425 OK: 2 Wood Village candidacies, both won/called, races renamed to Positions 1 and 4, ZERO empty 2026-11-03 races left, drift baseline 238.';
END $$;

COMMIT;
