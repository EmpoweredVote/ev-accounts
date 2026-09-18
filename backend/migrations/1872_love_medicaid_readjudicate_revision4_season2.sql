-- 1872_love_medicaid_readjudicate_revision4_season2.sql
-- Sara Love / Medicare-Medicaid: retire the fabricated citation, re-adjudicate against the ladder
-- Season 2 ACTUALLY PINS (revision 4, not revision 1), and write the row forward. One context row +
-- one answer row INSERTED. Nothing updated, nothing deleted, Season 1 untouched.
--
-- 🔴🔴 THE REVISION CHANGED BETWEEN SEASONS -- THE STORED NUMBER COULD NOT HAVE BEEN CARRIED.
-- Season 1 pins revision 1 (`92e96359-…`); **Season 2 pins revision 4 (`38bab357-…`)**. Migration
-- 1871's guard asserted the two seasons pinned the SAME revision; here they do not, so that guard is
-- INVERTED below: this migration asserts they differ and re-adjudicates against revision 4's text
-- rather than carrying an integer across two different ladders. The final number is 2 in both, which
-- is exactly why this had to be checked -- copying "2" forward would have been right by accident and
-- wrong by method.
--   revision 1, chair 2: "lower Medicare age to 55 AND expand Medicaid significantly"
--   revision 4, chair 2: "significantly expand Medicare OR Medicaid eligibility, stopping short of
--                         universal coverage"
-- ⚖ The revision-1 rung is a CONJUNCTION whose first half (the federal Medicare eligibility age) no
-- Maryland delegate can legislate -- a rung she structurally could not have evidenced. Revision 4
-- breaks the conjunction into a disjunction, and the Medicaid half IS state-reachable. So the
-- original seating was unevidenced on its own ladder, and the topic only becomes answerable for a
-- state legislator under the ladder Season 2 carries.
--
-- WHAT WAS WRONG. The Season 1 reasoning reads: *"Love supports protecting and expanding Medicaid.
-- She voted YES on SB 539 (2023) expanding Medicaid access and has consistently backed healthcare
-- safety net programs."*
--   * **SB0539 (2023) is "Economic Development - Tri-County Council for Southern Maryland -
--     Membership"**, sponsored by the Charles County Senators. It has no health content whatsoever.
--   * 🔑 **AND THERE WAS NO VOTE TO CAST.** Its status is *"In the Senate - Hearing 2/21"* -- it died
--     in Senate committee and never reached a floor of either chamber. This is what answers the
--     class-C objection that *a sponsorship index cannot test a vote*: the bill's own status can.
--     She was a Delegate; there was no House roll call on SB0539 in 2023 to vote YES on.
--   * The stored source is again `Members/Details/love02`, her SENATOR page (Senate since
--     2024-06-13), which returns 0 bills for 2021-2023 -- see migration 1871.
--
-- 🔑🔑 BUT THE PRIOR SWEEP'S "MEDICAID APPEARS IN ZERO OF HER SIX SESSIONS" WAS A VOCABULARY FALSE
-- NEGATIVE. **Maryland's statutory term is "Maryland Medical Assistance Program", not "Medicaid".**
-- Re-running the same six session pages for "medical assistance" instead of "medicaid" surfaced a
-- real, enacted, co-sponsored instrument that the first pass declared absent. A term-frequency search
-- over a corpus is only as good as the corpus's own vocabulary; this is the same defect shape as
-- reading a bill TITLE instead of its enacted text.
--
-- EVIDENCE, verified 2026-09-17:
--   * **HB1080 / CH0028 (2022RS) "Maryland Medical Assistance Program - Children and Pregnant Women
--     (Healthy Babies Equity Act)"** -- extends Medical Assistance coverage to noncitizen pregnant
--     women who would qualify but for immigration status, and their children to age 1. **Love voted
--     YEA on Third Reading, 96-40** (House vote sheet SEQ 396, legislative date 2022-03-08).
--     ⚠ A DIVIDED vote, so it discriminates; 40 Nays means agreeing with it is a position.
--     🔑 IDENTITY: "Delegate Love" is two people in this corpus (Mary Ann Love is the 2013/2014 one).
--     **The vote sheet lists every delegate and contains exactly ONE "Love"**, so the name is
--     unambiguous in that chamber on that day -- that is what settles it, not the surname.
--   * **HB0283 / CH0253 (2023RS) "Maryland Medical Assistance Program - Gender-Affirming Treatment
--     (Trans Health Equity Act)"** (crossfile SB0460/CH0252) -- **Co-Sponsor**, confirmed on her own
--     `love01?ys=2023RS` list AND on the bill page's sponsor list. Requires the Program to cover
--     gender-affirming treatment from 2024-01-01.
--
-- ⚖ WHY CHAIR 2 ON REVISION 4, and the honest limit.
--   * Chairs **4 and 5** (scale back / phase out) are excluded outright by a YEA on an expansion.
--   * Chair **1** requires expanding **Medicare to cover everyone regardless of age** -- a federal
--     single-payer instrument. She has nothing of the kind, and could not as a state delegate.
--   * Chair **3** is "improve current programs **while controlling costs**". Both instruments improve
--     the program and **neither controls costs** -- HB1080 and HB0283 both add covered population or
--     covered services. The second half of that conjunction is affirmatively unevidenced.
--   * Chair **2** is the only rung an instrument in her record actually matches: HB1080 is literally
--     an expansion of Medicaid **eligibility**, and "stopping short of universal coverage" is
--     satisfied -- she has no universal-coverage instrument at all.
--   * ⚠ THE HONEST LIMIT: the adverb **"significantly" is not evidenced**. Her record shows two
--     targeted expansions -- one population, one benefit -- not a demonstrated overhaul. Chair 2 is
--     reached because it is the only chair either instrument matches, and because chair 3 fails on a
--     whole clause while chair 2 fails only on a magnitude adverb. Stated so it can be argued with.
--     Same family as the `taxes` ladder's "significantly vs moderately" problem: a WORDING defect in
--     the rung, not a research gap in the politician.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s1_rev uuid; s2_rev uuid; s2_existing int;
BEGIN
  -- Season 1 must still be there, still chair 2, still pinned to revision 1
  SELECT pa.value, pa.topic_revision_id INTO s1_chair, s1_rev
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND pa.topic_id      = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1872: expected Season 1 chair 2 for Sara Love, found % -- state has moved', s1_chair;
  END IF;
  IF s1_rev IS DISTINCT FROM '92e96359-57a9-4c7e-a78e-a6f1af105ec6'::uuid THEN
    RAISE EXCEPTION 'migration 1872: Season 1 no longer pins revision 92e96359, found % -- re-read the ladder before writing', s1_rev;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
       AND pc.topic_id      = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
       AND pc.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
       AND pc.reasoning ILIKE '%539%'
  ) THEN
    RAISE EXCEPTION 'migration 1872: the Season 1 row no longer cites SB 539 -- has it already been corrected?';
  END IF;

  -- Season 2 must not already carry this topic for her
  SELECT count(*) INTO s2_existing
    FROM inform.politician_context pc
   WHERE pc.politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND pc.topic_id      = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_existing <> 0 THEN
    RAISE EXCEPTION 'migration 1872: Season 2 already has % row(s) for this politician/topic', s2_existing;
  END IF;

  -- 🔴 INVERTED GUARD (cf. migration 1871). Season 2 must pin revision 4, and it must NOT be the
  -- revision Season 1 pins -- the whole point of this migration is that the ladder changed and the
  -- chair was re-adjudicated against the new text rather than carried.
  SELECT sq.topic_revision_id INTO s2_rev
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id  = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
  IF s2_rev IS DISTINCT FROM '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid THEN
    RAISE EXCEPTION 'migration 1872: Season 2 pins % for this topic, not revision 4 (38bab357) -- the adjudication below was written against revision 4 and does not transfer', s2_rev;
  END IF;
  IF s2_rev = s1_rev THEN
    RAISE EXCEPTION 'migration 1872: Season 1 and Season 2 now pin the SAME revision -- this migration assumes they differ; re-read both ladders';
  END IF;

  -- and revision 4 chair 2 must still say what the reasoning argues it says
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '38bab357-9790-4cb3-a6d2-c43cbdca615b'
       AND sr.value = 2
       AND sr.text ILIKE '%eligibility%'
  ) THEN
    RAISE EXCEPTION 'migration 1872: revision 4 chair 2 no longer turns on eligibility -- the adjudication rests on that word';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES (
  'c5d2cd24-170a-4f87-8fde-84216fe62806',
  'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  '38bab357-9790-4cb3-a6d2-c43cbdca615b',
  NULL,
  'As a Delegate, Love voted for the Healthy Babies Equity Act (2022 HB1080, enacted as Chapter 28), which extends Maryland Medical Assistance Program coverage to pregnant noncitizens who would qualify for the program but for their immigration status, and to their children through age one. The House passed it 96 to 40 on third reading, and she is recorded voting Yea. She also co-sponsored the Trans Health Equity Act (2023 HB0283, Chapter 253), which requires the same program to cover gender-affirming treatment. Expanding who qualifies for Medical Assistance is what stance 2 turns on, and she has no instrument proposing universal Medicare coverage, which stance 1 requires. Stance 3 pairs improving the programs with controlling costs, and neither bill controls costs; both add covered people or covered services. The word "significantly" in stance 2 is not itself evidenced here: the record shows two targeted expansions rather than a demonstrated overhaul.',
  ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB1080?ys=2022RS',
    'https://mgaleg.maryland.gov/2022RS/votes/house/0396.pdf',
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/HB0283?ys=2023RS',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2023RS'
  ]
);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES (
  'c5d2cd24-170a-4f87-8fde-84216fe62806',
  'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  '38bab357-9790-4cb3-a6d2-c43cbdca615b',
  NULL,
  2
);

