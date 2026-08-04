-- 1547_reresearch_corman_residential_zoning.sql
--
-- First row restored by the re-research worklist: Craig A. Corman (Mayor, Beverly Hills) /
-- Residential Zoning = 3, on evidence that has nothing to do with the citations migration 1538 retired.
--
--   Review:   data/stance-research/reresearch-beverly-hills/FINDINGS.md
--   Row:      data/stance-research/reresearch-beverly-hills/rows.csv
--   Rollback: DELETE FROM inform.politician_answers
--              WHERE politician_id = '1221c215-2b80-46f7-b980-c04f25c5866f'
--                AND topic_id      = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
--             DELETE FROM inform.politician_context WHERE <same pair>;
--             Exactly reversible: this migration inserts those two rows and nothing else.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1547_reresearch_corman_residential_zoning.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- Migration 1538 emptied all five Beverly Hills councilmembers because every one of their rows cited
-- URLs that never existed (`bhcourier.com/article/<slug>` — hard 404 today, never captured by Wayback,
-- on a host where Wayback holds thousands of siblings). This restores ONE of those spokes from genuinely
-- new sources, which is the rule 1508 set: re-research must not return to the retired citations.
--
-- Chair 3 is "Allow multifamily and mixed-use near commercial corridors while protecting most
-- residential zones." Beverly Hills' Transit-Oriented Development Alternative Plan does exactly that,
-- and Corman is quoted describing it in his own words:
--
--   * <https://beverlypress.com/2026/06/beverly-hills-approves-transit-plan-for-sb-79/> — the plan moves
--     50% of the SB 79 housing density into the mixed-use overlay sites on Wilshire Boulevard east of
--     La Cienega. Corman: "We essentially have taken as much density as we can out of our single-family
--     neighborhoods, trying to protect our single-family neighborhoods, and we've been able to concentrate
--     it on a very small area east of La Cienega where there are no single-family neighborhoods, next to
--     the new Metro subway stop."
--   * <https://beverlypress.com/2026/07/corman-charts-course-for-the-future-of-beverly-hills/> — TODAP
--     "seeks to concentrate future housing around the Wilshire/La Cienega Metro station while reducing
--     development pressure on single-family neighborhoods".
--
-- Adjacent chairs were tested and excluded: 2 is modest duplex/ADU infill with design review, and this is
-- concentrated multifamily; 4 is broad by-right upzoning, and the plan deliberately narrows where density
-- lands. Where the evidence could NOT separate adjacent chairs it was left blank instead — Corman's
-- homelessness and transportation statements name no strategy, so both were skipped rather than guessed.
--
-- ⚠ The bill number travels with the source that carries it. The mayor-profile article says "Senate Bill
-- 29"; the transit-plan article, the city's agenda brief and the SCAG map all say SB 79. The reasoning
-- names SB 79 and cites the article that has it verbatim — the same trap as the Bentz roll-call row.
--
-- ✅ Every distinctive claim term in the reasoning was confirmed present in the cited pages' RAW HTML by
-- `node scripts/verify-reresearch-rows.mjs` (19/19). That check earned its place immediately: it rejected
-- an earlier draft whose words "backed", "state-mandated" and "concentrated" appear on neither page.
-- This is the standard 1542 established — a reasoning must be carried by the source beside it, not merely
-- be true.

BEGIN;

CREATE TEMP TABLE _row_1547 (politician_id uuid, politician text, topic_id uuid, topic text, value numeric) ON COMMIT DROP;
INSERT INTO _row_1547 VALUES (
  '1221c215-2b80-46f7-b980-c04f25c5866f', 'Craig A. Corman',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'Residential Zoning',
  3
);

