-- 1545_state_scope_criminal_justice.sql
--
-- Declare `Criminal Justice Approach` applicable to STATE officials, by adding the missing `state` row to
-- inform.compass_topic_roles. Third in the series: 1543 gave it `federal`, 1544 did the same job for
-- `Affordable Housing` at state tier, this completes the pattern.
--
--   Review:   data/stance-research/pretenure-reresearch/SCOPE-DECISION.md
--   Rollback: DELETE FROM inform.compass_topic_roles
--              WHERE topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND role_scope = 'state';
--             Exactly reversible: this migration inserts that one row and nothing else.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1545_state_scope_criminal_justice.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- `Criminal Justice Approach` was `judicial`-only until 1543 added `federal`. It still had no `state` row,
-- so **140 researched stances held by state legislators could never display** -- the largest remaining
-- addable bucket. States own most of the criminal justice system: they write the sentencing codes, run the
-- prisons and parole boards, and set bail and juvenile law. The role table was under-scoped, not the
-- stances wrong -- the same finding as 1543 and 1544.
--
-- **This changes no stance data.** It makes 140 existing rows visible on the profiles they already belong to.
--
-- After this, the topic is `federal + state + judicial`. It deliberately has **no `local` row**, so
-- ⚠ **37 local-tier answers on this topic remain out of scope** and are NOT addressed here. Whether a city
-- councillor or county official should be asked "when someone breaks the law, what matters most?" is a
-- separate call -- county sheriffs and DAs plausibly yes, a city zoning board no -- and the answer depends
-- on which local offices, not on the topic alone.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE `is_required` GATE, RE-MEASURED AGAIN
-- ---------------------------------------------------------------------------------------------------
-- `public.get_compass_completeness` counts required topics with `AND ctr.is_required = true`, and
-- `public.run_empower_preflight` turns an incomplete compass into `eligible: false` /
-- `CALIBRATION_INCOMPLETE`. This row moves the STATE bar from 27 to 28.
-- Re-checked on production immediately before writing: **0 connected profiles have `candidate_role` set and
-- there are 0 empowered profiles**, so nobody can be demoted -- preflight fails earlier on `ROLE_NOT_SET`.
-- `is_required = true` stays consistent with all 83 rows now in the table (still not one `false`).
-- ⚠ Expected: the first state-role candidate sees `required` = 28. To surface a topic WITHOUT touching the
-- completeness denominator, use `is_required = false` -- the display flags ignore that column.
--
-- ---------------------------------------------------------------------------------------------------
-- ⚠ WHY THIS FILE DOES NOT ASSERT AN ABSOLUTE `politician_answers` COUNT
-- ---------------------------------------------------------------------------------------------------
-- 1543 and 1544 both guarded "stance data untouched" as `count(*) = 33175`. That was true when they ran and
-- is ALREADY STALE: between 1544 and this file, another session retired 4 stance rows (answers 33,175 ->
-- 33,171 and context 33,721 -> 33,717, orphans still 0 -- a clean retirement, no migration file committed
-- yet). Three sessions write this database concurrently, so a hard-coded total is a guard that fails for a
-- reason unrelated to the migration. This file captures the counts at the START of its own transaction and
-- asserts they are UNCHANGED at the end, which is what "touches no stance data" actually means.

BEGIN;

CREATE TEMP TABLE _scope_1545 (topic_title text, topic_id uuid, role_scope text) ON COMMIT DROP;
INSERT INTO _scope_1545 (topic_title, topic_id, role_scope) VALUES
  ('Criminal Justice Approach', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 'state');

