-- CC_0380 — 2026-11-03 Los Angeles Mayor: record the result on AP's call.
--           This file is a CORRECTION of a claim CC_0379 made about the world.
--
-- 🔴🔴 CC_0379 SAID "AP WOULD CALL THIS RACE. WE HAVE NO CALLER." THE SECOND HALF WAS FALSE,
--   AND IT WAS FALSE WHEN IT WAS WRITTEN. AP's own feed carries **nine mayoral races** under
--   `officeID: "M"`, the Los Angeles mayoralty among them, and it had called it at
--   **2026-11-05T19:49:13Z** — three days before CC_0379 was applied. The absence of a caller
--   was asserted, not checked, against a feed this repo already reads for every federal and
--   state-executive result.
--   ▶ **AN ABSENCE YOU DID NOT LOOK FOR IS NOT A FINDING.** The same rule the 96 cancelled
--     school elections were held to — run the check from the source's own catalogue — was not
--     applied to the source we use most.
--   ⚠ Nothing CC_0379 WROTE was wrong: the City Attorney row stands, and the three it held
--     back were correctly held under the rule it was applying. Only its reason for holding
--     the mayoralty was wrong, and this file supplies the right one.
--
-- WHAT IT WRITES: 2 existing candidacies UPDATED in 1 race — 1 won, 1 lost, `called`.
--   Both prior values are NULL in all four result columns; the gate refuses anything else.
--
--   Los Angeles Mayor   🏆 Nithya Raman 579,501 (54.46%)
--                          Karen Ruth Bass 484,580 (45.54%) — INCUMBENT, DEFEATED
--
-- 🔴 THE BASIS IS AP'S WINNER FLAG, exactly as CC_0339 (Senate), CC_0350 (House) and
--   CC_0357 (state executives) used it. This is NOT a new kind of evidence and NOT a
--   loosening of the outstanding-ballot bound that CC_0377–CC_0379 apply. The bound exists
--   *because* those contests have no caller; this one does, so the bound is not the test.
--   AP race `20261103CA84303` · `raceCallStatus: "Called"` · winner `X` on candidate 172807
--   (Nithya Raman) · `calledAt` 2026-11-05T19:49:13.308Z · eevp 91.77 · `isCertified: false`.
--   Extract committed: backend/data/ca-la-city-2026-results/ap-national-{metadata,progress}-2026-11-08.json
--
-- 🟢 TWO INDEPENDENT SOURCES AGREE ON THE NUMBERS TO THE VOTE. AP publishes 579,501 and
--   484,580; the Los Angeles County RR/CC feed that CC_0379 read publishes 579,501 and
--   484,580. AP is not reading our extract and we are not reading AP's — they agree because
--   both are reading the county.
--
-- ⚠ KAREN BASS CONCEDED ON 2026-11-05, and that is CORROBORATION, NOT THE BASIS. A concession
--   is a statement by a candidate, not a count and not a call; this repo records `called` from
--   a caller. Her statement — "I have called Councilmember Nithya Raman to congratulate her on
--   her victory" — is consistent with AP's call and with the count, and is recorded here
--   because it explains why the question was asked, not because anything rests on it.
--
-- 🔴 THE OTHER THREE LOS ANGELES CITY RACES STAY NULL. AP's `officeID: "M"` is mayors only —
--   it carries no city attorney and no council race — so Council Districts 3 and 9 have no
--   caller and remain under the bound (margins 1,869 and 417, bounds 10,080 and 5,094).
--   The City Attorney already carries CC_0379's result.
--   ⚠ We hold 19 mayoral races on this ballot and AP carries 9; **the Los Angeles mayoralty is
--     the only one in both sets.** AP's other eight are cities we hold no race for at all —
--     a seeding gap, reported and not acted on here.
--
-- Slot reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

CREATE TEMP TABLE called (
  rc_id        uuid PRIMARY KEY,
  ap_cand_id   text NOT NULL,
  ballot_name  text NOT NULL,
  votes        int  NOT NULL,
  pct          numeric NOT NULL,
  ap_incumbent boolean NOT NULL,
  outcome      text NOT NULL CHECK (outcome IN ('won', 'lost'))
) ON COMMIT DROP;

