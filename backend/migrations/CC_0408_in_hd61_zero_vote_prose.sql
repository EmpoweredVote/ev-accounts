-- CC_0408 — Indiana House 61: replace the sentence that says Matt Pierce won with ZERO VOTES.
--
-- ONE ROW, ONE COLUMN. `essentials.race_candidates.result_source` on
-- 5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5. No result changes, no certainty changes, no person,
-- race, office, district or term is created, deleted, re-seated or re-dated. The call this row
-- records is CORRECT and stays: Pierce won. Only the count beside it was false.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 PRIOR VALUE, VERBATIM, BECAUSE AN UPDATE IS FINAL AND THERE IS NO HISTORY TABLE.
--   md5 1d3385cb90c44b30cc84ccb7d63200de, 426 characters, written by CC_0381 at
--   2026-11-08 21:30:32.186526+00:
--
--     Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP's
--     own per-state results feed (interactives.apelections.org/election-results/data-live/
--     2026-11-03/results/races/IN/, race 20261103IN15373, candidate 53896): Matt Pierce (Dem)
--     0 votes, 0%, recorded as won. This is AP's call and NOT the state canvass; AP reports
--     this race as not yet certified. Matched to our row on basis 'exact-full-name'.
--
--   The pre-gate below refuses to run unless the live column still hashes to that md5, so this
--   file cannot silently overwrite somebody else's later correction.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 WHAT WENT WRONG: AP PUBLISHES NO VOTE TOTAL FOR AN UNCONTESTED RACE, AND PUBLISHES THE
--      ABSENCE AS A ZERO. Read today from AP's own per-state feed, race 20261103IN15373:
--
--        metadata.json   "uncontested": true        parameters.vote.total   0
--                        "raceCallStatus": "Called" "isCertified": false
--        progress.json   candidate 53896 — voteCount 0, votePct 0, winner "X",
--                        calledAt 2026-11-03T23:00:00.000Z, eevp 0,
--                        reportingSources.voteTotal "ManualScrape"
--
--      AP called the seat at POLL CLOSE, which is the correct and normal handling of a ballot
--      with one name on it. The zero is AP's convention for a race it does not tabulate. It is
--      NOT a count, and CC_0381's generated sentence quoted it as one: "0 votes, 0%".
--
--      ⚠ THE DISCRIMINATOR WAS IN THE FEED THE WHOLE TIME AND WE DID NOT READ IT.
--        `uncontested: true` sits in AP's metadata beside the fields CC_0381 did read. A row
--        generated from voteCount alone cannot tell "nobody voted" from "AP does not count this
--        race", because both arrive as 0. ▶ Any future pass that formats AP vote totals must
--        branch on `uncontested` before it writes a number into prose.
--
-- WHERE THE REAL COUNT COMES FROM: the Indiana Election Division's own return, which does
--   tabulate the race — enr.indianavoters.in.gov/site/data/OffCatC_1040_B.json (category 1040 is
--   the state House; the site is Cloudflare-fronted, so it is fetched from the page origin, not
--   by bare curl). Read 2026-11-12 from a file whose Root.WriteTime is 2026-11-12T15:02:06.163:
--
--     OFFICEID 5158 · "State Representative, District 061" · NumofSeats 1
--       NAME_ON_BALLOT "Matt Pierce" · PARTY D · TOTAL 12939 · isWinner "T"
--
--   The page carrying that file reported 96.7% of Indiana's 5,067 precincts reporting statewide.
--   ▶ SO THIS IS STILL NOT A CANVASS. The row keeps result_certainty = 'called'; a count read
--     off a live return five days before certification is a better number than a false one, not
--     a certified one. Indiana certifies on 2026-12-01.
--
-- ⚠ WHAT THE STATE FILE DOES AND DOES NOT SAY ABOUT WRITE-INS. Pierce is the only candidate it
--   lists for this seat. Across all 100 Indiana House races the file lists NO write-in row at
--   all, so its silence here is the file's PRACTICE, not evidence that nobody wrote a name in.
--   The new sentence therefore says Pierce is the only candidate the return lists; it does NOT
--   claim he took 100% of the votes cast.
--
-- 🟢 THE READ WAS CONTROLLED. The same parse over the same file returns 79 multi-candidate races
--   with differing totals and isWinner T/F — House 45 comes back Streeter (R) 12,691 isWinner T
--   against Mayfield (D) 5,517 isWinner F — so the shape it returned for House 61 is a real
--   minority (21 of 100 races carry one candidate), not a parser collapsing every race to one
--   row. ⚠ Note the candidate node is an OBJECT when there is one candidate and an ARRAY
--   otherwise; reading it as an array without that branch returns undefined for this race.
--
-- 🔴🔴 THIS ROW IS ONE OF 55, AND THE OTHER 54 ARE DELIBERATELY NOT TOUCHED HERE.
--   Measured on production 2026-11-12: 55 candidacy rows carry the '0 votes, 0%' sentence, every
--   one of them a WINNER, spread across nine elections — WA 19, AZ 11, WI 8, UT 7, CA 4, MA 3,
--   CO 1, IN 1, OR 1. Those 55 rows are the ONLY rows in their races: not one of those races
--   holds a losing candidacy, which is the signature of an uncontested ballot (Arizona's pairs
--   are two-seat districts with two candidates). Fixing one needs that ONE state's own return
--   read and checked; eight more states is a separate piece of work with its own sources, and
--   guessing a count is how this defect got here. ▶ The post-verify asserts the class falls from
--   55 to EXACTLY 54, which is also the proof that this file touched one row and no other.
--
-- WHAT IS NOT WRITTEN:
--   · `result` stays 'won' and `result_certainty` stays 'called'. The call was right.
--   · `result_recorded_at` is LEFT AT 2026-11-08 21:30:32.186526+00 and gated unchanged. The
--     result was recorded that day; only its citation is being corrected today, and moving the
--     timestamp would erase when we actually learned the outcome.
--   · Nobody is seated. `office_terms` is asserted unchanged, row for row.