-- Snapshot, rather than hard-code, the counts this migration must not move.
CREATE TEMP TABLE _before_1545 AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS n_answers,
       (SELECT count(*) FROM inform.politician_context) AS n_context;

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- Identifier must match the expected title and be live. Derive-then-verify, never recall.
  SELECT string_agg(s.topic_title || ' / ' || COALESCE(t.title, '(no such topic)'), '; ') INTO v_bad
    FROM _scope_1545 s LEFT JOIN inform.compass_topics t ON t.id = s.topic_id
   WHERE t.id IS NULL OR t.title <> s.topic_title OR t.is_live IS NOT TRUE;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'topic_id mismatch, missing, or not live: %', v_bad; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics WHERE title = 'Criminal Justice Approach';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 topic titled Criminal Justice Approach, found %', v_n; END IF;

  -- Must currently LACK a state row.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1545 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 pre-existing state rows, found %', v_n; END IF;

  -- Must already have SOME role row: a topic with none already applies to all tiers, so inserting one
  -- would silently NARROW it instead of widening it.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r JOIN _scope_1545 s ON s.topic_id = r.topic_id;
  IF v_n = 0 THEN RAISE EXCEPTION 'topic has no role rows, so it already applies to all tiers — inserting would NARROW it'; END IF;

  -- 1543's federal row and the original judicial row must both still be there.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles
   WHERE topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND role_scope IN ('federal', 'judicial');
  IF v_n <> 2 THEN RAISE EXCEPTION 'expected federal+judicial rows to be present, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'state' AND ctr.is_required;
  IF v_n <> 27 THEN RAISE EXCEPTION 'expected 27 state required topics before the change, found %', v_n; END IF;
END $$;

-- ---- insert ----------------------------------------------------------------------------------------
INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
SELECT topic_id, role_scope, true FROM _scope_1545;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_af bool; v_as bool; v_al bool; v_aj bool; v_a int; v_c int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1545 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope
   WHERE r.is_required;
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected the state row present and required, found %', v_n; END IF;

  -- State required count moves by exactly 1; no other tier may move.
  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='state' AND ctr.is_required;
  IF v_n <> 28 THEN RAISE EXCEPTION 'expected 28 state required topics after the change, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='federal' AND ctr.is_required;
  IF v_n <> 26 THEN RAISE EXCEPTION 'federal required count moved (expected 26, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='local' AND ctr.is_required;
  IF v_n <> 22 THEN RAISE EXCEPTION 'local required count moved (expected 22, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='judicial' AND ctr.is_required;
  IF v_n <> 8 THEN RAISE EXCEPTION 'judicial required count moved (expected 8, found %) — it must not', v_n; END IF;

  -- Recompute the display flags exactly as the API does: federal+state+judicial true, local FALSE.
  SELECT bool_or(role_scope='federal'), bool_or(role_scope='state'),
         bool_or(role_scope='local'),   bool_or(role_scope='judicial')
    INTO v_af, v_as, v_al, v_aj
    FROM inform.compass_topic_roles WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF NOT (v_af AND v_as AND v_aj) THEN
    RAISE EXCEPTION 'expected federal+state+judicial to apply, got f=% s=% j=%', v_af, v_as, v_aj;
  END IF;
  IF COALESCE(v_al, false) THEN RAISE EXCEPTION 'a local row appeared — this migration must not add one'; END IF;

  -- Stance data must be untouched, measured against this transaction's own snapshot rather than a
  -- hard-coded total that another session can invalidate.
  SELECT n_answers, n_context INTO v_a, v_c FROM _before_1545;
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> v_a THEN RAISE EXCEPTION 'politician_answers moved from % to % — this migration must not touch stance data', v_a, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context;
  IF v_n <> v_c THEN RAISE EXCEPTION 'politician_context moved from % to % — this migration must not touch stance data', v_c, v_n; END IF;
END $$;

-- Report: state stances made displayable, and the local ones knowingly left out of scope.
-- ⚠ governments.type is UPPERCASE; a case-sensitive comparison buckets everyone as local.
SELECT
  count(*) FILTER (WHERE upper(g.type) = 'STATE')                                AS state_now_in_scope,
  count(*) FILTER (WHERE upper(g.type) NOT IN ('STATE','NATIONAL','FEDERAL'))     AS local_still_out_of_scope
  FROM inform.politician_answers a
  JOIN essentials.office_terms ot ON ot.politician_id = a.politician_id
  JOIN essentials.offices o   ON o.id  = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
 WHERE a.topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';

COMMIT;
