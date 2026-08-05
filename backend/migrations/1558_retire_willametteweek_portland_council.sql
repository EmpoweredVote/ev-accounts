-- 1558_retire_willametteweek_portland_council.sql
--
-- Retire all 57 Portland City Council stance rows whose sole citation is a fabricated Willamette Week
-- article. 12 politicians — the entire sitting council cohort plus the mayor.
--
--   Rollback: data/stance-retirement/2026-08-04-willametteweek-rollback.{json,md} carries every retired
--             row verbatim — politician, topic, value, reasoning and sources — so each can be reinserted
--             exactly. 8 of the 12 politicians drop to zero answers.
--   Queue:    data/stance-research/reresearch-portland/QUEUE.md
--
-- Operator-approved 2026-08-04 ("retire all 57, then queue portland as a re-research cluster").
--
-- No migration runner exists; this file records SQL applied by hand.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY — and why this is NOT a re-point
-- ---------------------------------------------------------------------------------------------------
-- Job 2 of the re-research worklist arrived labelled "composed hostname with a real twin — per-row
-- re-point-and-verify queue". That framing was wrong on both halves, and checking it changed the remedy.
--
-- 🔴 THE HOST IS REAL. `willametteweek.com` is Willamette Week's GENUINE FORMER domain: archived from
-- 1998-12-06, serving WW's own assets under `/2008/*`, and still 301-redirecting to `wweek.com` as late
-- as 2020-06 before it lapsed. It is NOT a composed hostname like `clark.house.gov`. Any sweep that
-- classifies it as invented is wrong about the host.
--
-- 🔴 BUT THE ARTICLES NEVER EXISTED. All five cited paths have the shape
-- `/news/2024/10/30/portland-{council-district-N,mayor}-candidates-answer-our-questions/`. CDX holds
-- ZERO captures of any URL containing `answer-our-questions` anywhere on wweek.com, and all five return
-- HTTP 404 at the live real domain.
--
-- 🔴 DECISIVELY, THE CLAIMED CONTENT IS ABSENT FROM WW'S REAL COVERAGE. WW's genuine reporting on these
-- races is the 2024-10-16 endorsement set (Districts 1-4 plus mayor), all five fetched live at HTTP 200.
-- Across all five, occurrences of the topics these rows assert:
--
--     immigration 0 · sanctuary 0 · ICE 0 · rent control/regulation/stabiliz 0 · zoning 0
--     voucher 0 · "affordable housing" 0
--
-- Yet the retired rows assert Local Immigration Enforcement for 9 of the 12 politicians, Rent Regulation
-- for 6, Affordable Housing for 11, Residential Zoning for 3, School Vouchers for 2. So this is not a
-- wrong address for real journalism — the journalism being cited does not exist. A re-point to the real
-- endorsements would have manufactured support, which is the defect, not the repair.
--
-- Person coverage is thin independently: **Sameer Kanal is not named in the D2 endorsement in any form**
-- (0 for "Kanal" and 0 for "Sameer"); Koyama Lane and Loretta Smith get 1 mention each, Mitch Green 2,
-- Morillo and Dan Ryan 3. WW's only per-candidate format, "city council entrance interview", covers about
-- six candidates in total — two of ours — and also carries zero immigration or zoning.
--
-- ⚠ ALL 57 ROWS ARE SOLE-SOURCED to the fabricated URL, so there is nothing to re-point alongside. This
-- is the opposite of the bilalmahmood case (1557), where 10 of 12 rows carried a live co-source. It is
-- the `newtonobserver` class with a twist: a REAL outlet, a FABRICATED article. The reasoning text of
-- every row names "Willamette Week 2024 voter guide" and embeds the dead URL inline.
--
-- ⚠ WHY NO SWEEP CAUGHT IT. The host resolves in nobody's DNS check because it is dead, but it never
-- looked invented (real outlet, real newspaper, plausible slug), and the citation-level sweep bounds
-- exposure by row rather than asking whether the cited PAGE ever existed. The decisive test here was
-- not the host at all — it was searching the real domain for the claimed topics.
--
-- ---------------------------------------------------------------------------------------------------
-- 8 OF 12 GO TO ZERO
-- ---------------------------------------------------------------------------------------------------
-- Emptied: Morillo, Avalos, Pirtle-Guiney, Zimmerman, Dunphy, Green, Kanal, Koyama Lane.
-- Reduced: Novick 9->2, Keith Wilson 10->5, Dan Ryan 9->6, Loretta Smith 5->2.
--
-- `last_stances_researched_at` is nulled for the emptied 8 ONLY — the 1494/1507/1508 rule, because a
-- timestamp with zero answers asserts research that no longer exists. The four who keep rows keep their
-- timestamps: clearing those would claim they were never researched. The set is computed from "has zero
-- answers after the delete", never hard-coded, and the count is asserted.
--
-- ⚠ FOLLOW-UP OWED, NOT DONE HERE: with two-thirds of the council at zero, Portland's `hasContext` chip
-- in `essentials/src/lib/coverage.js` may now claim coverage it does not have — the Beverly Hills
-- treatment (essentials commit ca993e74). That is a separate repo and a separate commit.

