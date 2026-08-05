-- 1560_retire_nav_page_sourced_stances.sql
--
-- Retire 5 stance rows sole-sourced to a government navigation page. Operator-approved 2026-08-04
-- ("retire the 5, re-source McCarty").
--
--   Rollback: data/stance-retirement/2026-08-04-nav-page-retirements-rollback.json — every row verbatim.
--   Sweep:    data/stance-retirement/2026-08-04-nav-page-sweep.md
--
-- Follows the ruling that landing pages don't count as coverage (essentials f0b26b4e). Each page below
-- was FETCHED and searched; the verdict rests on what the page contains, not on its URL shape.
--
--   * `lowellma.gov/council` — Robinson, Descoteaux, Mercier, all Affordable Housing. Page names each
--     twice, as a roster. **"affordable" 0 occurrences, "mill" 0**, "housing" 1 — while the three rows
--     claim backed housing projects, mill redevelopment and, for Descoteaux, that "his votes reflect a
--     pro-development stance". No vote is identified anywhere.
--   * `plano.gov/city-council` — Lavine, Taxation and Public Spending. Page names him twice.
--     **"tax" 0, "budget" 0, "spending" 0** — and the entire claim is about tax rates and budget scrutiny.
--   * `bloomington.in.gov/mayor` — Thomson, Healthcare Access. **"healthcare" 0**, "health" 1.
--     🔴 And the reasoning is an EMPTY STRING: this row asserted a compass value to voters with no
--     stated basis whatsoever. The worst single row found in this audit.
--
-- NO CHIP BREAKS, and that is proven rather than assumed (the ca993e74 note — join occupancy through
-- office_current_holder → offices → chambers → governments, never politicians.office_id):
--   Lowell   12 seated, 11 with answers → 9,  20 answers → 17
--   Plano     8 seated,  8 with answers → 8,  30 answers → 29
--   Bloomington  Thomson 20 answers → 19; its coverage.js entry is address-based anyway
--
-- ⚠ 2 politicians drop to zero answers (Robinson 1→0, Descoteaux 1→0). `last_stances_researched_at`
-- was ALREADY NULL for all five, so the null-if-emptied step is a no-op here; it is retained for
-- correctness per rule 1494/1507/1508 and asserted afterwards.
--
-- ⚠ McCARTY IS DELIBERATELY NOT TOUCHED. The instruction was to re-source rather than retire his
-- City Sanitation and Cleanliness row, and that could not be done faithfully — see
-- `not_retired_pending_decision` in the rollback JSON. In short: the official homelessness memo is real
-- and substantive but says "sanitation" 0 times, and the archived campaign issues page CONTRADICTS the
-- row's "rather than punitive sanitation enforcement" clause (he authored a camping ban). Re-pointing to
-- either would attach a source that does not support the claim as written.

BEGIN;

