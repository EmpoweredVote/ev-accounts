-- CC_0403 - Mississippi, U.S. Senate Class II: record AP's 2026-11-11 call. Scott Colom (Dem)
--           defeats Cindy Hyde-Smith (GOP). The seat flips.
--
-- WHY THIS FILE EXISTS, AND WHY IT IS SEPARATE FROM CC_0402. This is Wave 1 of the transition
--   programme, not the state-legislative tier, and it is ONE RACE whose facts want their own
--   header: a sitting U.S. Senator loses by 4,669 votes. CC_0402 carries 108 rows of
--   state-legislative work written from the same 2026-11-11 feed read and its gates are scoped
--   to STATE_LOWER/STATE_UPPER. Folding this in would have widened every one of them.
--
-- WHAT IT WRITES: 3 existing candidacies UPDATED in 1 race - 1 won, 2 lost, all
--   result_certainty = 'called'. No politician, race, office, district or term is created,
--   deleted or re-seated.
--
--   🔴🔴 RECORDING A RESULT SEATS NOBODY, AND HERE THAT MATTERS MORE THAN USUAL.
--     Cindy Hyde-Smith remains the sitting Senator from Mississippi until 2027-01-03. This file
--     records that she LOST AN ELECTION; it does not end her tenure and it must not touch her
--     incumbency. Two gates hold that: essentials.office_current_holder must still name her for
--     office f6398c92 after the write, and politicians.is_incumbent must read exactly as it did
--     before for all three people. A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT.
--
--   AP race 20261103MS26692, called 2026-11-11T22:58:49.687Z, with 98.73% of the expected vote
--   counted. AP marks the contest flippedSeat = true.
--
--     Scott Colom       Dem  AP id 169318  473,336  49.19%  WON   (winner flag 'X')
--     Cindy Hyde-Smith  GOP  AP id  28529  468,667  48.71%  lost  (AP's incumbent for this seat)
--     Ty Pinkins        Ind  AP id  71873   20,234   2.10%  lost
--
--   Margin 4,669 votes, 0.48 points.
--
-- 🟢 READ TWICE, ON TWO ENDPOINTS, BECAUSE A ONE-RACE FILE HAS NO INTERNAL CROSS-CHECK.
--   AP publishes this contest in BOTH results/national/ and results/races/MS/. Both were
--   fetched on 2026-11-11 and they agree on every field that matters: the same three candidate
--   ids, the same three vote counts, the same percentages, the same winner flag and the same
--   calledAt timestamp to the millisecond. ⚠ That is two reads of one source, not two sources;
--   it rules out a truncated or stale file, not an AP error.
--
-- 🔴 A PLURALITY WINS THIS RACE, AND THE SAME AP FILE PROVES AP KNOWS THE DIFFERENCE. Colom is
--   under 50%, so the first question is whether Mississippi sends this to a runoff. It does not,
--   and the evidence is in the file itself: the MS feed carries 7 races, and TWO of them - the
--   State House District 70 and District 77 unexpired-term contests - carry
--   raceCallStatus = 'Runoff'. AP labels a runoff when there is one, in this very file, and it
--   labels this race 'Called' with raceType 'General'. ▶ A CALL STATUS IS A CLAIM; the control
--   for it is the vocabulary the same source uses elsewhere.
--
-- 🔴 MISSISSIPPI HAS NO RECOUNT, AUTOMATIC OR REQUESTED. Read 2026-11-11 from Ballotpedia's
--   "Recount laws in Mississippi" (ballotpedia.org/Recount_laws_in_Mississippi), opened and read
--   rather than taken from a search summary: "Mississippi law does not provide for automatic or
--   requested recounts." There is therefore no margin threshold that would re-run this count by
--   itself; a court-ordered recount or an election contest is the only route. ⚠ That is a
--   statement about RECOUNTS. It is not a prediction that the number will not move: 1.27% of the
--   expected vote was still outstanding when AP called, and the state has not certified.
--
-- 🔴 PRIOR VALUES, BECAUSE AN UPDATE IS FINAL AND THERE IS NO HISTORY TABLE.
--   All three rows carry result = NULL, result_certainty = NULL and result_source = NULL. There
--   is no citation to preserve on any of them, and a gate asserts that before the write - if a
--   citation has appeared since this file was generated, the run stops rather than erasing it.
--   🟢 THE SCHEMA ALREADY ENFORCES HALF OF THAT, AND THIS FILE'S CONTROLS FOUND IT RATHER THAN
--     ASSUMING IT: race_candidates carries a CHECK named `race_candidates_result_needs_source`,
--     so a result with no citation CANNOT EXIST in this table. The first version of control V8
--     planted a decided-but-uncited row and was rejected by the database before the migration
--     was reached. ▶ "Decided and uncited" is not a state to defend against here; "decided and
--     cited by somebody else" is, and that is what the gate catches.
--
-- NAME MATCHING. All three are exact matches on the full name once case and punctuation are
--   folded, so none of CC_0381's relaxed bases is used here. The incumbent is checked on a
--   second, independent fact as well: AP names candidate 28529 as this seat's incumbent, and
--   essentials.office_current_holder independently names the politician our Hyde-Smith row links
--   to as the holder of the office this race is attached to.
--
-- WHAT THIS DOES TO WAVE 1. The U.S. Senate goes from 33 recorded winners to 34 of 35. The one
--   that remains is ALASKA, which AP still reports 'Too Early to Call' and which is
--   ranked-choice - so it correctly carries no row, and will not be settled by a plurality.
--
-- ▶ 2027-01-03 is the seating date for this seat, and seating is a separate act in a later file.
--
-- 🔴 THIS FILE IS NOT IDEMPOTENT, AND SAYS SO. A second run is REFUSED by the pre-gate with
--   'rows this file writes already carry a decided result', because re-running would append this
--   citation on top of the one it wrote the first time and nothing could undo that.
--
-- SOURCING. AP's own feed, read 2026-11-11. The call is AP's and is labelled as such in the
--   citation; result_certainty = 'called' NEVER 'certified'. AP reports isCertified = false.
--   ⚠ A CALL AND A CANVASS ARE TWO FACTS.
--
-- Slot CC_0403 reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  rc_id            uuid PRIMARY KEY,
  politician_id    uuid NOT NULL,
  our_name         text NOT NULL,   -- as our row reads today
  ap_name          text NOT NULL,   -- as AP prints it
  ap_candidate_id  text NOT NULL,
  party            text NOT NULL,
  votes            int  NOT NULL,
  pct              numeric NOT NULL,
  outcome          text NOT NULL CHECK (outcome IN ('won', 'lost')),
  ap_incumbent     boolean NOT NULL,
  prior_incumbent  boolean NOT NULL  -- politicians.is_incumbent BEFORE this file; must not move
) ON COMMIT DROP;

