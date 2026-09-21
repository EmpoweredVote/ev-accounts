-- 1873_feldman_civil_rights_readjudicate_revision2_season2.sql
-- Brian J. Feldman / Civil Rights and Social Justice: re-adjudicate chair 1 -> chair 2 against the
-- ladder Season 2 pins (revision 2), and write the row forward. One context row + one answer row
-- INSERTED. Nothing updated, nothing deleted, Season 1 untouched.
--
-- 🔑 UNLIKE 1870/1871/1872, THE CITATIONS HERE ARE REAL. Both named instruments exist, both say what
-- the row says they say, and Feldman is genuinely attached to both. **The defect is the CHAIR, not
-- the sourcing** -- the evidence is a solid chair 2 and the row was seated at chair 1. This is the
-- [[chair_needs_evidence_for_that_chair]] failure in its purest form: real evidence establishing the
-- DIRECTION, then a chair picked past what that evidence supports.
--
-- 🔴 THE REVISION DRIFTED BETWEEN SEASONS (same as migration 1872). Season 1 pins revision 1
-- (`839b4b5b-…`); Season 2 pins revision 2 (`2010cab0-…`). The rungs differ on exactly the point this
-- adjudication turns on:
--   revision 1, chair 1: "mandate racial equity requirements in all institutions **and provide
--                         reparations**"
--   revision 2, chair 1: "mandate racial equity requirements in all institutions"
--   both, chair 2:       "strengthen civil rights enforcement and address systemic discrimination"
--   both, chair 3:       "maintain current civil rights laws while promoting equal opportunity"
-- ⚖ Revision 1's chair 1 carried a **reparations** clause that nothing in his record touches, so the
-- original seating was unevidenced on its own ladder twice over. Revision 2 drops reparations, and
-- chair 1 still requires equity requirements **in ALL institutions**.
--
-- WHAT WAS WRONG. The Season 1 reasoning reads: *"Feldman supported gender-affirming care protections
-- (voted for SB119 expanding legally protected healthcare to include gender-affirming treatments
-- 2024) and sponsored the County Board Member Antibias Training Act (SB0293 2025) requiring antibias
-- training for school board members."* Both claims are TRUE and were re-verified below. What does not
-- follow is chair 1: **one training mandate aimed at one class of public body is not "racial equity
-- requirements in all institutions"**, and it is not reparations. The reasoning is chair 2's
-- description wearing chair 1's number.
-- ⚠ The stored source `Members/Details/feldman?ys=2025RS` is a ONE-SESSION page, so it cannot carry
-- the 2024 bill it is cited for -- the standing mgaleg trap. Session-scoped URLs are used below.
--
-- EVIDENCE, re-verified 2026-09-17:
--   * **SB0293 / CH0302 (2025RS) "County Boards of Education - Antibias Training for Members
--     (County Board Member Antibias Training Act)"** -- **Feldman is the FIRST-NAMED SPONSOR** of
--     four (Feldman, Attar, Augustine, Brooks), and it was **ENACTED as Chapter 302**. It requires
--     every member of a county board of education to complete antibias training at least once per
--     term, conducted separately from other required school-employee training.
--   * **SB0119 / CH0863 (2024RS) "Legally Protected Health Care - Gender-Affirming Treatment"**
--     (Senator Lam et al.) -- **Feldman voted YEA on Third Reading, 33-13** (Senate sheet 0389), and
--     **voted NAY on the Salling floor amendment, which failed 14-29** (sheet 0317). Both are DIVIDED
--     votes, so both discriminate. 🔑 Each sheet lists the whole chamber and contains exactly ONE
--     "Feldman", so the name is unambiguous there.
--
-- ⚖ WHY CHAIR 2 ON REVISION 2.
--   * Chairs **4 and 5** (limit enforcement / eliminate affirmative action) are excluded by a
--     first-named sponsorship of a new antibias mandate.
--   * Chair **3** is "maintain current civil rights laws while promoting equal opportunity". He did
--     not maintain -- he **authored a new statutory requirement** and it became law. Chair 3 is
--     affirmatively wrong for a bill sponsor.
--   * Chair **1** requires mandating racial equity requirements **in all institutions**. His mandate
--     reaches **county boards of education** and nothing else, and it mandates **training**, not
--     equity requirements. The quantifier is the discriminator and it is not met.
--   * Chair **2**, "strengthen civil rights enforcement and address systemic discrimination", is what
--     both instruments actually do: a bias-training requirement addresses systemic discrimination
--     inside a public institution, and shielding gender-affirming care strengthens a civil-rights
--     protection against out-of-state legal jeopardy.
--   * ⚠ THE HONEST LIMIT: chair 2 is broad enough that one sponsorship and one vote sit comfortably
--     inside it; this is not a claim that he would stop at chair 2 if asked. It is the highest chair
--     his record reaches, and chair 1's quantifier is what stops it going further.
--
-- ⚠ NOT IN THIS MIGRATION: his two **Same-Sex Marriage** rows (topic
-- `c5ab4eab-702f-49b8-9277-8ea53f3835c6`), which cite the same SB119. SB0119 is gender-affirming
-- HEALTH CARE and says nothing about marriage, so both rows are sourced off-ladder, and the Season 2
-- one is already voter-facing at chair 2. The real instrument is **HB0438/CH0002 (2012) Civil
-- Marriage Protection Act**, which he co-sponsored as a Delegate -- but its enacted text carries a
-- broad religious-entity exemption (services, accommodations, FACILITIES, goods) that matches
-- revision 2's **chair 3** ("decline to perform or host") rather than chair 2. Whether co-sponsoring
-- a compromise statute seats a legislator at the compromise is a CLASS-LEVEL precedent -- every state
-- marriage-equality act carries such an exemption -- so it is held for an operator call rather than
-- decided here.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s1_rev uuid; s2_rev uuid; s2_existing int;
BEGIN
  SELECT pa.value, pa.topic_revision_id INTO s1_chair, s1_rev
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
     AND pa.topic_id      = '0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1873: expected Season 1 chair 1 for Feldman, found % -- state has moved', s1_chair;
  END IF;
  IF s1_rev IS DISTINCT FROM '839b4b5b-dd16-45a5-8dce-8e54f85165f6'::uuid THEN
    RAISE EXCEPTION 'migration 1873: Season 1 no longer pins revision 839b4b5b, found %', s1_rev;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
       AND pc.topic_id      = '0bc588c6-39e1-4084-b5de-cac909b8b762'
       AND pc.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
       AND pc.reasoning ILIKE '%SB0293%'
  ) THEN
    RAISE EXCEPTION 'migration 1873: the Season 1 row no longer cites SB0293 -- has it already been corrected?';
  END IF;

  SELECT count(*) INTO s2_existing
    FROM inform.politician_context pc
   WHERE pc.politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'
     AND pc.topic_id      = '0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_existing <> 0 THEN
    RAISE EXCEPTION 'migration 1873: Season 2 already has % row(s) for this politician/topic', s2_existing;
  END IF;

  -- Season 2 must pin revision 2, and it must differ from Season 1's pin (cf. 1872)
  SELECT sq.topic_revision_id INTO s2_rev
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id  = '0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF s2_rev IS DISTINCT FROM '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid THEN
    RAISE EXCEPTION 'migration 1873: Season 2 pins % for this topic, not revision 2 (2010cab0) -- the adjudication was written against revision 2', s2_rev;
  END IF;
  IF s2_rev = s1_rev THEN
    RAISE EXCEPTION 'migration 1873: Season 1 and Season 2 now pin the SAME revision -- this migration assumes they differ';
  END IF;

  -- the two rungs the adjudication turns on must still read as argued
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '2010cab0-1968-4f24-b74d-ca47c2f90165'
       AND sr.value = 1 AND sr.text ILIKE '%all institutions%'
  ) THEN
    RAISE EXCEPTION 'migration 1873: revision 2 chair 1 no longer says "all institutions" -- that quantifier is what excludes it';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = '2010cab0-1968-4f24-b74d-ca47c2f90165'
       AND sr.value = 2 AND sr.text ILIKE '%systemic discrimination%'
  ) THEN
    RAISE EXCEPTION 'migration 1873: revision 2 chair 2 no longer addresses systemic discrimination -- re-read before seating';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES (
  'd423151e-8477-470d-8f73-ba7d2092f714',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  '2010cab0-1968-4f24-b74d-ca47c2f90165',
  NULL,
  'Feldman is the first-named sponsor of the County Board Member Antibias Training Act (2025 SB0293, enacted as Chapter 302), which requires every member of a county board of education to complete antibias training at least once during their term, held separately from other required school training. He also voted for the 2024 law shielding gender-affirming treatment as legally protected health care (SB0119, Chapter 863), passing the Senate 33 to 13, and voted against the floor amendment that would have narrowed it, which failed 14 to 29. Writing a new antibias requirement into law goes beyond stance 3, which is to maintain the civil rights laws already on the books. It stops short of stance 1, which calls for racial equity requirements across all institutions: this mandate reaches county boards of education and no other body, and it requires training rather than equity requirements. Addressing discrimination inside a public institution and strengthening an existing civil rights protection is what stance 2 describes.',
  ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0293?ys=2025RS',
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0119?ys=2024RS',
    'https://mgaleg.maryland.gov/2024RS/votes/senate/0389.pdf',
    'https://mgaleg.maryland.gov/2024RS/votes/senate/0317.pdf'
  ]
);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES (
  'd423151e-8477-470d-8f73-ba7d2092f714',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  '2010cab0-1968-4f24-b74d-ca47c2f90165',
  NULL,
  2
);

