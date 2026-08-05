-- 1561_retire_mccarty_sanitation_unsupportable.sql
--
-- Retire 1 stance row: Kevin McCarty (Mayor of Sacramento) · City Sanitation and Cleanliness · 3.
-- Operator-approved 2026-08-05, after a re-source attempt failed.
--
--   Rollback: data/stance-retirement/2026-08-05-mccarty-rollback.json — the row verbatim.
--   Sweep:    data/stance-retirement/2026-08-04-nav-page-sweep.md
--
-- WHY RETIRE RATHER THAN RE-SOURCE. Migration 1560 retired 5 sibling rows sole-sourced to government
-- nav pages and deliberately left this one for a re-source attempt. The attempt was made and failed:
--
--   * The cited page, `cityofsacramento.gov/mayor`, is a nav page. Its only body prose is a two-sentence
--     bio ("Kevin McCarty was elected as the 57th Mayor of the City of Sacramento in November of 2024.
--     From 2014 to 2024, McCarty served in the State Legislature"). An earlier note in this audit called
--     it substantive on the strength of 147 name mentions / "homeless" 64 / "clean" 36 across ~19,700
--     words — that was WRONG. Those hits are the site-wide navigation menu, and so is the word count.
--     ⚠ Word counts on .gov pages are nav-inflated. Do not use them as a substance signal.
--
--   * Official candidate, FETCHED: `.../mayor-mccarty-memo/9-16-homelessness-plan-update` ("State of
--     Homelessness Update"). Genuinely mayor-specific, item-specific and substantive — a 6-point plan,
--     "1375 beds ... on track to add nearly 500 beds this year", beds 12 / shelter 13 mentions. But
--     **"sanitation" appears 0 times**, and this row's topic is City Sanitation and Cleanliness.
--
--   * Campaign candidate, FETCHED from Wayback: `mccartyformayor.com/issues/` (host now dead, no A
--     record; capture 2025-04-22, 185 name mentions). **"sanitation" 0, "clean" 1, "dumping" 1.** Its one
--     relevant passage is about the American River Parkway: "We cannot sustain this treasure if we don't
--     address dumping, camping and public safety. This is why I worked on a new law to ban illegal
--     camping, while also fighting for $25 million for the county to provide services for those in need."
--
-- 🔴 THE EVIDENCE CONTRADICTS THE ROW. The reasoning asserts his approach is "adding beds and shelter
-- rather than punitive sanitation enforcement". He authored a camping ban and has said publicly "We need
-- to enforce the law. We can't have urban camping." The "coupling enforcement with social service
-- connections" half is supported; the "rather than punitive enforcement" half is refuted. Re-pointing to
-- either candidate would attach a source that does not support the claim as written — which is the
-- defect this audit exists to remove, not a repair.
--
-- The alternative was to keep the row and rewrite the reasoning to a balanced-to-enforcement posture.
-- That changes a voter-facing stance, so it went to the operator, who chose retirement.
--
-- ⚠ McCarty holds 23 answers; this removes 1, so he does NOT drop to zero and no coverage chip is
-- affected. Sacramento keeps its chip honestly.

BEGIN;

DO $$
DECLARE
  v_n          int;
  v_ans_before bigint;
  v_ctx_before bigint;
  v_pol   uuid := 'b89b09f0-6a9f-46e5-9193-8a9de99867b0';  -- Kevin McCarty
  v_topic uuid := '7687de4f-4d0b-462a-b803-bdfb23b16b42';  -- City Sanitation and Cleanliness
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  -- Guard: the row must still be exactly what was reviewed — present, answered, and SOLE-sourced to the
  -- nav page. A second citation acquired since the review would mean this is no longer evidence-free.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = v_pol AND topic_id = v_topic
     AND sources = ARRAY['https://www.cityofsacramento.gov/mayor']::text[];
  IF v_n <> 1 THEN RAISE EXCEPTION '1561: expected 1 sole-sourced McCarty sanitation row, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = v_pol AND topic_id = v_topic;
  IF v_n <> 1 THEN RAISE EXCEPTION '1561: expected 1 matching answer, found %', v_n; END IF;

  -- ---- retire ----
  DELETE FROM inform.politician_answers WHERE politician_id = v_pol AND topic_id = v_topic;
  DELETE FROM inform.politician_context WHERE politician_id = v_pol AND topic_id = v_topic;

  -- ---- post-verify ----
  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> 1 THEN
    RAISE EXCEPTION '1561: answers did not fall by exactly 1'; END IF;
  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> 1 THEN
    RAISE EXCEPTION '1561: context rows did not fall by exactly 1'; END IF;

  -- He must NOT be emptied — 22 answers should remain, so no chip question arises.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = v_pol;
  IF v_n <> 22 THEN RAISE EXCEPTION '1561: expected 22 remaining McCarty answers, found %', v_n; END IF;

  RAISE NOTICE '1561 OK: retired 1 row, McCarty retains % answers', v_n;
END $$;

COMMIT;