INSERT INTO called (rc_id, politician_id, our_name, ap_name, ap_candidate_id, party, votes, pct,
                    outcome, ap_incumbent, prior_incumbent) VALUES
  ('17b32590-e015-4bae-8615-099db1c79c8a'::uuid, '4fd59af4-eca7-4cdc-9082-178278ce3dc8'::uuid,
   'Scott Colom', 'Scott Colom', '169318', 'Dem', 473336, 49.19, 'won', false, false),
  ('c54a87d7-6acf-4345-9b21-487159b6cff1'::uuid, '4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid,
   'Cindy Hyde-Smith', 'Cindy Hyde-Smith', '28529', 'GOP', 468667, 48.71, 'lost', true, true),
  ('913f49ba-e5a0-45c6-898d-d253e3f7221e'::uuid, 'f162d87e-45fa-44fb-bbd4-b5df5751239b'::uuid,
   'Ty Pinkins', 'Ty Pinkins', '71873', 'Ind', 20234, 2.10, 'lost', false, false);

CREATE TEMP TABLE before_image AS
  SELECT rc.id AS rc_id, rc.result, rc.result_source, rc.result_certainty, rc.full_name,
         rc.is_incumbent AS rc_incumbent
    FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;

-- 🔴 OCCUPANCY IS SNAPSHOT FOR EVERY OFFICE ANY OF THESE THREE PEOPLE HOLDS, not only the seat
--    the race is attached to. Scott Colom also occupies a 'Candidate for U.S. Senate' placeholder
--    office row, and a file that only watched the real seat would not have seen that move.
CREATE TEMP TABLE occupancy_before AS
  SELECT och.office_id, och.politician_id
    FROM essentials.office_current_holder och
   WHERE och.office_id IN (SELECT r.office_id FROM essentials.races r JOIN essentials.race_candidates rc ON rc.race_id = r.id JOIN called c ON c.rc_id = rc.id)
      OR och.politician_id IN (SELECT politician_id FROM called);

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  -- 🔴 unaccent is NOT installed on prod. Fold in the application's own terms.
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçÝý',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCcYy')),
           '[^A-Z0-9]', '', 'g')
