-- CA_0311_library_books_local_own_words.sql
-- Author: Chris Andrews (CA_ namespace; slot reserved from the steward allocator 2026-10-15)
--
-- =============================================================================
-- CA_0311: education-library-books — local role evidence_basis record -> own-words
-- =============================================================================
-- Ruling 2026-10-15 (Chris Andrews), Season 3 library pilot Q5, option A.
--
-- WHY
--   A city or county council governs public libraries, not school libraries, so no
--   local officeholder holds a lever on this question. The annex already codes a
--   local library act as `adjacent`. The role row said `record`, which claims a
--   local record can seat a chair; none can. Under the 2026-10-06 ruling (CA_0302,
--   "positions without a lever") the level stays ASKED and only the person's own
--   words can seat a chair there.
--
-- WHAT THIS DOES
--   One UPDATE on inform.compass_topic_roles: (education-library-books, local)
--   evidence_basis 'record' -> 'own-words'. is_required is left as it is (true),
--   the same way CA_0302 re-labelled its four existing rows (abortion local,
--   deportation state, education-ai local, education-gender-identity local).
--   No answer, context or season row is touched. Measured 2026-10-15: 0
--   politician_answers rows on this topic in any season.
--
-- Idempotent: the UPDATE is guarded on the old value; the gate asserts the end state.
-- =============================================================================

BEGIN;

UPDATE inform.compass_topic_roles r
   SET evidence_basis = 'own-words'
  FROM inform.compass_topics t
 WHERE t.id = r.topic_id
   AND t.topic_key = 'education-library-books'
   AND r.role_scope = 'local'
   AND r.evidence_basis <> 'own-words';

DO $$
DECLARE
  v_topic CONSTANT uuid := '1fcff1e8-c913-4d97-91da-1145952d7c65';
  v_roles text;
  v_n     int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'education-library-books') THEN
    RAISE EXCEPTION 'CA_0311: education-library-books topic id/key mismatch';
  END IF;

  -- The four roles, exactly as intended after the change.
  SELECT string_agg(format('%s:%s:%s', role_scope, evidence_basis, is_required::text), ',' ORDER BY role_scope)
    INTO v_roles FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_roles IS DISTINCT FROM 'federal:own-words:false,local:own-words:true,school:record:true,state:record:true' THEN
    RAISE EXCEPTION 'CA_0311: library roles are % (expected federal own-words/false, local own-words/true, school record/true, state record/true)', v_roles;
  END IF;

  -- Nothing else moved: own-words rows across all topics = 40 before + this one.
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE evidence_basis = 'own-words';
  IF v_n <> 41 THEN
    RAISE EXCEPTION 'CA_0311: % own-words role rows in total (expected 41)', v_n;
  END IF;

  RAISE NOTICE 'CA_0311 OK: education-library-books local role is own-words; 41 own-words rows in total';
END $$;

COMMIT;