DO $$
DECLARE ctx int; ans numeric; ans_rev uuid; bad int; s1_ctx int; s1_ans numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1872: expected exactly 1 Season 2 context row, found %', ctx;
  END IF;

  SELECT value, topic_revision_id INTO ans, ans_rev FROM inform.politician_answers
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1872: expected Season 2 chair 2, found %', ans;
  END IF;
  IF ans_rev IS DISTINCT FROM '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid THEN
    RAISE EXCEPTION 'migration 1872: the new answer is pinned to %, not revision 4 -- the number would assert the wrong ladder', ans_rev;
  END IF;

  -- the corrected row must not repeat the dead citation or the love02 source
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning ILIKE '%539%' OR EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%love02%'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1872: the corrected row still carries SB 539 or the love02 source';
  END IF;

  -- history must be intact: still there, still chair 2, still pinned to revision 1, still citing 539
  SELECT count(*) INTO s1_ctx FROM inform.politician_context
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning ILIKE '%539%';
  IF s1_ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1872: the Season 1 historical context row was altered -- it must survive verbatim';
  END IF;

  SELECT value INTO s1_ans FROM inform.politician_answers
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_revision_id='92e96359-57a9-4c7e-a78e-a6f1af105ec6';
  IF s1_ans IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1872: the Season 1 answer or its revision pin moved -- history must survive verbatim';
  END IF;
END $$;

COMMIT;
