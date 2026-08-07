-- 1601_retire_group_c_dead_host_stances.sql
--
-- Retire 8 stance rows across 4 politicians whose ONLY citation is a host that cannot be reached and
-- cannot be re-pointed. Deletes from BOTH inform.politician_answers and inform.politician_context --
-- a retirement leaves neither half behind (the shape every retirement migration since 1507 uses).
--   Rollback record: data/stance-retirement/2026-08-07-group-c-retirement-rollback.json
--   Findings record: data/stance-retirement/2026-08-07-dead-host-repoint-pass.md
--   Follows 1600, which re-pointed the 7 rows in the same queue that DID have a usable capture.
--
-- ---------------------------------------------------------------------------------------------
-- 🔴 OPERATOR RULING, AND IT IS BROADER THAN THE STANDING RULE. The rule that governed 1520, 1525
-- and 1548 is **verified absent -> retire, NEVER unsure -> retire**. Only Stephenson's 3 rows meet
-- that bar. The other 5 sit on lapsed campaign domains: the pages are GONE, which makes the claims
-- unverifiable, not disproven. The operator was told this explicitly and instructed retirement of
-- all 8 on 2026-08-07. Recording it here because a future reader comparing this migration to the
-- rule would otherwise read it as the rule being misapplied. It is a decision, not a drift.
-- ⚠ Every row is recoverable from the rollback record; re-research is the better long-term answer
-- for the 5, and nothing here forecloses it.
--
-- ---------------------------------------------------------------------------------------------
-- WHY EACH HOST CANNOT BE REPAIRED. All 8 rows are SOLE-sourced -- no co-source survives the delete.
--
--   boli.oregon.gov  (Stephenson, 3)  -- COMPOSED HOSTNAME, confirmed. Oregon serves BOLI at
--     www.oregon.gov/boli (HTTP 200). The cited host has no DNS and zero captures on any path: it
--     never existed. `clark.house.gov` shape. NOT re-pointable to the real BOLI site, because the
--     cited path is a news INDEX and a landing page is not coverage -- attributing three broad
--     characterisations to a news index would MANUFACTURE support.
--     ⚠ These 3 also have the invented URL appended into the voter-facing `reasoning` prose, so
--     Citations.jsx has been rendering a fabricated URL as body text. That ends here.
--
--   monteiro4council2022.com (Monteiro, 2) -- lapsed, no DNS. TWO captures exist (2022-01-17,
--     2023-03-15) and NEITHER carries the claims: no "retail", "restaurants", "high wages",
--     "firefighters" or "first responders" on either. Re-pointing would have cited a page that does
--     not say what the row says. The archived Priorities sub-page might, but the row cites the ROOT,
--     and sourcing a row to a page its author never used is what 1557 explicitly refused to do.
--
--   octavioforwhittier.com (Martinez, 2) -- lapsed campaign domain. No DNS, zero captures.
--   downeylegend.com       (Frometa, 1)  -- no DNS, zero captures of the cited article.
--
-- ⚠ A lapsed campaign domain is the NORMAL end state of a real campaign site. None of these four is
-- an invented outlet, and this migration must not be cited as evidence that they were.
--
-- ---------------------------------------------------------------------------------------------
-- NOT AFFECTED, verified before writing: the 7 hosts in this same queue that were never dead at all
-- (they publish an A record only on `www`, the form their citations already use -- see 1600 and the
-- probe fix in citation-host-resolve.mjs), and the 23 co-sourced rows, which each keep a working
-- citation alongside the dead host and are parked by operator ruling.
--
-- COVERAGE CHIPS: none flip, verified before writing. Downey 18->17 answers, Hawthorne 17->15,
-- Whittier 12->12, each still 5 politicians with answers, so all three keep `hasContext: true` in
-- essentials/src/lib/coverage.js. Stephenson is a statewide Oregon officeholder under no city chip.
--
-- TIMESTAMPS: Stephenson is EMPTIED to 0 answers. Her `last_stances_researched_at` is ALREADY NULL,
-- so nothing is cleared and nothing may be set -- NULL + 0 answers correctly reads as "nobody looked
-- yet" and resurfaces her in the research queue (the 1494 rule). Setting it would assert that we
-- looked and found nothing, which is the opposite of what happened.

