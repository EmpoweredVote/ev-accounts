-- Migration 1071: Remove erroneous "U.S. Senate Maryland" 2026 race
--
-- Maryland has NO U.S. Senate seat up in 2026 — it is not a Class 2 state
-- (MD's seats are up in 2028 (Van Hollen) and 2030 (Alsobrooks)). This race row
-- was seeded in error (0 candidates) and would otherwise display a false/empty
-- contest now that statewide races surface in the feed. Delete it.
--
-- Race: 961f1dd1-6751-415e-8741-0483493bdfe7 (U.S. Senate Maryland, 2026 general)
-- race_candidates has ON DELETE CASCADE, but this race has 0 candidates anyway.

BEGIN;

-- Safety: confirm it's the expected race and has no candidates before deleting.
DO $$
DECLARE v_name text; v_cands int;
BEGIN
  SELECT r.position_name, (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
    INTO v_name, v_cands
  FROM essentials.races r WHERE r.id = '961f1dd1-6751-415e-8741-0483493bdfe7';
  IF v_name IS DISTINCT FROM 'U.S. Senate Maryland' THEN
    RAISE EXCEPTION 'Unexpected race name "%" — aborting', v_name;
  END IF;
  IF v_cands <> 0 THEN
    RAISE EXCEPTION 'Race has % candidates — aborting (manual review)', v_cands;
  END IF;
END $$;

DELETE FROM essentials.races WHERE id = '961f1dd1-6751-415e-8741-0483493bdfe7';

-- Verify it's gone.
SELECT count(*) AS remaining FROM essentials.races WHERE id = '961f1dd1-6751-415e-8741-0483493bdfe7';

COMMIT;
