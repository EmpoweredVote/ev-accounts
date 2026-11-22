-- =============================================================================
-- CA_0414 — gun-policy at the local level: records never seat a chair alone
-- (evidence_basis 'record' -> 'own-words'; ruling 2026-10-22, Chris Andrews)
-- =============================================================================
-- compass_topic_roles.evidence_basis (CA_0302) says what can seat a chair at a
-- (topic, level): 'record' = records and own words both count; 'own-words' = only
-- the person's own words can. For gun-policy, local officials hold no lever on any
-- rung that a record could evidence, so a local record never seats a chair alone.
-- The row is re-labelled so Stage 5 routes local gun-policy rows to the own-words
-- stratum (and its review rules) instead of the record stratum.
--
-- OLD VALUE (recorded here because an UPDATE is final):
--   inform.compass_topic_roles, topic_key 'gun-policy', role_scope 'local':
--     evidence_basis = 'record'   (is_required unchanged, not touched here)
--   Undo: UPDATE inform.compass_topic_roles r SET evidence_basis = 'record'
--           FROM inform.compass_topics t
--          WHERE t.id = r.topic_id AND t.topic_key = 'gun-policy' AND r.role_scope = 'local';
--
-- The gun-policy federal and state rows stay 'record' and are not touched.
-- No answer, context or evidence row is touched. One row changes.
-- Idempotent in effect: the precondition refuses a second run (the row would
-- already read 'own-words'), which is the intended signal that it already applied.
-- No grant or RLS change: no table or column is created.
-- =============================================================================

BEGIN;

-- Precondition gate: exactly one (gun-policy, local) row, and it reads 'record'.
-- (Plain TEMP table, dropped at the end: ON COMMIT DROP would vanish at once if a runner strips BEGIN.)
-- Also captures how many gun-policy rows read 'record' before the update, so the
-- post-verify can prove the federal and state rows were not touched.
CREATE TEMP TABLE _ca0414_before AS
SELECT r.role_scope, r.evidence_basis
  FROM inform.compass_topic_roles r
  JOIN inform.compass_topics t ON t.id = r.topic_id
 WHERE t.topic_key = 'gun-policy';

DO $$
DECLARE
  n_local int;
  n_local_record int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE evidence_basis = 'record')
    INTO n_local, n_local_record
    FROM _ca0414_before
   WHERE role_scope = 'local';
  IF n_local <> 1 THEN
    RAISE EXCEPTION 'CA_0414: expected exactly 1 (gun-policy, local) row, found %', n_local;
  END IF;
  IF n_local_record <> 1 THEN
    RAISE EXCEPTION 'CA_0414: the (gun-policy, local) row does not read ''record'' (already applied, or changed since the header was written)';
  END IF;
END $$;

UPDATE inform.compass_topic_roles r
   SET evidence_basis = 'own-words'
  FROM inform.compass_topics t
 WHERE t.id = r.topic_id
   AND t.topic_key = 'gun-policy'
   AND r.role_scope = 'local'
   AND r.evidence_basis = 'record';

-- Post-verify gate.
DO $$
DECLARE
  n_local_own int;
  n_other_before int;
  n_other_record_before int;
  n_other_after int;
  n_other_record_after int;
BEGIN
  SELECT count(*) INTO n_local_own
    FROM inform.compass_topic_roles r
    JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE t.topic_key = 'gun-policy' AND r.role_scope = 'local' AND r.evidence_basis = 'own-words';
  IF n_local_own <> 1 THEN
    RAISE EXCEPTION 'CA_0414: (gun-policy, local) does not read ''own-words'' (found % such rows)', n_local_own;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE evidence_basis = 'record')
    INTO n_other_before, n_other_record_before
    FROM _ca0414_before WHERE role_scope <> 'local';

  SELECT count(*), count(*) FILTER (WHERE r.evidence_basis = 'record')
    INTO n_other_after, n_other_record_after
    FROM inform.compass_topic_roles r
    JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE t.topic_key = 'gun-policy' AND r.role_scope <> 'local';

  IF n_other_after <> n_other_before OR n_other_record_after <> n_other_record_before THEN
    RAISE EXCEPTION 'CA_0414: other gun-policy rows moved (rows % -> %, record % -> %)',
      n_other_before, n_other_after, n_other_record_before, n_other_record_after;
  END IF;

  -- The ruling names federal and state as 'record'; assert they still are.
  IF EXISTS (
    SELECT 1
      FROM inform.compass_topic_roles r
      JOIN inform.compass_topics t ON t.id = r.topic_id
     WHERE t.topic_key = 'gun-policy' AND r.role_scope IN ('federal', 'state')
       AND r.evidence_basis <> 'record'
  ) THEN
    RAISE EXCEPTION 'CA_0414: a gun-policy federal or state row no longer reads ''record''';
  END IF;
END $$;

DROP TABLE _ca0414_before;

COMMIT;