CREATE TEMP TABLE _before_1547 AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS n_answers,
       (SELECT count(*) FROM inform.politician_context) AS n_context;

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_txt text;
BEGIN
  -- Derive-then-verify both identifiers against their expected names.
  SELECT p.full_name INTO v_txt FROM essentials.politicians p JOIN _row_1547 r ON r.politician_id = p.id;
  IF v_txt IS DISTINCT FROM (SELECT politician FROM _row_1547) THEN
    RAISE EXCEPTION 'politician uuid resolves to %, not the expected name', COALESCE(v_txt, '(missing)');
  END IF;

  SELECT t.title INTO v_txt FROM inform.compass_topics t JOIN _row_1547 r ON r.topic_id = t.id WHERE t.is_live AND t.is_active;
  IF v_txt IS DISTINCT FROM (SELECT topic FROM _row_1547) THEN
    RAISE EXCEPTION 'topic uuid resolves to %, not a live "Residential Zoning"', COALESCE(v_txt, '(missing or not live)');
  END IF;

  -- The topic must apply to the LOCAL tier or the answer could never display on a city officeholder's
  -- compass — the out-of-tier defect that 1543-1545 spent three migrations shrinking.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles cr JOIN _row_1547 r ON r.topic_id = cr.topic_id
   WHERE cr.role_scope = 'local';
  IF v_n = 0 THEN RAISE EXCEPTION 'topic has no local role row — this answer would never display'; END IF;

  -- Corman must actually hold a Beverly Hills seat right now (migration 1546 territory).
  SELECT count(*) INTO v_n
    FROM essentials.current_office_holders coh
    JOIN _row_1547 r ON r.politician_id = coh.politician_id
    JOIN essentials.offices o ON o.id = coh.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'City of Beverly Hills, California, US';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected Corman to currently hold a Beverly Hills seat, found %', v_n; END IF;

  -- Must be an INSERT: 1538 deleted both rows, so anything present means someone else got here first.
  SELECT count(*) INTO v_n FROM inform.politician_answers a JOIN _row_1547 r
    ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'an answer already exists for this pair — reconcile by hand'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c JOIN _row_1547 r
    ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'a context row already exists for this pair — reconcile by hand'; END IF;

  -- The value must be a whole chair. politician_answers_value_half_step PERMITS 0.5 steps, so the guard
  -- against another fractional-stance incident has to live here, in the migration.
  SELECT count(*) INTO v_n FROM _row_1547 WHERE value <> round(value) OR value < 1 OR value > 5;
  IF v_n <> 0 THEN RAISE EXCEPTION 'value must be a discrete 1-5 chair'; END IF;
END $$;

-- ---- insert ----------------------------------------------------------------------------------------
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, topic_id, value FROM _row_1547;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id,
       'On the Transit-Oriented Development Alternative Plan, said the council has taken as much density '
    || 'as it can out of single-family neighborhoods and can concentrate it next to the new Metro subway '
    || 'stop; the plan moves half the housing density Senate Bill 79 requires near transit onto mixed-use '
    || 'overlay sites east of La Cienega',
       ARRAY['https://beverlypress.com/2026/06/beverly-hills-approves-transit-plan-for-sb-79/',
             'https://beverlypress.com/2026/07/corman-charts-course-for-the-future-of-beverly-hills/']
  FROM _row_1547;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_a int; v_c int; v_srcs text[];
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a JOIN _row_1547 r
    ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id AND a.value = r.value;
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 answer at the stated chair, found %', v_n; END IF;

  -- No orphans, in either direction: every answer needs its context and vice versa.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE c.politician_id IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '% answer(s) without context — orphan', v_n; END IF;

  SELECT sources INTO v_srcs FROM inform.politician_context c JOIN _row_1547 r
    ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF array_length(v_srcs, 1) <> 2 THEN RAISE EXCEPTION 'expected 2 sources, found %', array_length(v_srcs, 1); END IF;

  -- Never re-cite the retired host, and never store a bare homepage: both are gate classes upstream.
  IF EXISTS (SELECT 1 FROM unnest(v_srcs) s WHERE s ILIKE '%bhcourier.com%') THEN
    RAISE EXCEPTION 'a retired bhcourier.com citation came back — that host is the composed-URL defect';
  END IF;
  IF EXISTS (SELECT 1 FROM unnest(v_srcs) s WHERE s !~ '^https://[^/]+/.+') THEN
    RAISE EXCEPTION 'a source is not a pathed https URL (bare host = PRIMARY_SITE_NO_PATH)';
  END IF;

  -- Exactly one answer and one context row added, nothing else touched.
  SELECT n_answers, n_context INTO v_a, v_c FROM _before_1547;
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> v_a + 1 THEN RAISE EXCEPTION 'politician_answers moved % -> %, expected exactly +1', v_a, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context;
  IF v_n <> v_c + 1 THEN RAISE EXCEPTION 'politician_context moved % -> %, expected exactly +1', v_c, v_n; END IF;

  -- No fractional values anywhere in the corpus after this write.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE value <> round(value);
  IF v_n <> 0 THEN RAISE EXCEPTION '% fractional stance value(s) present', v_n; END IF;
END $$;

DROP TABLE _before_1547;

-- Report: Beverly Hills' compass coverage after this row. Four of five councilmembers still hold zero,
-- and 24 of their retired spokes remain PENDING re-research -- not blank, not researched.
SELECT p.full_name, o.title,
       count(a.topic_id) AS compass_answers
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  JOIN essentials.current_office_holders coh ON coh.office_id = o.id
  JOIN essentials.politicians p ON p.id = coh.politician_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = p.id
 WHERE g.name = 'City of Beverly Hills, California, US' AND ch.name = 'City Council'
 GROUP BY p.full_name, o.title
 ORDER BY compass_answers DESC, p.full_name;

COMMIT;
