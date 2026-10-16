-- CA_0313_s3_education_lens_cleanup.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved by the steward allocator.
--
-- =============================================================================
-- CA_0313: Season 3 Education Lens cleanup — three ruled changes, metadata only
-- =============================================================================
-- Created 2026-10-16 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT
--   1. education-school-budget (49f0b171-…) is REMOVED from the draft Season 3
--      (7b3a066c-…) question set. Ruling 2026-10-16: off for Season 3, parked, not
--      dropped (decision record: docs/superpowers/specs/2026-10-07-season3-ladder-
--      evaluation.md, PR #1035). Stage 0 passed the count gate, but 167 of 176 school
--      acts were Yes; the only splits were tax-rate votes.
--   2. education-school-budget and education-gender-identity (d96f987e-…) are REMOVED
--      from the Education Lens (inform.compass_lens_topics). Lens rule 2026-10-14: a
--      topic is in a level's lens only if that level can be seated (EGI: school boards
--      seated 0 of ~244, state law preempts). The remaining six keep their order; the
--      lens description says 6. A lens may run below 8 topics (same ruling).
--   3. education-gender-identity federal evidence_basis: own-words -> record (ruled
--      2026-10-14, item 3: Congress holds a lever — H.R. 5 2023, H.R. 2616 2026).
--
-- NOT TOUCHED: EGI stays pinned in Season 3 on rev 1 (parked, not dropped). Season 2
--   (open) is not edited: school-budget keeps its S2 pin and its 1 voter answer.
--   No politician has ever been seated on either topic (0 answers, any season), so this
--   costs 0 seats. No topic, revision or answer row is deleted.
--
-- Idempotent. Post-verify gate at the end.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_actor  CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2'; -- Chris Andrews
  v_s3     CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075'; -- Season 3 (draft)
  v_budget CONSTANT uuid := '49f0b171-2ddf-4e68-887f-0ba78a2562f1'; -- education-school-budget
  v_egi    CONSTANT uuid := 'd96f987e-3404-4667-909d-5889116ba6e5'; -- education-gender-identity
  v_lens   uuid;
  v_n      int;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_budget AND topic_key = 'education-school-budget') THEN
    RAISE EXCEPTION 'CA_0313: school-budget topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_egi AND topic_key = 'education-gender-identity') THEN
    RAISE EXCEPTION 'CA_0313: EGI topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_s3 AND number = 3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0313: Season 3 is not a draft (its question set would be frozen)';
  END IF;
  SELECT id INTO v_lens FROM inform.compass_lenses WHERE key = 'education';
  IF v_lens IS NULL THEN RAISE EXCEPTION 'CA_0313: education lens missing'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id IN (v_budget, v_egi);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0313: % politician answers exist on school-budget/EGI — the 0-seat premise is false; stop', v_n;
  END IF;

  -- 1. school-budget out of the Season 3 draft.
  IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_budget) THEN
    PERFORM inform.admin_season_remove_topic(v_s3, v_budget, v_actor);
    RAISE NOTICE 'CA_0313: school-budget removed from Season 3.';
  ELSE
    RAISE NOTICE 'CA_0313: school-budget already absent from Season 3; skipping.';
  END IF;

  -- 2. school-budget and EGI out of the Education Lens; the six keep their relative order.
  DELETE FROM inform.compass_lens_topics WHERE lens_id = v_lens AND topic_id IN (v_budget, v_egi);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'CA_0313: % lens_topics rows removed.', v_n;
  UPDATE inform.compass_lenses
     SET description = '6 questions for school board and state board of education candidates'
   WHERE id = v_lens
     AND description IS DISTINCT FROM '6 questions for school board and state board of education candidates';

  -- 3. EGI federal evidence basis -> record.
  UPDATE inform.compass_topic_roles
     SET evidence_basis = 'record'
   WHERE topic_id = v_egi AND role_scope = 'federal' AND evidence_basis <> 'record';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'CA_0313: EGI federal role rows set to record: %', v_n;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_s3     CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_budget CONSTANT uuid := '49f0b171-2ddf-4e68-887f-0ba78a2562f1';
  v_egi    CONSTANT uuid := 'd96f987e-3404-4667-909d-5889116ba6e5';
  v_lens   uuid;
  v_n      int;
  v_keys   text;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_budget) THEN
    RAISE EXCEPTION 'CA_0313 verify: school-budget is still in Season 3';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_egi) THEN
    RAISE EXCEPTION 'CA_0313 verify: EGI lost its Season 3 pin (it is parked, not dropped)';
  END IF;

  SELECT id INTO v_lens FROM inform.compass_lenses WHERE key = 'education';
  SELECT count(*), string_agg(t.topic_key, ',' ORDER BY lt.sort_order) INTO v_n, v_keys
    FROM inform.compass_lens_topics lt JOIN inform.compass_topics t ON t.id = lt.topic_id
   WHERE lt.lens_id = v_lens;
  IF v_n <> 6 OR v_keys <> 'education-curriculum,education-library-books,education-equity-programs,'
                        || 'education-school-police,education-charter-authorization,education-ai' THEN
    RAISE EXCEPTION 'CA_0313 verify: education lens is % topics: %', v_n, v_keys;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles
              WHERE topic_id = v_egi AND role_scope = 'federal' AND evidence_basis <> 'record') THEN
    RAISE EXCEPTION 'CA_0313 verify: EGI federal role is not record';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_egi AND role_scope = 'federal') THEN
    RAISE EXCEPTION 'CA_0313 verify: EGI has no federal role row';
  END IF;

  RAISE NOTICE 'CA_0313 OK — school-budget off Season 3; education lens = 6 topics (%); EGI federal = record.', v_keys;
END $$;

COMMIT;