INSERT INTO called (rc_id, ap_cand_id, ballot_name, votes, pct, ap_incumbent, outcome) VALUES
  ('43809e67-3447-4ffa-835e-12a567513e7c'::uuid, '172807', 'Nithya Raman',    579501, 54.46, false, 'won'),
  ('c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid, '50853',  'Karen Ruth Bass', 484580, 45.54, true,  'lost');

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),
           '[^A-Z0-9]', '', 'g')
$f$;

DO $$
DECLARE n int; txt text; race uuid;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 measured candidacies, the file carries %', n; END IF;

  PERFORM 1 FROM essentials.race_candidates WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Nithya Raman');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist'; END IF;

  -- the name beside each uuid is compared with the DATABASE ROW'S name (CC_0359 gate D)
  SELECT string_agg(c.ballot_name || ' (rc ' || c.rc_id || ') is ' ||
                    coalesce(rc.full_name, '(no such candidacy)') || ' in the database', '; ') INTO txt
    FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.id IS NULL OR pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.ballot_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a measured name does not match the row it is written against: %', txt; END IF;

  -- 🔴 BOTH ROWS MUST BE THE SAME RACE, AND IT MUST BE THE 2026-11-03 GENERAL, NOT THE JUNE
  --   PRIMARY. We hold TWO Los Angeles mayoral races: the primary carries 14 candidates and no
  --   swearing-in row, the general carries these two and hands over 2026-12-14. A control for
  --   CC_0379 landed on the primary by accident and proved nothing; this gate makes that
  --   mistake impossible to commit.
  SELECT count(DISTINCT rc.race_id) INTO n FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id;
  IF n <> 1 THEN RAISE EXCEPTION 'the two rows sit in % different races', n; END IF;
  SELECT DISTINCT rc.race_id INTO race FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id;

  SELECT string_agg(coalesce(s.swearing_in_date::text, '(no row)') || ' / ' ||
                    e.election_date::text || ' / ' || o.title || ' / ' || d.label, '; ') INTO txt
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
   WHERE r.id = race
     AND (e.election_date <> DATE '2026-11-03' OR s.swearing_in_date IS DISTINCT FROM DATE '2026-12-14'
          OR o.title <> 'Mayor' OR d.label <> 'Los Angeles city');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this is not the 2026-11-03 Los Angeles mayoral general handing over 2026-12-14: %', txt; END IF;

  -- every candidacy in the race must be measured
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.race_id = race AND NOT EXISTS (SELECT 1 FROM called x WHERE x.rc_id = rc.id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the race is only partly measured, missing: %', txt; END IF;

  SELECT r.seats INTO n FROM essentials.races r WHERE r.id = race;
  IF n <> (SELECT count(*) FROM called WHERE outcome = 'won') THEN
    RAISE EXCEPTION 'the race carries % seat(s) and this file records % winner(s)', n, (SELECT count(*) FROM called WHERE outcome = 'won');
  END IF;

  -- 🔴 AP'S WINNER MUST ALSO BE THE TOP VOTE-GETTER. CC_0359 learned that a call and a count
  --   can be published separately; where both exist they must agree, and if they ever do not,
  --   this file must stop rather than pick one.
  SELECT string_agg(l.ballot_name || ' (' || l.votes || ') is recorded LOST above ' ||
                    w.ballot_name || ' (' || w.votes || ') recorded WON', '; ') INTO txt
    FROM called w JOIN called l ON l.rc_id <> w.rc_id
   WHERE w.outcome = 'won' AND l.outcome = 'lost' AND l.votes >= w.votes;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'AP''s winner is not the top vote-getter: %', txt; END IF;

  -- 🔴 AN INDEPENDENT FACT: AP flags its own incumbent, and so does essentials.office_current_holder.
  --   Neither is supplied by this file, so they can disagree with it and with each other.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.ballot_name || ': AP says incumbent=' || c.ap_incumbent ||
           ', our candidacy says ' || rc.is_incumbent ||
           ', the seat is held by ' || coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = rc.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE c.ap_incumbent <> rc.is_incumbent
        OR (c.ap_incumbent AND och.politician_id IS DISTINCT FROM rc.politician_id)
        OR (NOT c.ap_incumbent AND och.politician_id = rc.politician_id)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent fact disagrees across AP, our row and the view: %', txt; END IF;

  -- percentages must be consistent with the votes this file carries
  SELECT string_agg(c.ballot_name || ': ' || c.pct || '% against ' || c.votes || ' of ' ||
                    (SELECT sum(votes) FROM called), '; ') INTO txt
    FROM called c
   WHERE abs(c.pct - round(100.0 * c.votes / (SELECT sum(votes) FROM called), 2)) > 0.02;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a percentage does not follow from the votes beside it: %', txt; END IF;

  SELECT string_agg(rc.full_name || ' already reads result=' || coalesce(rc.result, '(null)'), '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL
      OR rc.result_source IS NOT NULL OR rc.result_recorded_at IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file only writes over NULL and found a value: %', txt; END IF;

  RAISE NOTICE 'CC_0380 pre-checks passed: 2 candidacies in one race, both NULL, AP''s call agrees with the count and with the incumbent fact';
END $$;

UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Associated Press election results feed, race 20261103CA84303 '
         || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/national/), '
         || 'raceCallStatus "Called", called 2026-11-05T19:49:13Z at 91.77% of expected vote, '
         || 'isCertified false; retrieved 2026-11-08. ' || c.ballot_name || ' ' || c.votes
         || ' votes (' || c.pct || '%). AP''s figures match the Los Angeles County RR/CC count '
         || 'to the vote. Karen Bass conceded on 2026-11-05; that is corroboration, not the basis.',
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result_source LIKE '%CC_0380%' OR rc.result_source LIKE '%20261103CA84303%';
  IF n <> 2 THEN RAISE EXCEPTION 'this file wrote % of its 2 rows', n; END IF;

  SELECT count(*) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result = 'lost')
    INTO n, total FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;
  IF n <> 1 OR total <> 1 THEN RAISE EXCEPTION 'expected 1 won and 1 lost, wrote % and %', n, total; END IF;

  -- 🔴 THE TWO COUNCIL RACES MUST STILL BE NULL. AP carries no council contest, so they have
  --   no caller and the bound still governs them — margins of 1,869 and 417.
  SELECT string_agg(d.label || ': ' || rc.full_name || ' = ' || rc.result, '; ') INTO txt
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-14'
     AND o.title = 'Council Member'
     AND (rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL OR rc.result_source IS NOT NULL);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a council race with no caller has acquired a result: %', txt; END IF;

  -- the 2026-12-14 wave now stands at 2 of 4 decided, 4 candidacies open
  SELECT count(DISTINCT r.id) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result IS NULL)
    INTO n, total
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-14';
  IF n <> 2 THEN RAISE EXCEPTION 'the 2026-12-14 wave shows % races with a winner, expected 2', n; END IF;
  IF total <> 4 THEN RAISE EXCEPTION 'the wave shows % candidacies still unrecorded, expected 4', total; END IF;

  -- 🔴 NOBODY IS SEATED. Karen Bass is mayor until 2026-12-14 and the view must still say so.
  PERFORM 1 FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.races r ON r.office_id = och.office_id
   WHERE r.id = (SELECT DISTINCT rc.race_id FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id)
     AND p.full_name = 'Karen Ruth Bass';
  IF NOT FOUND THEN RAISE EXCEPTION 'the sitting mayor is no longer the current holder — this file must not have changed that'; END IF;

  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN
    RAISE EXCEPTION 'the unflagged offices_missing_terms baseline reads %, not 238 (total %, flagged %)', unflagged, total, flagged;
  END IF;

  RAISE NOTICE 'CC_0380 post-verify passed: Nithya Raman recorded as mayor-elect on AP''s call; Karen Bass is still the current holder until 2026-12-14; both council races still open; baseline unflagged 238 (total %, flagged %)', total, flagged;
END $$;

COMMIT;
