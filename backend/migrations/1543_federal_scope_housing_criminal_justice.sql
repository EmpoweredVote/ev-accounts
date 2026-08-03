-- 1543_federal_scope_housing_criminal_justice.sql
--
-- Declare `Affordable Housing` and `Criminal Justice Approach` applicable to FEDERAL officials, by adding
-- the missing `federal` rows to inform.compass_topic_roles.
--
--   Review:   data/stance-research/pretenure-reresearch/SCOPE-DECISION.md
--   Rollback: DELETE FROM inform.compass_topic_roles
--              WHERE role_scope = 'federal'
--                AND topic_id IN ('669cac97-66a6-4087-b036-936fbe62efb3',   -- Affordable Housing
--                                 '9db07b16-1076-4b7d-ad89-ebe7b51f4336');  -- Criminal Justice Approach
--             Exactly reversible: this migration only inserts those two rows.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1543_federal_scope_housing_criminal_justice.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- `inform.compass_topic_roles` is the live tier model. The API derives the display flags from it --
--   applies_federal = hasAnyRoleRows ? rows.some(r => r.role_scope = 'federal') : true
-- (a topic with NO rows defaults to all tiers true) -- and the frontend filters each profile's compass by
-- the office tier in `deriveScopedTopics` (Results.jsx, ElectionsView.jsx), keeping `t[key] !== false`.
--
-- Before this migration:
--   Affordable Housing        -> `local` only     => applies_federal = FALSE
--   Criminal Justice Approach -> `judicial` only  => applies_federal = FALSE
-- So **271 researched stances on federal officials could never display**: 194 on Affordable Housing and
-- 77 on Criminal Justice Approach, including two chairs migration 1541 had just restored (Val Hoyle /
-- Affordable Housing and Ayanna Pressley / Criminal Justice Approach). They were also inflating the
-- UNTIERED `answer_count` in `getCandidates`, so Hoyle read as 7 stances when only 5 could surface.
--
-- The operator's decision is that the role table was UNDER-SCOPED, not that the rows were wrong: Congress
-- legislates housing (LIHTC, Section 8, the housing credit) and criminal justice (federal sentencing, the
-- death penalty, cannabis scheduling) constantly. **This changes no stance data at all** -- it makes 271
-- existing rows visible on the profiles they already belong to.
--
-- ⚠ `compass_topics.office_scope` is NOT the mechanism -- NULL on all 44 live topics and never read by the
-- frontend. Do not use it.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE ONE REAL RISK, MEASURED BEFORE WRITING: `is_required` FEEDS A HARD ELIGIBILITY GATE
-- ---------------------------------------------------------------------------------------------------
-- `public.get_compass_completeness(user, role_scope)` counts required topics with
-- `AND ctr.is_required = true`, and `public.run_empower_preflight` turns an incomplete compass into a
-- **`CALIBRATION_INCOMPLETE` failure with `eligible: false`**. So adding `is_required = true` rows raises
-- the bar for federal-role candidates from 24 required topics to 26, and a candidate sitting at exactly 24
-- would lose eligibility.
--
-- Measured on production before choosing: **0 of 12 connected profiles have `candidate_role` set, and there
-- are 0 empowered profiles (active or otherwise).** Nobody can be demoted by this today -- preflight fails
-- earlier on `ROLE_NOT_SET` for every existing profile. `is_required = true` is therefore both safe and
-- consistent with all 80 pre-existing rows (there is not a single `false` in the table).
-- ⚠ EXPECTED, NOT A BUG: the first federal-role candidate will see `required` = 26, not 24.
-- If that is ever unwanted, flip these two rows to `is_required = false` -- the display flags ignore
-- `is_required`, so the topics stay visible while dropping out of the completeness denominator.
--
-- ⚠ NOT ADDRESSED HERE, DELIBERATELY: ~3,300 answers corpus-wide sit on topics excluded for their holder's
-- tier. The largest single bucket is **712 STATE-tier answers on Affordable Housing**, which this migration
-- does NOT fix because `Affordable Housing` still has no `state` row. That is a separate decision.

BEGIN;