$f$;

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 measured candidacies, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'won';
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 winner, the file carries %', n; END IF;

  -- POSITIVE CONTROL. A "no mismatch found" is vacuous if the comparison sees nothing at all.
  PERFORM 1 FROM essentials.race_candidates
   WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Cindy Hyde-Smith');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist - every name gate below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM before_image;
  IF n <> 3 THEN RAISE EXCEPTION 'the before-image sees % of the 3 rows this file names - a gate that reads the wrong rows proves nothing', n; END IF;

  -- 🔴 EVERY ROW IS ADDRESSED BY uuid AND THE NAME BESIDE IT DOES NOT FIND IT.
  SELECT count(*) INTO n FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% pinned candidacies do not exist', n; END IF;
  SELECT string_agg(c.our_name || ' <> ' || rc.full_name, ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.our_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned rows do not carry the name this file states: %', txt; END IF;
  SELECT string_agg(c.our_name, ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.politician_id IS DISTINCT FROM c.politician_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned rows do not link to the politician this file states: %', txt; END IF;

  -- all three must sit in ONE race, and it must be the 2026-11-03 Mississippi U.S. Senate race
  SELECT count(DISTINCT rc.race_id) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;
  IF n <> 1 THEN RAISE EXCEPTION 'the 3 pinned rows sit in % races, not 1', n; END IF;
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03' OR d.district_type <> 'NATIONAL_UPPER' OR lower(d.state) <> 'ms';
  IF n <> 0 THEN RAISE EXCEPTION '% pinned rows are not in the 2026-11-03 Mississippi U.S. Senate race', n; END IF;

  -- 🔴 ONE WINNER BECAUSE races.seats SAYS ONE, read from production rather than assumed.
  SELECT r.seats INTO n FROM essentials.races r
   WHERE r.id = (SELECT DISTINCT rc.race_id FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id);
  IF n <> 1 THEN RAISE EXCEPTION 'production says this race fills % seats, this file records 1 winner', n; END IF;

  -- 🔴🔴 THE WINNER MUST BE THE TOP VOTE-GETTER. The only gate that can catch a transposed win,
  --   because every other check reads the outcome column beside the name. AP publishes the
  --   winner FLAG and the VOTE COUNT as independent fields.
  SELECT string_agg(x.our_name, ', ') INTO txt FROM (
    SELECT c.our_name, c.outcome, rank() OVER (ORDER BY c.votes DESC) AS vote_rank FROM called c
  ) x WHERE (x.outcome = 'won') <> (x.vote_rank = 1);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the row marked won is not the top vote-getter: %', txt; END IF;

  -- 🔴 NOTHING THIS FILE WRITES MAY ALREADY BE DECIDED, AND NOTHING MAY ALREADY BE CITED.
  SELECT string_agg(b.full_name || ' = ' || b.result, ', ') INTO txt
    FROM before_image b WHERE b.result IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows this file writes already carry a decided result: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result_certainty IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% rows this file writes already carry a certainty', n; END IF;
  SELECT string_agg(b.full_name, ', ') INTO txt FROM before_image b WHERE coalesce(b.result_source, '') <> '';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a citation has appeared since this file was generated and would be destroyed: %', txt; END IF;

  -- 🔴 AP'S INCUMBENT MUST BE OUR SEAT HOLDER. Two facts, neither of them a name: AP flags
  --   candidate 28529 as this seat's incumbent, and our own view must name the politician that
  --   row links to as the holder of the office this race is attached to.
  SELECT count(*) INTO n FROM called WHERE ap_incumbent;
  IF n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 AP incumbent on this ballot, the file carries %', n; END IF;
  PERFORM 1
     FROM called c
     JOIN essentials.race_candidates rc ON rc.id = c.rc_id
     JOIN essentials.races r ON r.id = rc.race_id
     JOIN essentials.office_current_holder och ON och.office_id = r.office_id
    WHERE c.ap_incumbent AND och.politician_id = c.politician_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'AP''s incumbent for this seat is not the politician our own view names as its holder'; END IF;

  -- and our own incumbency flags must be exactly what the header says they are, before the write
  SELECT string_agg(c.our_name || ': file says ' || c.prior_incumbent || ', production says ' || p.is_incumbent, ', ') INTO txt
    FROM called c JOIN essentials.politicians p ON p.id = c.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM c.prior_incumbent;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'incumbency flags are not what this file recorded: %', txt; END IF;

  RAISE NOTICE 'pre-checks passed: 3 candidacies in 1 race, 1 won, 2 lost';
END $$;

-- ─── 3. The write ───
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Associated Press race call for the 2026-11-03 general election, read '
         || '2026-11-11 from AP''s own results feed, in BOTH '
         || 'interactives.apelections.org/election-results/data-live/2026-11-03/results/national/ '
         || 'and .../results/races/MS/ (race 20261103MS26692, candidate ' || c.ap_candidate_id
         || '), which agree on every field: ' || c.ap_name || ' (' || c.party || ') '
         || c.votes || ' votes, ' || c.pct || '%, recorded as ' || c.outcome
         || '. AP called the race at 2026-11-11T22:58:49.687Z for Scott Colom with 98.73% of the '
         || 'expected vote counted, a margin of 4,669 votes (0.48 points), and marks the contest '
         || 'flippedSeat = true. Mississippi elects a U.S. Senator by plurality, and AP labels a '
         || 'runoff as such in this same file (two Mississippi State House unexpired-term races '
         || 'carry raceCallStatus = ''Runoff''); this race carries ''Called'' and raceType '
         || '''General''. Mississippi law provides for no recount, automatic or requested '
         || '(ballotpedia.org/Recount_laws_in_Mississippi, read 2026-11-11). This is AP''s call '
         || 'and NOT the state canvass; AP reports isCertified = false. RECORDING A RESULT SEATS '
         || 'NOBODY - the winner takes office 2027-01-03 and Cindy Hyde-Smith holds the seat '
         || 'until then.',
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result = c.outcome AND rc.result_certainty = 'called';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 rows written, % carry the outcome this file states', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE position('20261103MS26692' in coalesce(rc.result_source, '')) = 0;
  IF n <> 0 THEN RAISE EXCEPTION '% written rows do not name the AP race they came from', n; END IF;

  -- 🔴🔴 RECORDING A RESULT SEATS NOBODY. Cindy Hyde-Smith is still the Senator from Mississippi.
  SELECT count(*) INTO n FROM occupancy_before;
  IF n = 0 THEN RAISE EXCEPTION 'the occupancy snapshot is empty - the comparison below would pass vacuously'; END IF;
  SELECT string_agg(x.office_id::text, ', ') INTO txt FROM (
    SELECT coalesce(b.office_id, a.office_id) AS office_id
      FROM occupancy_before b
      FULL OUTER JOIN (
        SELECT och.office_id, och.politician_id
          FROM essentials.office_current_holder och
         WHERE och.office_id IN (SELECT office_id FROM occupancy_before)
      ) a ON a.office_id = b.office_id
     WHERE a.office_id IS NULL OR b.office_id IS NULL
        OR a.politician_id IS DISTINCT FROM b.politician_id
  ) x;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the current officeholder changed for office(s) % - this file seats nobody', txt; END IF;
  PERFORM 1 FROM essentials.office_current_holder och
   WHERE och.office_id = 'f6398c92-57e8-4e45-9a4b-0131bf40e332'
     AND och.politician_id = '4d83f985-9248-4905-a9b6-5742e2df77a8';
  IF NOT FOUND THEN RAISE EXCEPTION 'Cindy Hyde-Smith no longer holds the Mississippi Senate seat - this file records a defeat, it does not end a tenure'; END IF;

  -- 🔴 AND IT MOVES NO INCUMBENCY FLAG. A losing incumbent is still the incumbent until January.
  SELECT string_agg(c.our_name, ', ') INTO txt
    FROM called c JOIN essentials.politicians p ON p.id = c.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM c.prior_incumbent;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'politicians.is_incumbent moved for %', txt; END IF;
  SELECT string_agg(b.full_name, ', ') INTO txt
    FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE rc.is_incumbent IS DISTINCT FROM b.rc_incumbent;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'race_candidates.is_incumbent moved for %', txt; END IF;

  -- the wave's own number: 33 recorded U.S. Senate winners before this file, 34 after.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'NATIONAL_UPPER' AND rc.result = 'won';
  IF n <> 34 THEN RAISE EXCEPTION 'expected 34 U.S. Senate winners after this file, found %', n; END IF;

  -- 🔴 THE OCCUPANCY DRIFT BASELINE. This file creates no office.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;

  RAISE NOTICE 'CC_0403 done: Colom won, Hyde-Smith and Pinkins lost; U.S. Senate now 34 of 35 recorded; occupancy % / % / %', total, flagged, unflagged;
END $$;

DROP TABLE IF EXISTS before_image;
DROP TABLE IF EXISTS occupancy_before;

COMMIT;
