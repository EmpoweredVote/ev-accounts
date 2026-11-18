-- CC_0452 — ME-02: Paul LePage's winner citation claims he defeated an incumbent who was not
--           a candidate. Replace that clause with what the seat actually was: OPEN.
--
-- =============================================================================================
-- WHAT IS WRONG
-- =============================================================================================
--
-- CC_0447 wrote this, and it is live on a voter-facing page:
--
--     "Called 2026-11-12T18:31:29.417Z, defeating incumbent Jared Golden."
--
-- Jared Golden was ME-02's incumbent and was NOT A CANDIDATE. He announced on 2025-11-05 that
-- he would not seek re-election. LePage won an OPEN seat, defeating Matthew Dunlap.
--
-- =============================================================================================
-- THE VALUE THIS MIGRATION OVERWRITES, RECORDED BEFORE IT IS DESTROYED
-- =============================================================================================
--
-- There is no history table for result_source and no schema_migrations to replay from, so the
-- moment this UPDATE commits the old string exists nowhere but here and in
-- backend/data/me02-open-seat-2026/before-values.json. CA_0335 cost a full production clone by
-- recording only the new values, and it destroyed the evidence for its own premise in the
-- bargain. So:
--
--   row            c58647c9-1ac0-43a4-9682-c0c7198631b9  (Paul LePage, ME-02, result = won)
--   md5 before     32379de0539db5d416bcbec49ba34b13
--   length before  474
--   value before   AP race call, AP race 20261103ME20645 (ME-02), RANKED CHOICE. WINNER=Paul
--                  LePage; GOP, first-choice 170,265 votes, 49.89% of all 341,256 ballots cast,
--                  of which 6,021 were blank. No candidate cleared 50% on first choices, so
--                  Maine ran its ranked-choice tabulation; AP's final round gives LePage 170,890
--                  to Matthew Dunlap 165,432. Called 2026-11-12T18:31:29.417Z, defeating
--                  incumbent Jared Golden. AP results feed read 2026-11-17 03:00Z. A media call
--                  is not the state canvass.
--
-- The pre-check REFUSES unless the live value still hashes to that md5. A header claim about an
-- overwritten value is only testable while the value is still there, so the file is gated on it
-- rather than merely asserting it in prose.
--
-- 🟢 THE WRITE IS A replace() ON THE LIVE STRING, NOT A RESTATEMENT OF IT. Only the 35-character
--    clause moves; the AP race id, both vote counts, the ranked-choice final round, the call
--    timestamp and the canvass caveat survive by construction rather than by careful retyping.
--
-- =============================================================================================
-- 🔴 THE DEFECT IS NOT A TYPO. IT IS A TWO-WAY TEST THAT NEEDED THREE BRANCHES.
-- =============================================================================================
--
-- AP's feed publishes an `incumbent` for a race. CC_0447 compared it with the winner:
--
--   winner id == incumbent id   ->  "Incumbent re-elected"   (CA-23 Obernolte, NC-07 Rouzer)
--   winner id != incumbent id   ->  "defeating incumbent X"  (CA-04, CO-04 ... and ME-02)
--
-- The first branch is careful work: it compares AP candidate IDs, not surnames, which is the
-- namesake guard this repo pays for elsewhere. The second branch is where the hole is.
--
-- 🔴 AP's `incumbent` IS AN ATTRIBUTE OF THE SEAT, NOT A BALLOT LINE. "The winner is not the
--    incumbent" does not mean "the winner beat the incumbent". The incumbent may not have run.
--    The missing question is the third branch:
--
--        IS THE INCUMBENT'S CANDIDATE ID ON A LOSING BALLOT LINE IN THIS RACE?
--          yes -> the winner defeated the incumbent
--          no  -> OPEN SEAT; the incumbent did not seek re-election
--
--    In ME-02 the answer is no, and nothing errored. In CA-04 and CO-04 the answer is yes,
--    which is why those two citations are correct and are left exactly as they are.
--
-- ⚠ THE SAME PASS GOT FOUR OF FIVE RIGHT, AND THAT IS THE POINT. A rule can be right most of
--   the time and still be the wrong rule. Four green rows are not evidence the rule is sound;
--   they are evidence the fifth case is rarer.
--
-- =============================================================================================
-- THE SOURCES, EACH READ AS A DOCUMENT
-- =============================================================================================
--
-- 1. MAINE SECRETARY OF STATE, "2026 General Candidate List - FINAL" (.xlsx), downloaded from
--    maine.gov/sos/elections-voting/upcoming-elections and committed beside this migration as
--    backend/data/me02-open-seat-2026/me-2026-general-candidate-list-FINAL.xlsx, so the claim
--    re-reads offline. Parsed from its own sharedStrings/sheet XML. Office code CG, District 2
--    holds exactly two rows:
--
--        CG | Dist 2 | ... | Dunlap, Matthew G.
--        CG | Dist 2 | ... | LePage, Paul R.
--
--    Golden appears in NONE of the file's 456 rows.
--    🔴 A NAME SEARCH THAT FINDS NOTHING IS A BROKEN SEARCH UNTIL A CONTROL PASSES. The same
--       probe was run for names that must be there: "lepage" 2 rows, "dunlap" 1, "mills" 1,
--       "golden" 0. The detector is live, so the zero is an absence rather than a failure.
--
-- 2. AP'S OWN CAPTURE, already committed by CC_0450 at
--    backend/data/house-2026-late-losers/ap-ballots-2026-11-17.json. For race 20261103ME20645:
--
--        ap_incumbent  : { candidate_id "66383", first "Jared", last "Golden" }
--        all_lines     : 60414 LePage · 174146 Dunlap · 179614 Blank Votes · 120523 Ward
--
--    🔴 AP NAMES GOLDEN AS THE INCUMBENT AND PUTS HIM ON NO BALLOT LINE, IN THE SAME OBJECT.
--       The evidence that the claim is false was inside the file the claim was built from.
--
-- 3. THE MAINE MONITOR / NOTUS, published 2025-11-05, read 2026-11-17 (page fetched and read,
--    not summarised): "Rep. Jared Golden announced Wednesday that he will not seek reelection",
--    in a Bangor Daily News op-ed, quoting him directly - "I don't fear losing. What has become
--    apparent to me is that I now dread the prospect of winning."
--    ⚠ A web search summary was NOT the source for any name or date here. It located the page.
--
-- =============================================================================================
-- 🟢 WHAT IS *NOT* WRONG, AND MUST NOT BE "FIXED"
-- =============================================================================================
--
-- GOLDEN STILL HOLDS THE SEAT. His office_terms row (term_start 2019-01-03, open-ended, from
-- unitedstates/congress-legislators via migration 1536) is correct and this file does not touch
-- it. A RETIRING incumbent holds the office until the term ends on 2027-01-03, exactly as a
-- DEFEATED one does - the repo already knows that a losing incumbent still holds the seat, and
-- this is the same rule reached from the other side. Assertion 10 pins it, because the obvious
-- misreading of this correction is "then Golden should not be in office_current_holder".
--
-- The four other CC_0447 winner citations were each checked against our own office_terms AND
-- against AP's ballot, and all four are TRUE. They are listed in before-values.json and
-- assertion 11 confirms this file left them alone:
--
--   CA-04  Jones "defeating incumbent Mike Thompson"   - Thompson holds CA-04 and lost the race
--   CO-04  Laubacher "defeating incumbent L. Boebert"  - Boebert holds CO-04 and lost the race
--   CA-23  Obernolte "Incumbent re-elected"            - winner id == incumbent id
--   NC-07  Rouzer "Incumbent re-elected"               - winner id == incumbent id
--
-- =============================================================================================
-- WHAT THIS DELIBERATELY DOES NOT DO
-- =============================================================================================
--
-- * It creates and deletes nothing: no race_candidates row for Golden (he was not a candidate -
--   a row would assert the opposite of the finding), no politicians row, no office change.
-- * It does not re-stamp result_recorded_at. The RESULT did not change; a citation did. Moving
--   that timestamp would claim the call was re-read today, and it was not.
-- * It does not touch the `source` column, which records where the candidacy came from.
-- * 🔴 IT DOES NOT ADD A GENERAL CI GATE for the three-branch rule above. That gate wants to
--   read AP's ballot, which lives in a committed JSON file rather than in the database, so it
--   belongs with the matcher and not in a post-verify block. Assertion 3 pins the half of it
--   that IS answerable in SQL - every "defeating incumbent X" claim repo-wide must name someone
--   who holds a row in that same race - and that half alone would have caught CC_0447.
--
-- =============================================================================================
-- ⚠ TWO SQL ALIASES WERE RENAMED AFTER THIS FILE WAS APPLIED, AND THAT IS RECORDED RATHER THAN
--   QUIETLY TIDIED. The applied text aliased a temp table and a sub-select `o`;
--   check-office-occupancy.mjs reads `<alias>.politician_id` as the dropped
--   essentials.offices.politician_id and failed CI on it. The guard is right - it cannot tell a
--   temp table aliased `o` from the offices table - so the aliases are now `prev` and `opp`.
--   Nothing else changed: no predicate, no literal, no assertion.
--   🔴 THE FILE IS NOT RE-RUNNABLE TO PROVE THAT, because its pre-check pins the OLD md5, which
--   is no longer live. It was verified instead by a REPLAY: a scratch copy that restores the
--   overwritten citation inside the transaction and then runs this file unchanged. Both renamed
--   aliases were exercised against real data, and the whole thing rolled back.
-- =============================================================================================

