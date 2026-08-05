-- 1562_retire_lowellsun_composed_citations.sql
--
-- Retire all 17 Lowell stance rows citing `lowellsun.com`. 9 politicians — nine of Lowell's twelve
-- seated officials, including the mayor. Operator-approved 2026-08-05.
--
--   Rollback: data/stance-retirement/2026-08-05-lowellsun-rollback.json carries every retired row
--             verbatim — politician, topic, value, reasoning, sources — so each can be reinserted.
--   Sweep:    data/stance-retirement/2026-08-04-nav-page-sweep.md (how this was found)
--
-- ---------------------------------------------------------------------------------------------------
-- WHY — a REAL outlet with INVENTED articles. This is a new shape.
-- ---------------------------------------------------------------------------------------------------
-- `lowellsun.com` is The Lowell Sun, a real newspaper, and the host is LIVE (root HTTP 200). The prior
-- six invented-source clusters were invented HOSTS (medfordmirror.com, newtonvillearea.com,
-- alhambraource.com, walthamtribunenews.com, walthamatch.com, newtonobserver.com) and every one was
-- catchable by a DNS or host-reachability sweep. This one is not: the host resolves, serves, and is
-- exactly who it claims to be.
--
-- What does not exist is the ARTICLES. All 15 cited paths:
--   * return **HTTP 404** on the live site, and
--   * have **zero Wayback captures** — never archived, not once.
--
-- Control run in the same session, same conditions (the clark.house.gov lesson — never trust an
-- unverified control): `lowellsun.com/2023/05*` and `/2023/08*` are **densely** archived, including
-- `/amp/` and `?share=facebook` variants of ordinary stories (Aerosmith farewell tour, arrest logs, a
-- CDC leprosy warning). Real Lowell Sun articles from those exact months get captured. These 15 did not,
-- because they were never published. The slugs read as generated headlines:
-- `lowell-council-rent-stabilization`, `vesna-nuon-sanctuary-city`, `rita-mercier-homelessness`,
-- `lowell-data-center-moratorium`, `lowell-launches-housing-first-initiative`.
--
-- 🔴 WHY EVERY PRIOR SWEEP MISSED IT — AND THIS IS THE GENERALISABLE PART. **Not one of the 17 rows was
-- sole-sourced to lowellsun.com.** Each fabricated article sat beside a plausible-looking `.gov` page, so
-- every row-level check saw a resolvable co-source and moved on. Identical blind spot to migration 1548
-- (newtonobserver), one layer deeper: there the co-source was a composed city path, here it is a real
-- nav page. It only surfaced because migration 1560 cleaned up the nav pages and left these 12 rows
-- looking thin enough to chase.
--   ⚠ Host-level reachability sweeps CANNOT find this class. A live host + a 404 path + no capture is the
--     signature, and it must be tested per CITATION with an archived control.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY ALL 17 AND NOT JUST THE 3
-- ---------------------------------------------------------------------------------------------------
--   * **3 rows are WHOLLY composed** — every citation invented, no other source at all:
--     Kimberly Scott / Data Center, Rita Mercier / Homelessness Response, Vesna Nuon / Local Immigration.
--   * **14 rows** paired a fabricated article with `lowellma.gov/council` or `lowellma.gov/mayor`. The
--     operator ruled on 2026-08-04 that **landing pages do not count as coverage** (essentials f0b26b4e,
--     and migration 1560 retired 3 Lowell rows sourced to that same council page). Removing the
--     fabricated article therefore leaves no citation that evidences anything. Retiring them is the
--     existing ruling applied transitively, not a new judgement.
--
-- ⚠ ALL 9 POLITICIANS DROP TO ZERO ANSWERS, and the 17 rows are Lowell's ENTIRE remaining stance
-- coverage (17 of 17 answers across the 12 seated officials). Lowell therefore goes from 9 stanced
-- officials to **0**, and its `hasContext` chip is flipped false in the same batch (essentials
-- src/lib/coverage.js) — unlike Newton, where the chip was left standing while survivors existed.
--
-- `last_stances_researched_at` was already NULL for all 9, so the null-if-emptied step is a no-op here;
-- it is retained for correctness (rule 1494/1507/1508) and asserted afterwards.

BEGIN;

DO $$
DECLARE
  v_n          int;
  v_ans_before bigint;
  v_ctx_before bigint;
  v_nulled     int;
  v_cohort uuid[];
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  CREATE TEMP TABLE ls_target AS
    SELECT pc.politician_id, pc.topic_id
      FROM inform.politician_context pc
     WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s ILIKE '%lowellsun%');

  -- Guard: exact pre-state.
  SELECT count(*) INTO v_n FROM ls_target;
  IF v_n <> 17 THEN RAISE EXCEPTION '1562: expected 17 target rows, found %', v_n; END IF;

  SELECT count(DISTINCT politician_id) INTO v_n FROM ls_target;
  IF v_n <> 9 THEN RAISE EXCEPTION '1562: expected 9 politicians, found %', v_n; END IF;

  SELECT count(DISTINCT s) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%lowellsun%';
  IF v_n <> 15 THEN RAISE EXCEPTION '1562: expected 15 distinct fabricated URLs, found %', v_n; END IF;

  -- Every target must have a matching answer (no orphan context rows in scope).
  SELECT count(*) INTO v_n FROM ls_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1562: % target rows have no answer', v_n; END IF;

  -- 🔴 The premise: no surviving citation may be anything other than the two Lowell nav pages already
  -- ruled non-evidence. If a row has acquired a REAL third-party source since the review, it is no
  -- longer evidence-free and must not be retired blind.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE (pc.politician_id, pc.topic_id) IN (SELECT politician_id, topic_id FROM ls_target)
     AND s NOT ILIKE '%lowellsun%'
     AND s NOT IN ('https://www.lowellma.gov/council', 'https://lowellma.gov/mayor');
  IF v_n <> 0 THEN RAISE EXCEPTION '1562: % surviving citations are not the known nav pages — re-review', v_n; END IF;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM ls_target;

  -- ---- retire ----
  DELETE FROM inform.politician_answers pa USING ls_target t
   WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id;

  DELETE FROM inform.politician_context pc USING ls_target t
   WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id;

  -- ---- null the timestamp for the emptied (no-op here; already NULL for all 9) ----
  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%lowellsun%';
  IF v_n <> 0 THEN RAISE EXCEPTION '1562: % lowellsun citations survived', v_n; END IF;

  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> 17 THEN
    RAISE EXCEPTION '1562: answers did not fall by exactly 17'; END IF;
  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> 17 THEN
    RAISE EXCEPTION '1562: context rows did not fall by exactly 17'; END IF;

  -- All 9 must now hold zero answers.
  SELECT count(*) INTO v_n FROM unnest(v_cohort) AS c(id)
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id);
  IF v_n <> 9 THEN RAISE EXCEPTION '1562: expected 9 politicians emptied to zero, found %', v_n; END IF;

  -- No emptied politician may retain a research timestamp.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1562: % emptied politicians still carry a timestamp', v_n; END IF;

  -- Lowell must now hold zero stance answers, which is what forces the chip flip.
  SELECT count(*) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o  ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN inform.politician_answers pa ON pa.politician_id = och.politician_id
   WHERE g.geo_id = '2537000';
  IF v_n <> 0 THEN RAISE EXCEPTION '1562: expected Lowell to hold 0 stance answers, found %', v_n; END IF;

  RAISE NOTICE '1562 OK: retired 17 rows, 9 emptied, % timestamps nulled, Lowell at zero', v_nulled;
  DROP TABLE ls_target;
END $$;

COMMIT;
