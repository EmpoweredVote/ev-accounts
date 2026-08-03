-- 1544_state_scope_affordable_housing.sql
--
-- Declare `Affordable Housing` applicable to STATE officials, by adding the missing `state` row to
-- inform.compass_topic_roles. Completes the pair with 1543, which added the `federal` row.
--
--   Review:   data/stance-research/pretenure-reresearch/SCOPE-DECISION.md
--   Rollback: DELETE FROM inform.compass_topic_roles
--              WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND role_scope = 'state';
--             Exactly reversible: this migration inserts that one row and nothing else.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1544_state_scope_affordable_housing.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- `Affordable Housing` carried only a `local` row until 1543 added `federal`. It still had no `state` row,
-- so **712 researched housing stances held by state legislators could never display** -- the single largest
-- out-of-tier bucket in the corpus, larger than everything 1543 fixed (271). States plainly legislate
-- housing: they run the LIHTC allocating agencies, set landlord-tenant and rent-control law, and preempt or
-- enable local zoning. The role table was under-scoped, not the rows wrong -- the same finding as 1543.
--
-- **This changes no stance data.** It makes 712 existing rows visible on the profiles they already belong to.
--
-- Mechanism (see 1543 for the full note): the API derives
--   applies_state = hasAnyRoleRows ? rows.some(r => r.role_scope = 'state') : true
-- and the frontend filters each profile's compass by office tier in `deriveScopedTopics`
-- (Results.jsx, ElectionsView.jsx), keeping `t[key] !== false`.
-- ⚠ `compass_topics.office_scope` is NOT the mechanism -- NULL on all 44 live topics, never read.
--
-- ⚠ AFTER THIS, `Affordable Housing` HAS federal + state + local. For DISPLAY that is identical to having
-- no rows at all (a topic with none defaults to all tiers true), but the rows are NOT redundant: they are
-- what puts the topic in each tier's REQUIRED set for compass completeness. It stays absent from
-- `judicial`, so judges still will not be asked it -- which is intended.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE `is_required` GATE, RE-MEASURED RATHER THAN ASSUMED FROM 1543
-- ---------------------------------------------------------------------------------------------------
-- `public.get_compass_completeness` counts required topics with `AND ctr.is_required = true`, and
-- `public.run_empower_preflight` turns an incomplete compass into a **`CALIBRATION_INCOMPLETE` failure with
-- `eligible: false`**. This row moves the STATE bar from 26 required topics to 27, so a state-role candidate
-- sitting at exactly 26 would lose eligibility.
--
-- Re-checked on production immediately before writing this file, not carried over from 1543:
-- **0 connected profiles have `candidate_role` set and there are 0 empowered profiles.** Nobody can be
-- demoted -- preflight fails earlier on `ROLE_NOT_SET` for all 12 existing profiles. `is_required = true`
-- is consistent with all 82 rows now in the table (still not one `false`).
-- ⚠ EXPECTED, NOT A BUG: the first state-role candidate will see `required` = 27.
-- If unwanted, flip this row to `is_required = false` -- the display flags ignore `is_required`, so the
-- topic stays visible while dropping out of the completeness denominator.

BEGIN;