BEGIN;

-- The row, pinned by id, and the exact clause this file is allowed to replace.
CREATE TEMP TABLE cc0452_pin ON COMMIT DROP AS
SELECT 'c58647c9-1ac0-43a4-9682-c0c7198631b9'::uuid        AS rc_id,
       'aa63d55d-80b8-42b9-9aa5-0713387f65fb'::uuid        AS race_id,
       '32379de0539db5d416bcbec49ba34b13'                  AS md5_before,
       ', defeating incumbent Jared Golden.'               AS false_clause;

-- Baselines, captured in this transaction so nobody else's concurrent work can move them.
CREATE TEMP TABLE cc0452_base ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.race_candidates)   AS rc_total,
       (SELECT count(*) FROM essentials.politicians)       AS pol_total,
       (SELECT count(*) FROM essentials.politician_images) AS img_total;

-- Every citation in the repo, hashed. Assertion 1 compares against this: exactly one row may
-- differ afterwards, which is a far stronger claim than "the row I meant to change changed".
CREATE TEMP TABLE cc0452_cites ON COMMIT DROP AS
SELECT rc.id, md5(rc.result_source) AS md5_before
  FROM essentials.race_candidates rc
 WHERE rc.result_source IS NOT NULL;

-- The row's other columns, so assertion 7 can prove this file moved nothing but the prose.
CREATE TEMP TABLE cc0452_row_before ON COMMIT DROP AS
SELECT rc.id, rc.full_name, rc.result, rc.result_certainty, rc.result_recorded_at,
       rc.politician_id, rc.is_write_in, rc.candidate_status, rc.source
  FROM essentials.race_candidates rc
  JOIN cc0452_pin p ON p.rc_id = rc.id;

