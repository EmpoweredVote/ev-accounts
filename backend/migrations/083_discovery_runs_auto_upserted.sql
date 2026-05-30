BEGIN;

ALTER TABLE essentials.discovery_runs
  ADD COLUMN IF NOT EXISTS candidates_auto_upserted INT NOT NULL DEFAULT 0;

COMMIT;