BEGIN;

DO $$
DECLARE
  v_n              int;
  v_ans_before     bigint;
  v_ans_after      bigint;
  v_ctx_before     bigint;
  v_ctx_after      bigint;
  v_nulled         int;
  v_cohort uuid[];
BEGIN
  -- Corpus counts are captured, never hard-coded: a literal drifts the moment another session lands a
  -- migration, and 1557 raced six of them.
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  CREATE TEMP TABLE ww_target AS
    SELECT DISTINCT pc.politician_id, pc.topic_id
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE s ILIKE '%willametteweek%';

  -- Guard: exact pre-state.
  SELECT count(*) INTO v_n FROM ww_target;
  IF v_n <> 57 THEN RAISE EXCEPTION '1558: expected 57 target rows, found %', v_n; END IF;

  SELECT count(DISTINCT politician_id) INTO v_n FROM ww_target;
  IF v_n <> 12 THEN RAISE EXCEPTION '1558: expected 12 politicians, found %', v_n; END IF;

  -- Every target must have a matching answer, and none may be an orphan context row.
  SELECT count(*) INTO v_n FROM ww_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1558: % target rows have no answer (orphans)', v_n; END IF;

  -- 🔴 The premise of the whole retirement: every row is sole-sourced to the fabricated URL. If any row
  -- has acquired a second citation since the review, it is no longer evidence-free and must not be
  -- retired blind.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s ILIKE '%willametteweek%')
     AND array_length(pc.sources, 1) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '1558: % rows are no longer sole-sourced — re-review before retiring', v_n; END IF;

  -- Exactly the five verified-absent URLs, nothing else.
  SELECT count(DISTINCT s) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%willametteweek%';
  IF v_n <> 5 THEN RAISE EXCEPTION '1558: expected 5 distinct fabricated URLs, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%willametteweek%'
     AND s NOT LIKE 'https://www.willametteweek.com/news/2024/10/30/portland-%-candidates-answer-our-questions/';
  IF v_n <> 0 THEN RAISE EXCEPTION '1558: % citations do not match the verified fabricated shape', v_n; END IF;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM ww_target;

  -- ---- retire ----
  DELETE FROM inform.politician_answers pa
   USING ww_target t
   WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id;

  DELETE FROM inform.politician_context pc
   USING ww_target t
   WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id;

  -- ---- null the timestamp for the emptied only ----
  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%willametteweek%';
  IF v_n <> 0 THEN RAISE EXCEPTION '1558: % willametteweek citations survived', v_n; END IF;

  SELECT count(*) INTO v_ans_after FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_after FROM inform.politician_context;
  IF v_ans_before - v_ans_after <> 57 THEN
    RAISE EXCEPTION '1558: answers fell by %, expected 57', v_ans_before - v_ans_after; END IF;
  IF v_ctx_before - v_ctx_after <> 57 THEN
    RAISE EXCEPTION '1558: context rows fell by %, expected 57', v_ctx_before - v_ctx_after; END IF;

  -- Exactly 8 politicians must now hold zero answers.
  SELECT count(*) INTO v_n FROM unnest(v_cohort) AS c(id)
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id);
  IF v_n <> 8 THEN RAISE EXCEPTION '1558: expected 8 politicians emptied to zero, found %', v_n; END IF;

  -- No emptied politician may keep a research timestamp, and no surviving one may lose it.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1558: % emptied politicians still carry a research timestamp', v_n; END IF;

  RAISE NOTICE '1558 OK: retired 57 rows, 12 politicians, 8 emptied, % timestamps nulled', v_nulled;
  DROP TABLE ww_target;
END $$;

COMMIT;