BEGIN;

DO $$
DECLARE
  v_n            int;
  v_ctx_before   bigint;
  v_ans_before   bigint;
  v_ctx_after    bigint;
  v_ans_after    bigint;
  v_stephenson uuid := '8548989d-ff40-4b25-bb42-e1a7cbb03c88';
BEGIN
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;

  -- The exact target set, by citation. Captured once so the deletes and the guards cannot diverge.
  CREATE TEMP TABLE _doomed_1601 ON COMMIT DROP AS
  SELECT pc.politician_id, pc.topic_id
    FROM inform.politician_context pc
   WHERE EXISTS (
     SELECT 1 FROM unnest(pc.sources) s
      WHERE s LIKE '%boli.oregon.gov%'
         OR s LIKE '%monteiro4council2022%'
         OR s LIKE '%octavioforwhittier%'
         OR s LIKE '%downeylegend%');

  SELECT count(*) INTO v_n FROM _doomed_1601;
  IF v_n <> 8 THEN RAISE EXCEPTION '1601: expected 8 target rows, found %', v_n; END IF;

  SELECT count(DISTINCT politician_id) INTO v_n FROM _doomed_1601;
  IF v_n <> 4 THEN RAISE EXCEPTION '1601: expected 4 politicians, found %', v_n; END IF;

  -- Every target must be SOLE-sourced to a dead host. If a co-source survives, this is a strip, not
  -- a retirement, and deleting the row would destroy a working citation.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN _doomed_1601 d USING (politician_id, topic_id)
   WHERE EXISTS (
     SELECT 1 FROM unnest(pc.sources) s
      WHERE s NOT LIKE '%boli.oregon.gov%'
        AND s NOT LIKE '%monteiro4council2022%'
        AND s NOT LIKE '%octavioforwhittier%'
        AND s NOT LIKE '%downeylegend%');
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: % target rows carry a surviving co-source; strip, do not retire', v_n; END IF;

  -- Every target must currently have an answer, or the count arithmetic below is wrong.
  SELECT count(*) INTO v_n
    FROM _doomed_1601 d
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id = d.politician_id AND a.topic_id = d.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: % targets have no answer row', v_n; END IF;

  -- ---- the retirement: both halves ----
  DELETE FROM inform.politician_answers a
   USING _doomed_1601 d
   WHERE a.politician_id = d.politician_id AND a.topic_id = d.topic_id;

  DELETE FROM inform.politician_context pc
   USING _doomed_1601 d
   WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id;

  -- ---- post-verify on COUNTS, never on absence of error ----
  SELECT count(*) INTO v_ctx_after FROM inform.politician_context;
  SELECT count(*) INTO v_ans_after FROM inform.politician_answers;

  IF v_ctx_before - v_ctx_after <> 8 THEN
    RAISE EXCEPTION '1601: context rows fell by %, expected 8', v_ctx_before - v_ctx_after; END IF;
  IF v_ans_before - v_ans_after <> 8 THEN
    RAISE EXCEPTION '1601: answer rows fell by %, expected 8', v_ans_before - v_ans_after; END IF;

  -- Nothing may still cite any of the four hosts.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s LIKE '%boli.oregon.gov%' OR s LIKE '%monteiro4council2022%'
      OR s LIKE '%octavioforwhittier%' OR s LIKE '%downeylegend%';
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: % citations to the retired hosts survived', v_n; END IF;

  -- Stephenson is the only politician this empties, and her timestamp must STAY null.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = v_stephenson;
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: Stephenson should hold 0 answers, holds %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = v_stephenson AND last_stances_researched_at IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: Stephenson has a timestamp with 0 answers (the 1494 rule)'; END IF;

  -- No other politician may be emptied by this migration.
  SELECT count(*) INTO v_n
    FROM (SELECT DISTINCT politician_id FROM _doomed_1601) d
   WHERE d.politician_id <> v_stephenson
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = d.politician_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1601: % politicians emptied unexpectedly', v_n; END IF;

  RAISE NOTICE '1601: retired 8 rows / 4 politicians; context % -> %, answers % -> %',
    v_ctx_before, v_ctx_after, v_ans_before, v_ans_after;
END $$;

COMMIT;