CREATE TEMP TABLE _scope_1543 (topic_title text, topic_id uuid, role_scope text) ON COMMIT DROP;
INSERT INTO _scope_1543 (topic_title, topic_id, role_scope) VALUES
  ('Affordable Housing',        '669cac97-66a6-4087-b036-936fbe62efb3', 'federal'),
  ('Criminal Justice Approach', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 'federal');

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- Identifiers must match the expected titles. Derive-then-verify, never recall.
  SELECT string_agg(s.topic_title || ' / ' || COALESCE(t.title, '(no such topic)'), '; ') INTO v_bad
    FROM _scope_1543 s LEFT JOIN inform.compass_topics t ON t.id = s.topic_id
   WHERE t.id IS NULL OR t.title <> s.topic_title OR t.is_live IS NOT TRUE;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'topic_id mismatch, missing, or not live: %', v_bad; END IF;

  -- Titles must be unique, or resolving a topic by name elsewhere is ambiguous.
  SELECT string_agg(t.title, '; ') INTO v_bad
    FROM inform.compass_topics t JOIN _scope_1543 s ON s.topic_title = t.title
   GROUP BY t.title HAVING count(*) > 1;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'duplicate topic titles: %', v_bad; END IF;

  -- Both must currently LACK a federal row; otherwise the premise has changed.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1543 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 pre-existing federal rows for these topics, found %', v_n; END IF;

  -- Both must already have SOME role row: if a topic had none it would already default to all tiers
  -- true, and inserting one row would silently REMOVE it from the other tiers.
  SELECT string_agg(s.topic_title, '; ') INTO v_bad
    FROM _scope_1543 s
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles r WHERE r.topic_id = s.topic_id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'topic has no role rows, so it already applies to all tiers — inserting would NARROW it: %', v_bad; END IF;

  -- Record the federal required-topic count so the delta can be asserted afterwards.
  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'federal' AND ctr.is_required;
  IF v_n <> 24 THEN RAISE EXCEPTION 'expected 24 federal required topics before the change, found %', v_n; END IF;
END $$;

-- ---- insert ----------------------------------------------------------------------------------------
INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
SELECT topic_id, role_scope, true FROM _scope_1543;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles r
    JOIN _scope_1543 s ON s.topic_id = r.topic_id AND s.role_scope = r.role_scope
   WHERE r.is_required;
  IF v_n <> 2 THEN RAISE EXCEPTION 'expected 2 federal rows present, found %', v_n; END IF;

  -- The federal required count must move by exactly 2, and no other tier may move.
  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'federal' AND ctr.is_required;
  IF v_n <> 26 THEN RAISE EXCEPTION 'expected 26 federal required topics after the change, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'local' AND ctr.is_required;
  IF v_n <> 22 THEN RAISE EXCEPTION 'local required count moved (expected 22, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'state' AND ctr.is_required;
  IF v_n <> 26 THEN RAISE EXCEPTION 'state required count moved (expected 26, found %) — it must not', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
   WHERE ct.is_live AND ctr.role_scope = 'judicial' AND ctr.is_required;
  IF v_n <> 8 THEN RAISE EXCEPTION 'judicial required count moved (expected 8, found %) — it must not', v_n; END IF;

  -- The two topics must now derive applies_federal = TRUE, computed exactly as the API does.
  SELECT string_agg(x.title || ' applies_federal=' || x.af::text, '; ') INTO v_bad FROM (
    SELECT t.title, bool_or(r.role_scope = 'federal') AS af
      FROM inform.compass_topics t
      JOIN inform.compass_topic_roles r ON r.topic_id = t.id
      JOIN _scope_1543 s ON s.topic_id = t.id
     GROUP BY t.title
  ) x WHERE x.af IS NOT TRUE;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'applies_federal did not become true: %', v_bad; END IF;

  -- No stance data may be touched by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> 33175 THEN RAISE EXCEPTION 'politician_answers changed (expected 33175, found %) — this migration must not touch stance data', v_n; END IF;
END $$;

-- Report: the previously-inert federal answers that these two rows make displayable.
SELECT t.title,
       count(*) AS federal_answers_now_in_scope
  FROM inform.politician_answers a
  JOIN _scope_1543 s ON s.topic_id = a.topic_id
  JOIN inform.compass_topics t ON t.id = a.topic_id
 WHERE EXISTS (
   SELECT 1 FROM essentials.office_terms ot
     JOIN essentials.offices o ON o.id = ot.office_id
     JOIN essentials.chambers ch ON ch.id = o.chamber_id
     JOIN essentials.governments g ON g.id = ch.government_id
    WHERE ot.politician_id = a.politician_id
      AND upper(g.type) IN ('NATIONAL', 'FEDERAL')   -- ⚠ governments.type is UPPERCASE
 )
 GROUP BY t.title ORDER BY t.title;

COMMIT;
