BEGIN;

-- =============================================================================
-- CC_0087: four rows describe the LU-8H vote more precisely than the record does
-- =============================================================================
-- Slot CC_0087 reserved via `steward slot CC` before this file existed.
--
-- 🔴 THIS FILE EDITS VOTER-FACING PROSE. CC_0081..CC_0084 each asserted the
--    reasoning was byte-identical; this one changes it, in four published claims
--    about four named sitting commissioners. Approved by Chris Cantrell
--    2026-09-09 after being shown the before/after for each row, with the
--    wording chosen as "minimal correction": fix only what the record
--    contradicts, add no procedure a voter does not need.
--
-- APPLIED TO PRODUCTION 2026-09-09 with scripts/apply-migration-file.mjs, the
--    first use of the DROP-guard repair from PR #434 -- before it, the safe
--    applier refused this file for dropping its own temp tables. Dry-run first
--    with scripts/dry-run-migration.mjs --verify, which printed all four
--    corrected sentences from inside the doomed transaction; rollback confirmed
--    by re-reading the corpus (the old tally still present) before applying.
--    After: 4 rows updated, chairs still 4/2/2/2, sources still 3/5/3/3.
--
-- ⚠ DELIBERATELY NOT IDEMPOTENT. Precondition 3 requires each OLD sentence to be
--    present exactly once, so a second run FAILS LOUDLY rather than passing as a
--    no-op. For a `sources` append a silent no-op is right; for a prose edit it
--    is not -- "this already ran" is something the operator must be told, since
--    the alternative is wondering whether a text change landed.
--
-- WHAT THIS IS. Four `reasoning` edits, one sentence each. NO answer changes and
-- NO chair moves. `sources` are untouched — the instrument was always cited; it
-- is the description of the VOTE that overreached.
--
-- ── WHAT THE RECORD ACTUALLY SAYS ────────────────────────────────────────────
--
-- Matter 241888 (ordinance 25-59), BCC Comprehensive Development Master Plan &
-- Zoning, 2025-06-26, item 7A, read in full on 2026-09-09. In order:
--
--   1. Chairman Rodriguez moved to reject staff's recommendation and approve the
--      requested 1:1 ratio; seconded by Commissioner Gilbert III.
--   2. THAT MOTION FAILED 6-4 — Steinberg, Cohen Higgins, Garcia and McGhee
--      voted "no"; Gonzalez, Hardemon and Higgins were absent.
--   3. ACA Schwaderer Raurell advised that SEVEN VOTES were needed to approve.
--   4. Senator Garcia moved to reconsider; seconded by Steinberg; PASSED 10-0.
--   5. Rodriguez restated his motion, and "the Board voted to reject staff's
--      recommendation and approve the application as presented" —
--      🔴 WITH NO TALLY RECORDED.
--
-- So two claims in the corpus had no source:
--
--   * "The Board adopted it 7 votes to 3" (Rodriguez). No tally exists for the
--     adoption. SEVEN is the number of votes the County Attorney said were
--     REQUIRED, which is the likeliest origin of the error — a requirement read
--     as a result.
--   * "voted No" placed against the adoption (Cohen Higgins, Steinberg, Garcia).
--     Each did vote No, on the motion that FAILED at step 2. How any member voted
--     at step 5 is not recorded anywhere.
--
-- ⚠ NO VOTE'S DIRECTION WAS WRONG and no chair moves. All three voted against
--   loosening LU-8H, which is what their chair 2 says; Rodriguez sponsored all
--   three steps, which is what his chair 4 says. This is precision, not polarity.
--
-- 🔴 THE RULE THIS TEACHES: A NARRATIVE SUMMARY OF A MEETING IS NOT A VOTE
--    RECORD, AND THE TALLY BESIDE THE MOTION YOU ARE READING MAY BELONG TO A
--    DIFFERENT MOTION. Same family as the recital-versus-operative trap: the
--    document is right there and still answers a question you did not ask.
--
-- ── GARCIA MOVED TO RECONSIDER, AND HIS ROW NOW SAYS SO ──────────────────────
--
-- Step 4 is his motion, and it is what let the amendment be adopted. Rewriting
-- the vote sequence while omitting his own part in it would be selective, so the
-- fact goes in, stated flatly and without a motive attached. Under most rules
-- only a member on the PREVAILING side may move to reconsider, and his side
-- prevailed at step 2, so the motion is procedurally ordinary — but that is
-- inference, and the row asserts only what the minutes say.
--
-- ⚠ A RE-AUDIT QUESTION IS OPEN ON GARCIA'S CHAIR, recorded in the todo and NOT
--   decided here: his 2 also rests on co-sponsoring R-191-26 and R-678-26, both
--   boundary-protective and both cited, so it may well stand.
-- =============================================================================

DROP TABLE IF EXISTS _cc0087_edits;
DROP TABLE IF EXISTS _cc0087_before;

CREATE TEMP TABLE _cc0087_edits AS
SELECT * FROM (VALUES
  ('d1404db5-02c6-4880-a8f5-3fe2c7d4d2d0'::uuid, 'Anthony Rodriguez',
   'The Board adopted it 7 votes to 3, as filed and without the changes its own staff had recommended.',
   'The Board adopted it as filed, without the changes its own staff had recommended; no tally is recorded for that vote.'),

  ('0d13108c-a1ad-4747-b8b4-5db47c0e6941'::uuid, 'Danielle Cohen Higgins',
   'She voted No; the Board adopted it anyway, as filed and without the changes its own staff had recommended.',
   'She voted No on the motion to reject staff''s recommendation and approve the 1-to-1 ratio, which failed 6 votes to 4; the Board reconsidered and adopted it anyway, as filed and without the changes its own staff had recommended, with no tally recorded.'),

  ('237fe767-ea76-45d3-8ded-95e623dbce8f'::uuid, 'Micky Steinberg',
   'Steinberg voted No.',
   'Steinberg voted No on the motion to reject staff''s recommendation and approve the 1-to-1 ratio, which failed 6 votes to 4.'),

  ('385f0162-a7ac-445a-9522-abe0491b65dd'::uuid, 'René Garcia',
   'Garcia voted No.',
   'Garcia voted No on the motion to reject staff''s recommendation and approve the 1-to-1 ratio, which failed 6 votes to 4. He then moved to reconsider it; that motion passed 10-0 and the Board adopted the amendment, with no tally recorded.')
) AS v(politician_id, who, old_text, new_text);

