-- CA_0312_curriculum_equity_local_own_words.sql
-- Author: Chris Andrews (CA_ namespace; slot reserved from the steward allocator 2026-10-16)
--
-- =============================================================================
-- CA_0312: education-curriculum + education-equity-programs — local role
--          evidence_basis record -> own-words
-- =============================================================================
-- Ruling X2, 2026-10-16 (Chris Andrews), Education Lens review after the library pilot.
-- Same shape as CA_0311 (education-library-books, Q5).
--
-- WHY
--   A city or county council holds no lever on what a school teaches (curriculum) or
--   on a district's equity offices, training and support (equity-programs); the
--   school board and the state do. Both annexes already say so. The Stage 0 census
--   (2026-10-15) found no local record on either topic. The role rows said `record`,
--   which claims a local record can seat a chair. Under CA_0302 ("positions without a
--   lever") the level stays ASKED and only the person's own words can seat a chair.
--
-- WHAT THIS DOES
--   One UPDATE on inform.compass_topic_roles: the `local` row of each topic,
--   evidence_basis 'record' -> 'own-words'. is_required is left as it is (true), as
--   CA_0302 and CA_0311 did. No answer, context or season row is touched. Measured
--   2026-10-16: 0 politician_answers rows on either topic in any season.
--
-- Idempotent: the UPDATE is guarded on the old value; the gate asserts the end state.
-- =============================================================================

BEGIN;

UPDATE inform.compass_topic_roles r
   SET evidence_basis = 'own-words'
  FROM inform.compass_topics t
 WHERE t.id = r.topic_id
   AND t.topic_key IN ('education-curriculum', 'education-equity-programs')
   AND r.role_scope = 'local'
   AND r.evidence_basis <> 'own-words';

DO $$
DECLARE
  v_curr   CONSTANT uuid := '6c43fdec-d084-415d-a15d-d78f48d4fb34';
  v_equity CONSTANT uuid := '66b389c7-86fc-45e9-bf34-964bb747f27b';
  v_want   CONSTANT text := 'federal:own-words:false,local:own-words:true,school:record:true,state:record:true';
  v_roles  text;
  v_n      int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_curr AND topic_key = 'education-curriculum') THEN
    RAISE EXCEPTION 'CA_0312: education-curriculum topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_equity AND topic_key = 'education-equity-programs') THEN
    RAISE EXCEPTION 'CA_0312: education-equity-programs topic id/key mismatch';
  END IF;

  -- The four roles of each topic, exactly as intended after the change.
  SELECT string_agg(format('%s:%s:%s', role_scope, evidence_basis, is_required::text), ',' ORDER BY role_scope)
    INTO v_roles FROM inform.compass_topic_roles WHERE topic_id = v_curr;
  IF v_roles IS DISTINCT FROM v_want THEN
    RAISE EXCEPTION 'CA_0312: curriculum roles are % (expected %)', v_roles, v_want;
  END IF;
  SELECT string_agg(format('%s:%s:%s', role_scope, evidence_basis, is_required::text), ',' ORDER BY role_scope)
    INTO v_roles FROM inform.compass_topic_roles WHERE topic_id = v_equity;
  IF v_roles IS DISTINCT FROM v_want THEN
    RAISE EXCEPTION 'CA_0312: equity-programs roles are % (expected %)', v_roles, v_want;
  END IF;

  -- Nothing else moved: own-words rows across all topics = 41 before (after CA_0311) + these two.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE evidence_basis = 'own-words';
  IF v_n <> 43 THEN
    RAISE EXCEPTION 'CA_0312: % own-words role rows in total (expected 43)', v_n;
  END IF;

  RAISE NOTICE 'CA_0312 OK: curriculum and equity-programs local roles are own-words; 43 own-words rows in total';
END $$;

COMMIT;