BEGIN;

-- ─── 1. Pre-gates ───
DO $$
DECLARE v_md5 text; v_name text; v_result text; v_certainty text; v_holder text; v_n int;
BEGIN
  SELECT md5(rc.result_source), rc.full_name, rc.result, rc.result_certainty
    INTO v_md5, v_name, v_result, v_certainty
    FROM essentials.race_candidates rc
   WHERE rc.id = '5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5'::uuid;

  IF v_md5 IS NULL THEN
    RAISE EXCEPTION 'CC_0408 pre-gate: candidacy 5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5 is not present';
  END IF;
  IF v_md5 <> '1d3385cb90c44b30cc84ccb7d63200de' THEN
    RAISE EXCEPTION 'CC_0408 pre-gate: result_source has changed since this file was written (md5 %, expected 1d3385cb90c44b30cc84ccb7d63200de) — re-read the row before overwriting it', v_md5;
  END IF;
  IF v_name <> 'Matt Pierce' OR v_result <> 'won' OR v_certainty <> 'called' THEN
    RAISE EXCEPTION 'CC_0408 pre-gate: row is % / % / %, expected Matt Pierce / won / called', v_name, v_result, v_certainty;
  END IF;

  -- 🔴 THE IDENTITY CLAIM, NOT JUST THE STRING. The Indiana ballot name must be the person our
  --    own data says sits in House 61, or the count being written belongs to somebody else.
  SELECT p.full_name INTO v_holder
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = '7b3f68ef-bd9b-4316-9e39-89091b6e9aa1'::uuid;
  IF v_holder IS DISTINCT FROM 'Matt Pierce' THEN
    RAISE EXCEPTION 'CC_0408 pre-gate: House 61 is held by %, not Matt Pierce', coalesce(v_holder, '(nobody)');
  END IF;

  -- The row must still carry the false sentence. If it does not, somebody has already fixed it.
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.id = '5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5'::uuid
     AND rc.result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'CC_0408 pre-gate: the zero-vote sentence is not on this row'; END IF;

  -- The repo-wide class, measured before the write.
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_n <> 55 THEN RAISE EXCEPTION 'CC_0408 pre-gate: % rows carry the zero-vote sentence, expected 55 — re-measure before writing', v_n; END IF;
END $$;