CREATE TEMP TABLE _scope_1544 (topic_title text, topic_id uuid, role_scope text) ON COMMIT DROP;
INSERT INTO _scope_1544 (topic_title, topic_id, role_scope) VALUES
  ('Affordable Housing', '669cac97-66a6-4087-b036-936fbe62efb3', 'state');

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- Identifier must match the expected title and be live. Derive-then-verify, never recall.
  SELECT string_agg(s.topic_title || ' / ' || COALESCE(t.title, '(no such topic)'), '; ') INTO v_bad
    FROM _scope_1544 s LEFT JOIN inform.compass_topics t ON t.id = s.topic_id
   WHERE t.id IS NULL OR t.title <> s.topic_title OR t.is_live IS NOT TRUE;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'topic_id mismatch, missing, or not live: %', v_bad; END IF;

  -- Title must be unique so resolving by name elsewhere is unambiguous.
  SELECT count(*) INTO v_n FROM inform.compass_topics WHERE title = 'Affordable Housing';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 topic titled Affordable Housing, found %', v_n; END IF;

  -- Must currently LACK a state row, or the premise has changed.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1544 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 pre-existing state rows for Affordable Housing, found %', v_n; END IF;

  -- Must already have SOME role row: a topic with none already applies to all tiers, and inserting one
  -- would silently NARROW it to just that tier.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1544 s ON s.topic_id = r.topic_id;
  IF v_n = 0 THEN RAISE EXCEPTION 'Affordable Housing has no role rows, so it already applies to all tiers — inserting would NARROW it'; END IF;

  -- 1543 must be in place; this migration completes that work and assumes its result.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles
   WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND role_scope IN ('federal', 'local');
  IF v_n <> 2 THEN RAISE EXCEPTION 'expected Affordable Housing to hold federal+local rows from 1543, found %', v_n; END IF;

  -- Baseline required counts, asserted so the delta can be proven afterwards.
  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'state' AND ctr.is_required;
  IF v_n <> 26 THEN RAISE EXCEPTION 'expected 26 state required topics before the change, found %', v_n; END IF;
END $$;

-- ---- insert ----------------------------------------------------------------------------------------
INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
SELECT topic_id, role_scope, true FROM _scope_1544;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_af bool; v_as bool; v_al bool; v_aj bool;
BEGIN
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1544 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope
   WHERE r.is_required;
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected the state row present and required, found %', v_n; END IF;

  -- State required count moves by exactly 1; no other tier may move.
  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='state' AND ctr.is_required;
  IF v_n <> 27 THEN RAISE EXCEPTION 'expected 27 state required topics after the change, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='federal' AND ctr.is_required;
  IF v_n <> 26 THEN RAISE EXCEPTION 'federal required count moved (expected 26, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='local' AND ctr.is_required;
  IF v_n <> 22 THEN RAISE EXCEPTION 'local required count moved (expected 22, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct JOIN inform.compass_topic_roles ctr ON ctr.topic_id=ct.id
   WHERE ct.is_live AND ctr.role_scope='judicial' AND ctr.is_required;
  IF v_n <> 8 THEN RAISE EXCEPTION 'judicial required count moved (expected 8, found %) — it must not', v_n; END IF;

  -- Recompute the display flags exactly as the API does: federal+state+local true, judicial false.
  SELECT bool_or(role_scope='federal'), bool_or(role_scope='state'),
         bool_or(role_scope='local'),   bool_or(role_scope='judicial')
    INTO v_af, v_as, v_al, v_aj
    FROM inform.compass_topic_roles WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF NOT (v_af AND v_as AND v_al) THEN
    RAISE EXCEPTION 'expected Affordable Housing to apply to federal+state+local, got f=% s=% l=%', v_af, v_as, v_al;
  END IF;
  IF COALESCE(v_aj, false) THEN RAISE EXCEPTION 'Affordable Housing must NOT apply to judicial'; END IF;

  -- No stance data may be touched.
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> 33175 THEN RAISE EXCEPTION 'politician_answers changed (expected 33175, found %) — this migration must not touch stance data', v_n; END IF;
END $$;

-- Report: the state-tier housing stances this row makes displayable.
-- ⚠ governments.type is UPPERCASE ('STATE'); a case-sensitive comparison buckets everyone as local.
SELECT count(*) AS state_housing_answers_now_in_scope
  FROM inform.politician_answers a
 WHERE a.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
   AND EXISTS (
     SELECT 1 FROM essentials.office_terms ot
       JOIN essentials.offices o ON o.id = ot.office_id
       JOIN essentials.chambers ch ON ch.id = o.chamber_id
       JOIN essentials.governments g ON g.id = ch.government_id
      WHERE ot.politician_id = a.politician_id AND upper(g.type) = 'STATE'
   );

COMMIT;