DO $$
DECLARE
  v_n          int;
  v_ans_before bigint;
  v_ans_after  bigint;
  v_ctx_before bigint;
  v_ctx_after  bigint;
  v_nulled     int;
  v_cohort uuid[] := ARRAY[
    '246e6b71-e8ad-44bb-aa5c-10228d2c056a',  -- Corey Robinson
    'b7015fbc-6173-48bc-99ba-d0363b771048',  -- John Descoteaux
    'ef52f3fd-dc4d-4a4a-8320-fbae613a4baa',  -- Rita Mercier
    'ecef0481-27c7-4955-b822-83d64c7ef63f',  -- Steve Lavine
    '1c6dbdaf-e110-48d3-9b88-27f911d9521f'   -- Kerry Thomson
  ]::uuid[];
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  CREATE TEMP TABLE nav_target (politician_id uuid, topic_id uuid, url text);
  INSERT INTO nav_target VALUES
    ('246e6b71-e8ad-44bb-aa5c-10228d2c056a','669cac97-66a6-4087-b036-936fbe62efb3','https://www.lowellma.gov/council'),
    ('b7015fbc-6173-48bc-99ba-d0363b771048','669cac97-66a6-4087-b036-936fbe62efb3','https://www.lowellma.gov/council'),
    ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa','669cac97-66a6-4087-b036-936fbe62efb3','https://www.lowellma.gov/council'),
    ('ecef0481-27c7-4955-b822-83d64c7ef63f','f7e5678d-dadd-4556-a2fc-446e24642ceb','https://www.plano.gov/city-council'),
    ('1c6dbdaf-e110-48d3-9b88-27f911d9521f','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','https://bloomington.in.gov/mayor');

  -- Guard: each target must exist, still cite exactly that page, and be SOLE-sourced to it. A row that
  -- has since gained a second citation is no longer evidence-free and must not be retired blind.
  SELECT count(*) INTO v_n
    FROM nav_target t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   WHERE pc.sources = ARRAY[t.url]::text[];
  IF v_n <> 5 THEN RAISE EXCEPTION '1560: expected 5 sole-sourced nav rows, found %', v_n; END IF;

  -- Each must have a matching answer (no orphan context rows in scope).
  SELECT count(*) INTO v_n FROM nav_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1560: % targets have no answer', v_n; END IF;

  -- ---- retire ----
  DELETE FROM inform.politician_answers pa USING nav_target t
   WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id;

  DELETE FROM inform.politician_context pc USING nav_target t
   WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id;

  -- ---- null the timestamp for any of these emptied to zero (no-op here; already NULL) ----
  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;

  -- ---- post-verify ----
  SELECT count(*) INTO v_ans_after FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_after FROM inform.politician_context;
  IF v_ans_before - v_ans_after <> 5 THEN
    RAISE EXCEPTION '1560: answers fell by %, expected 5', v_ans_before - v_ans_after; END IF;
  IF v_ctx_before - v_ctx_after <> 5 THEN
    RAISE EXCEPTION '1560: context rows fell by %, expected 5', v_ctx_before - v_ctx_after; END IF;

  -- Exactly 2 of the five must now hold zero answers (Robinson, Descoteaux).
  SELECT count(*) INTO v_n FROM unnest(v_cohort) AS c(id)
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id);
  IF v_n <> 2 THEN RAISE EXCEPTION '1560: expected 2 politicians emptied to zero, found %', v_n; END IF;

  -- No emptied politician may retain a research timestamp.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1560: % emptied politicians still carry a timestamp', v_n; END IF;

  -- The 5 targeted rows must be gone.
  SELECT count(*) INTO v_n
    FROM nav_target t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION '1560: % targeted rows survive', v_n; END IF;

  -- 🔴 These nav pages are STILL cited by 12 other rows, and that is expected and out of scope: those
  -- rows pair the nav page with a co-source, so they are not evidence-free and a blanket "nobody cites
  -- this page" assertion would (and did, in draft) fail the migration wrongly.
  --   lowellma.gov/council      14 rows total, 3 retired here, 11 co-sourced remain
  --   bloomington.in.gov/mayor   2 rows total, 1 retired here,  1 co-sourced remains
  --   plano.gov/city-council     1 row  total, 1 retired here,  0 remain
  -- ⚠ Those 12 are a FOLLOW-UP QUEUE, not a clean bill of health: the 1548 lesson is that a worthless
  -- citation sharing a row with a plausible one is invisible to row-level checks. Detect per CITATION.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN ('https://www.lowellma.gov/council','https://www.plano.gov/city-council','https://bloomington.in.gov/mayor');
  IF v_n <> 12 THEN RAISE EXCEPTION '1560: expected 12 co-sourced nav citations to remain, found %', v_n; END IF;

  RAISE NOTICE '1560 OK: retired 5 rows, 2 emptied, % timestamps nulled', v_nulled;
  DROP TABLE nav_target;
END $$;

COMMIT;