CREATE TEMP TABLE _cc0087_before AS
SELECT c.politician_id, md5(c.reasoning) AS md5_before, length(c.reasoning) AS len_before,
       array_to_string(c.sources, '|') AS sources_before
  FROM inform.politician_context c
  JOIN inform.seasons s        ON s.id = c.season_id AND s.status = 'open'
  JOIN inform.compass_topics t ON t.id = c.topic_id  AND t.topic_key = 'growth-and-development'
  JOIN _cc0087_edits e         ON e.politician_id = c.politician_id;

-- ── PRECONDITIONS ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'open' AND number = 2) THEN
    RAISE EXCEPTION 'CC_0087: Season 2 is not the open season';
  END IF;

  -- 1. every uuid resolves to the name written beside it
  SELECT count(*) INTO v_n
    FROM _cc0087_edits e
    JOIN essentials.politicians p ON p.id = e.politician_id AND p.full_name = e.who;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 politician_ids resolve to the name beside them', v_n;
  END IF;

  -- 2. four target rows
  SELECT count(*) INTO v_n FROM _cc0087_before;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 growth-and-development rows found in the open season', v_n;
  END IF;

  -- 3. 🔴 EACH OLD SENTENCE MUST BE PRESENT EXACTLY ONCE. A substring appearing
  --    twice would make `replace()` change a second place nobody read.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
   WHERE (length(c.reasoning) - length(replace(c.reasoning, e.old_text, ''))) / length(e.old_text) = 1;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 rows contain their old sentence exactly once — re-read them', v_n;
  END IF;

  -- 4. the new sentence is not already there (this file has not run)
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
   WHERE position(e.new_text in c.reasoning) > 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0087: % row(s) already carry the new sentence', v_n;
  END IF;

  -- 5. all four are published claims. @zero-scope: excludes-blanks — a 0 is a
  --    blank spoke and publishes no prose to correct.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = a.politician_id
   WHERE a.value <> 0;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 target answers are non-blank', v_n;
  END IF;

  -- 6. 🔴 THE INSTRUMENT MUST STILL BE CITED IN ALL FOUR. The corrected sentence
  --    describes matter 241888; if a row stopped citing it, the fix would be
  --    describing a vote the row no longer points at.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
   WHERE 'https://www.miamidade.gov/govaction/matter.asp?matter=241888' = ANY (c.sources);
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 rows still cite matter 241888', v_n;
  END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────
UPDATE inform.politician_context c
   SET reasoning  = replace(c.reasoning, e.old_text, e.new_text),
       updated_at = now()
  FROM _cc0087_edits e, inform.seasons s, inform.compass_topics t
 WHERE c.politician_id = e.politician_id
   AND s.id = c.season_id AND s.status = 'open'
   AND t.id = c.topic_id  AND t.topic_key = 'growth-and-development';

-- ── POST-VERIFY ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  -- 1. the new sentence is in all four, exactly once
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
   WHERE (length(c.reasoning) - length(replace(c.reasoning, e.new_text, ''))) / length(e.new_text) = 1;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: % of 4 rows carry the new sentence exactly once', v_n;
  END IF;

  -- 2. the old sentence is gone from all four
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
   WHERE position(e.old_text in c.reasoning) > 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0087: % row(s) still contain the old sentence', v_n;
  END IF;

  -- 3. 🔑 REVERSING THE EDIT MUST REPRODUCE THE ORIGINAL BYTE FOR BYTE.
  --    This is the assertion that matters: it proves ONLY the intended sentence
  --    changed. A stray character anywhere else in 1,200 words of voter-facing
  --    prose fails here, which no length or keyword check would catch.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = c.politician_id
    JOIN _cc0087_before b ON b.politician_id = c.politician_id
   WHERE md5(replace(c.reasoning, e.new_text, e.old_text)) = b.md5_before;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: only %/4 rows reverse cleanly to their original text — something else changed', v_n;
  END IF;

  -- 4. no citation moved. This file edits prose only.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_before b ON b.politician_id = c.politician_id
   WHERE array_to_string(c.sources, '|') = b.sources_before;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: %/4 rows kept their sources unchanged', v_n;
  END IF;

  -- 5. 🔴 THE UNSOURCED TALLY IS GONE FROM THE WHOLE CORPUS, not just these rows
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
   WHERE c.reasoning LIKE '%7 votes to 3%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0087: % context row(s) still claim "7 votes to 3"', v_n;
  END IF;

  -- 6. no answer changed
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'growth-and-development'
    JOIN _cc0087_edits e ON e.politician_id = a.politician_id
   WHERE (e.who = 'Anthony Rodriguez' AND a.value = 4)
      OR (e.who <> 'Anthony Rodriguez' AND a.value = 2);
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0087: %/4 answers still sit at the chair they were seated on', v_n;
  END IF;

  RAISE NOTICE 'CC_0087 OK: four LU-8H vote sentences corrected, every reversal byte-identical, sources and chairs untouched.';
END $$;

DROP TABLE _cc0087_edits;
DROP TABLE _cc0087_before;

COMMIT;