DO $$
DECLARE ctx int; ans numeric; ans_rev uuid; bad int; s1_ctx int; s1_ans numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1873: expected exactly 1 Season 2 context row, found %', ctx;
  END IF;

  SELECT value, topic_revision_id INTO ans, ans_rev FROM inform.politician_answers
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'migration 1873: expected Season 2 chair 2, found %', ans;
  END IF;
  IF ans_rev IS DISTINCT FROM '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid THEN
    RAISE EXCEPTION 'migration 1873: the new answer is pinned to %, not revision 2', ans_rev;
  END IF;

  -- the corrected row must cite session-scoped instruments, not the one-session member page
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%Members/Details%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1873: the corrected row still leans on a one-session member page';
  END IF;

  -- history must be intact: still chair 1, still pinned to revision 1
  SELECT count(*) INTO s1_ctx FROM inform.politician_context
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1873: the Season 1 historical context row was altered or removed';
  END IF;

  SELECT value INTO s1_ans FROM inform.politician_answers
   WHERE politician_id='d423151e-8477-470d-8f73-ba7d2092f714'
     AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_revision_id='839b4b5b-dd16-45a5-8dce-8e54f85165f6';
  IF s1_ans IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1873: the Season 1 answer or its revision pin moved -- history must survive verbatim';
  END IF;
END $$;

COMMIT;
