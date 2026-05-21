-- 117: Ensure essentials.politicians.external_id is UNIQUE (idempotent).
-- Phase 133 / Open Question 1 (RESEARCH.md).
-- The D-07 upsert pattern (ON CONFLICT (external_id) DO UPDATE) requires a
-- unique index. Phase 133's IN/LA loaders worked because external_id was
-- effectively unique by construction, but no explicit constraint existed.
-- This migration adds one. Safe to re-run: uses IF NOT EXISTS where possible
-- and probes pg_constraint before ALTER TABLE.
--
-- Pre-apply probe (production state at authoring time): operator should run
--   psql "$DATABASE_URL" -At -c "SELECT indexname FROM pg_indexes \
--     WHERE schemaname='essentials' AND tablename='politicians' \
--     AND indexdef ILIKE '%external_id%'"
-- and record the result in the deployment log alongside this migration.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'essentials.politicians'::regclass
       AND contype  = 'u'
       AND conname  = 'essentials_politicians_external_id_key'
  ) THEN
    -- Detect duplicate external_ids first (refuse to add constraint silently)
    DECLARE dup_count int;
    BEGIN
      SELECT COUNT(*) INTO dup_count FROM (
        SELECT external_id FROM essentials.politicians
         WHERE external_id IS NOT NULL
         GROUP BY external_id HAVING COUNT(*) > 1
      ) s;
      IF dup_count > 0 THEN
        RAISE EXCEPTION 'Migration 117 ABORT: % duplicate external_id values in essentials.politicians. Resolve dupes before re-running.', dup_count;
      END IF;
    END;

    ALTER TABLE essentials.politicians
      ADD CONSTRAINT essentials_politicians_external_id_key UNIQUE (external_id);
    RAISE NOTICE 'Migration 117: added UNIQUE on essentials.politicians.external_id';
  ELSE
    RAISE NOTICE 'Migration 117: UNIQUE constraint already present; no-op';
  END IF;
END $$;

-- ROLLBACK (emergency, manual):
--   ALTER TABLE essentials.politicians DROP CONSTRAINT essentials_politicians_external_id_key;