-- Golden's tenure, so assertion 10 can prove the correction did not unseat him.
CREATE TEMP TABLE cc0452_term_before ON COMMIT DROP AS
SELECT och.office_id, och.politician_id, p.full_name
  FROM essentials.office_current_holder och
  JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE och.office_id = (SELECT r.office_id FROM essentials.races r
                         JOIN cc0452_pin pin ON pin.race_id = r.id);

-- ---------------------------------------------------------------------------------------------
-- PRE-CHECK. Refuse to overwrite anything whose current value is not the one in the header.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  n int;
  live_md5 text;
BEGIN
  -- P1. The row is there, it is ME-02's winner, and it still holds the value this file records.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN cc0452_pin p ON p.rc_id = rc.id
   WHERE rc.race_id = p.race_id
     AND rc.result = 'won'
     AND rc.full_name = 'Paul LePage';
  IF n <> 1 THEN
    RAISE EXCEPTION 'PRE-CHECK: expected exactly 1 ME-02 winner row named Paul LePage at the pinned id, found %', n;
  END IF;

  SELECT md5(rc.result_source) INTO live_md5
    FROM essentials.race_candidates rc JOIN cc0452_pin p ON p.rc_id = rc.id;
  IF live_md5 IS DISTINCT FROM (SELECT md5_before FROM cc0452_pin) THEN
    RAISE EXCEPTION 'PRE-CHECK: the live citation hashes to %, the header records % — it has been edited since. Re-read it, re-record it, and do not overwrite somebody else''s value.',
      live_md5, (SELECT md5_before FROM cc0452_pin);
  END IF;

  -- P2. The clause occurs exactly once, so replace() cannot touch more than it should.
  SELECT (length(rc.result_source) - length(replace(rc.result_source, p.false_clause, ''))) / length(p.false_clause)
    INTO n
    FROM essentials.race_candidates rc JOIN cc0452_pin p ON p.rc_id = rc.id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'PRE-CHECK: the clause to replace occurs % time(s) in the citation, expected exactly 1', n;
  END IF;

  -- P3. The premise of the correction, read from the table rather than asserted in prose:
  --     nobody named Golden is a candidate in this race.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN cc0452_pin p ON p.race_id = rc.race_id
   WHERE rc.last_name = 'Golden' OR rc.full_name ILIKE '%Golden%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'PRE-CHECK: % candidate row(s) named Golden exist in ME-02 — the premise of this correction is wrong, stop', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- THE WRITE. One row, one clause, guarded and idempotent.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result_source = replace(
         rc.result_source,
         p.false_clause,
         '. OPEN SEAT: ME-02''s incumbent, Jared Golden, was not a candidate. He announced on '
      || '2025-11-05 that he would not seek re-election, so LePage defeated Matthew Dunlap for an '
      || 'open seat and defeated no incumbent. Two sources, each read as a document: the Maine '
      || 'Secretary of State''s "2026 General Candidate List - FINAL" prints exactly two names for '
      || 'Congressional District 2 (Dunlap, Matthew G. and LePage, Paul R.) and names Golden in '
      || 'none of its 456 rows; AP names Golden as this race''s incumbent, AP candidate id 66383, '
      || 'and that id sits on none of the four ballot lines AP publishes here. Golden continues to '
      || 'hold the seat until the term ends 2027-01-03. CORRECTED by CC_0452, which replaced a '
      || 'clause written by CC_0447 that wrongly described Golden as having been beaten in this '
      || 'race; the overwritten value is recorded verbatim in that migration''s header and in '
      || 'backend/data/me02-open-seat-2026/before-values.json.')
  FROM cc0452_pin p
 WHERE rc.id = p.rc_id
   AND strpos(rc.result_source, p.false_clause) > 0;