-- Snapshots that the post-verify compares against, taken inside this transaction so that
-- another session moving a total while this file is written cannot turn a gate red or green.
CREATE TEMP TABLE cc0408_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                            AS office_terms_rows,
       (SELECT count(*) FROM essentials.race_candidates
         WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%')                      AS zero_vote_rows,
       (SELECT result_recorded_at FROM essentials.race_candidates
         WHERE id = '5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5'::uuid)                AS recorded_at,
       (SELECT count(*) FROM essentials.race_candidates rc
          JOIN essentials.races r ON r.id = rc.race_id
          JOIN essentials.elections e ON e.id = r.election_id
         WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified') AS certified_rows;

-- ─── 2. The write ───
UPDATE essentials.race_candidates rc
   SET result_source =
         'Associated Press called this race for Matt Pierce (Dem) at poll close, '
      || '2026-11-03T23:00:00Z — AP''s own per-state results feed '
      || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/races/IN/, '
      || 'race 20261103IN15373, candidate 53896, winner flag "X"), read 2026-11-08 and re-read '
      || '2026-11-12. AP MARKS THIS RACE "uncontested": true AND PUBLISHES NO VOTE TOTAL FOR IT: '
      || 'voteCount 0, votePct 0, parameters.vote.total 0, eevp 0. That zero is AP''s convention '
      || 'for a race it does not tabulate, not a count — this row previously repeated that zero '
      || 'as a vote total and a percentage, which was false, and CC_0408 replaced the sentence '
      || 'on 2026-11-12 (the exact prior wording is recorded in that migration''s header). '
      || 'THE VOTES ARE PUBLISHED BY THE INDIANA ELECTION DIVISION''S OWN RETURN: '
      || 'enr.indianavoters.in.gov/site/data/OffCatC_1040_B.json, OFFICEID 5158 '
      || '"State Representative, District 061", NumofSeats 1 — NAME_ON_BALLOT "Matt Pierce", '
      || 'PARTY D, TOTAL 12,939 votes, isWinner "T" — read 2026-11-12 from a file whose '
      || 'Root.WriteTime is 2026-11-12T15:02:06.163, with 96.7% of Indiana''s 5,067 precincts '
      || 'reporting statewide. Pierce is the only candidate that return lists for this seat; the '
      || 'file lists no write-in row for any of the 100 Indiana House races, so it states no '
      || 'opposing or write-in total rather than reporting none. THIS IS A RACE CALL AND A '
      || 'PARTIAL STATE RETURN, NOT THE CERTIFIED CANVASS — AP reports isCertified false and '
      || 'Indiana certifies on 2026-12-01. Matched to our row on basis ''exact-full-name'' '
      || '(CC_0381); the Indiana ballot name is also the person essentials.office_current_holder '
      || 'names in House 61.'
 WHERE rc.id = '5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5'::uuid
   AND md5(rc.result_source) = '1d3385cb90c44b30cc84ccb7d63200de';

-- ─── 3. Post-verify ───
DO $$
DECLARE b record; v_n int; v_src text; v_result text; v_certainty text; v_recorded timestamptz;
BEGIN
  SELECT * INTO b FROM cc0408_before;

  SELECT rc.result_source, rc.result, rc.result_certainty, rc.result_recorded_at
    INTO v_src, v_result, v_certainty, v_recorded
    FROM essentials.race_candidates rc
   WHERE rc.id = '5dbdf812-0d70-4eb4-b0b9-aaf5e4bc7ff5'::uuid;

  -- The false sentence must be gone from this row.
  IF v_src ~ '[^0-9,]0 votes, 0(\.0+)?%' THEN
    RAISE EXCEPTION 'CC_0408 gate: the zero-vote sentence is still on the row';
  END IF;

  -- 🔴 AND THE REAL COUNT MUST BE THERE. "Not false" is not "true": a blanked column would pass
  --    the test above and assert nothing at all.
  IF position('12,939 votes' in v_src) = 0 THEN
    RAISE EXCEPTION 'CC_0408 gate: the state''s count is not in the new citation';
  END IF;
  IF position('enr.indianavoters.in.gov' in v_src) = 0 THEN
    RAISE EXCEPTION 'CC_0408 gate: the new citation does not name the source of that count';
  END IF;
  -- AP's provenance survives: the call is still AP's and the row must still say so, by race id.
  IF position('20261103IN15373' in v_src) = 0 THEN
    RAISE EXCEPTION 'CC_0408 gate: the new citation dropped the AP race id it was called from';
  END IF;
  IF position('uncontested' in v_src) = 0 THEN
    RAISE EXCEPTION 'CC_0408 gate: the new citation does not say WHY AP reported a zero';
  END IF;
  -- It must not read as a canvass.
  IF position('NOT THE CERTIFIED CANVASS' in v_src) = 0 THEN
    RAISE EXCEPTION 'CC_0408 gate: the new citation does not say it is uncertified';
  END IF;

  -- The result itself is untouched, and so is when it was recorded.
  IF v_result <> 'won' OR v_certainty <> 'called' THEN
    RAISE EXCEPTION 'CC_0408 gate: the result moved — % / %, expected won / called', v_result, v_certainty;
  END IF;
  IF v_recorded IS DISTINCT FROM b.recorded_at THEN
    RAISE EXCEPTION 'CC_0408 gate: result_recorded_at moved from % to %, and this file records no new result', b.recorded_at, v_recorded;
  END IF;

  -- 🔴 EXACTLY ONE ROW LEFT THE CLASS. This is also the proof that nothing else was touched.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_n <> b.zero_vote_rows - 1 THEN
    RAISE EXCEPTION 'CC_0408 gate: % rows still carry the zero-vote sentence, expected % (one fewer than before)', v_n, b.zero_vote_rows - 1;
  END IF;
  IF v_n <> 54 THEN
    RAISE EXCEPTION 'CC_0408 gate: expected 54 zero-vote rows to REMAIN for a later pass, found %', v_n;
  END IF;

  -- Recording a citation seats nobody and certifies nobody.
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> b.office_terms_rows THEN
    RAISE EXCEPTION 'CC_0408 gate: office_terms moved from % to % — this file seats nobody', b.office_terms_rows, v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
     JOIN essentials.races r ON r.id = rc.race_id
     JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified';
  IF v_n <> b.certified_rows THEN
    RAISE EXCEPTION 'CC_0408 gate: certified rows in the 2026-11-03 general moved from % to %', b.certified_rows, v_n;
  END IF;

  RAISE NOTICE 'CC_0408 OK — Indiana House 61 now cites the Indiana Election Division''s 12,939 votes; 54 zero-vote rows remain across the other eight states for a later pass';
END $$;

COMMIT;