-- ---------------------------------------------------------------------------------------------
-- Post-verify. Counting one row says nothing; each gate below takes its expectation from
-- somewhere a tamper on this file cannot reach.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  n int;
  b record;
  txt text;
BEGIN
  SELECT * INTO b FROM cc0452_base;

  -- 1. 🔴 EXACTLY ONE CITATION IN THE WHOLE REPO CHANGED, AND IT IS THIS ONE.
  --    (expectation: the md5 of every citation, captured in this transaction before the write)
  SELECT count(*) INTO n
    FROM cc0452_cites c
    JOIN essentials.race_candidates rc ON rc.id = c.id
   WHERE md5(rc.result_source) IS DISTINCT FROM c.md5_before;
  IF n <> 1 THEN
    RAISE EXCEPTION '1: % citation(s) repo-wide changed, expected exactly 1', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0452_cites c
    JOIN essentials.race_candidates rc ON rc.id = c.id
    JOIN cc0452_pin p ON p.rc_id = rc.id
   WHERE md5(rc.result_source) IS DISTINCT FROM c.md5_before;
  IF n <> 1 THEN
    RAISE EXCEPTION '1: the one citation that changed is not the pinned ME-02 winner row';
  END IF;

  -- 2. The false claim is gone from the row, in every spelling.
  SELECT rc.result_source INTO txt
    FROM essentials.race_candidates rc JOIN cc0452_pin p ON p.rc_id = rc.id;
  IF txt ILIKE '%defeating incumbent%' OR txt ILIKE '%defeated incumbent%'
     OR txt ILIKE '%incumbent Jared Golden%' THEN
    RAISE EXCEPTION '2: the ME-02 winner citation still claims an incumbent was defeated';
  END IF;
  IF txt NOT LIKE '%OPEN SEAT%' THEN
    RAISE EXCEPTION '2: the ME-02 winner citation does not say the seat was open';
  END IF;

  -- 3. 🔴 THE GATE THAT WOULD HAVE CAUGHT CC_0447, repo-wide and not limited to this race:
  --    every "defeating incumbent X" claim must name somebody who holds a row IN THAT RACE.
  --    (expectation: essentials.race_candidates itself — this file declares no name here)
  SELECT count(*) INTO n
    FROM (
      SELECT rc.id, rc.race_id,
             substring(rc.result_source from 'defeating incumbent ([^.]+)\.') AS claimed
        FROM essentials.race_candidates rc
       WHERE rc.result_source LIKE '%defeating incumbent %'
    ) q
   WHERE q.claimed IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.race_candidates opp
                      WHERE opp.race_id = q.race_id
                        AND opp.full_name = q.claimed
                        AND opp.result = 'lost');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % row(s) claim to have defeated an incumbent who holds no losing row in that race', n;
  END IF;

  -- 4. The citation still names the person it is attached to.
  --    (expectation: rc.full_name, read from the table)
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN cc0452_pin p ON p.rc_id = rc.id
   WHERE rc.result_source NOT LIKE '%WINNER=' || rc.full_name || ';%';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: the ME-02 citation no longer names its own candidate';
  END IF;

  -- 5. The citation still names the seat the row sits in.
  --    (expectation: d.state and d.geo_id, the row's own geography)
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN cc0452_pin p ON p.rc_id = rc.id
    JOIN essentials.races r  ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE rc.result_source NOT LIKE '%(' || upper(lower(d.state)) || '-' || substr(d.geo_id, 3, 2) || ')%';
  IF n <> 0 THEN
    RAISE EXCEPTION '5: the ME-02 citation carries a seat label that is not the seat the row sits in';
  END IF;

  -- 6. 🔴 THE NUMBERS SURVIVED THE REPLACE, CHECKED AGAINST A ROW THIS FILE DID NOT WRITE.
  --    CC_0450's Dunlap citation carries the same ranked-choice final round. If the replace()
  --    ate part of the sentence it sits in, these stop agreeing.
  --    (expectation: the Dunlap row's result_source, written by CC_0450)
  SELECT count(*) INTO n
    FROM essentials.race_candidates w
    JOIN cc0452_pin p ON p.rc_id = w.id
    JOIN LATERAL (
      SELECT l.result_source AS cite
        FROM essentials.race_candidates l
       WHERE l.race_id = p.race_id AND l.full_name = 'Matthew Dunlap'
       LIMIT 1) d ON true
   WHERE d.cite IS NULL
      OR w.result_source NOT LIKE '%' || substring(d.cite from 'final round gives Paul LePage ([0-9,]+)') || '%'
      OR w.result_source NOT LIKE '%' || substring(d.cite from 'to Dunlap ([0-9,]+)') || '%'
      OR w.result_source NOT LIKE '%' || substring(d.cite from '(AP race [0-9A-Z]+)') || '%'
      OR w.result_source NOT LIKE '%A media call is not the state canvass.%';
  IF n <> 0 THEN
    RAISE EXCEPTION '6: the corrected citation lost the race id or the ranked-choice figures its own loser row carries';
  END IF;

  -- 7. Nothing but the prose moved on this row.
  --    (expectation: the row's own columns, captured before the write)
  -- NB: the alias is `prev`, not `o`. check-office-occupancy.mjs reads `<alias>.politician_id`
  -- as a reference to the dropped essentials.offices.politician_id, and it is right to: a
  -- static guard cannot tell a temp table aliased `o` from the offices table. Renaming the
  -- alias is the fix; widening the guard's pattern would not be.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN cc0452_row_before prev ON prev.id = rc.id
   WHERE rc.full_name        IS DISTINCT FROM prev.full_name
      OR rc.result           IS DISTINCT FROM prev.result
      OR rc.result_certainty IS DISTINCT FROM prev.result_certainty
      OR rc.result_recorded_at IS DISTINCT FROM prev.result_recorded_at
      OR rc.politician_id    IS DISTINCT FROM prev.politician_id
      OR rc.is_write_in      IS DISTINCT FROM prev.is_write_in
      OR rc.candidate_status IS DISTINCT FROM prev.candidate_status
      OR rc.source           IS DISTINCT FROM prev.source;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: this file changed a column other than result_source on the ME-02 winner row';
  END IF;

  -- 8. Exactly one row repo-wide carries this migration's marker.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
   WHERE rc.result_source LIKE '%CORRECTED by CC_0452,%';
  IF n <> 1 THEN
    RAISE EXCEPTION '8: % row(s) repo-wide carry this migration''s marker, expected exactly 1', n;
  END IF;

  -- 9. It creates and deletes nothing, in any of the three tables the mirror trigger can reach.
  IF (SELECT count(*) FROM essentials.race_candidates) <> b.rc_total THEN
    RAISE EXCEPTION '9: race_candidates moved from % to %', b.rc_total, (SELECT count(*) FROM essentials.race_candidates);
  END IF;
  IF (SELECT count(*) FROM essentials.politicians) <> b.pol_total THEN
    RAISE EXCEPTION '9: politicians moved from % to %', b.pol_total, (SELECT count(*) FROM essentials.politicians);
  END IF;
  IF (SELECT count(*) FROM essentials.politician_images) <> b.img_total THEN
    RAISE EXCEPTION '9: politician_images moved from % to %', b.img_total, (SELECT count(*) FROM essentials.politician_images);
  END IF;

  -- 10. 🔴 GOLDEN STILL HOLDS ME-02. Correcting the citation must not be read as unseating him.
  --     (expectation: office_current_holder, a different table this file never writes)
  SELECT count(*) INTO n
    FROM cc0452_term_before t
    LEFT JOIN essentials.office_current_holder och
           ON och.office_id = t.office_id AND och.politician_id = t.politician_id
   WHERE och.office_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: ME-02''s officeholder changed — the retiring incumbent holds the seat until 2027-01-03';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cc0452_term_before WHERE full_name = 'Jared Golden') THEN
    RAISE EXCEPTION '10: ME-02''s current holder was not Jared Golden when this transaction began';
  END IF;

  -- 11. The four other CC_0447 winner citations are untouched and still say what they said.
  --     (covered by assertion 1, asserted again by content because the point of this file is
  --      that the fix is targeted at the one claim that is false)
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
   WHERE rc.result = 'won'
     AND rc.result_recorded_at = (SELECT result_recorded_at FROM cc0452_row_before)
     AND rc.result_source LIKE '%Incumbent re-elected: AP winner candidateID%';
  IF n <> 2 THEN
    RAISE EXCEPTION '11: expected 2 CC_0447 winner rows still reading "Incumbent re-elected", found %', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
   WHERE rc.result = 'won'
     AND rc.result_recorded_at = (SELECT result_recorded_at FROM cc0452_row_before)
     AND rc.result_source LIKE '%defeating incumbent %';
  IF n <> 2 THEN
    RAISE EXCEPTION '11: expected 2 CC_0447 winner rows still reading "defeating incumbent" (CA-04, CO-04), found %', n;
  END IF;

  RAISE NOTICE 'CC_0452 OK — ME-02''s winner citation records an open seat; 1 citation changed repo-wide, Golden still holds the seat.';
END $$;

COMMIT;
