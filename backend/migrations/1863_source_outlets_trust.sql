-- Outlet-level trust + barred-for-ingest flags for the discovery review reorg.
-- Spec: on-the-record/docs/superpowers/specs/2026-09-16-discovery-review-reorg-design.md
ALTER TABLE essentials.source_outlets
  ADD COLUMN IF NOT EXISTS trusted       boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS trusted_at    timestamptz,
  ADD COLUMN IF NOT EXISTS ingest_barred boolean     NOT NULL DEFAULT false;

-- Seed the barred-for-ingest flag from the chain ToS scoreboard (AI/ML bar).
-- Name-based, case-insensitive; extend as the scoreboard grows.
UPDATE essentials.source_outlets
SET ingest_barred = true
WHERE ingest_barred = false
  AND (name ILIKE ANY (ARRAY[
        '%nexstar%', '%gray %', '%gray media%', '%hearst%', '%graham media%',
        '%lee enterprises%', '%tollbit%'
      ]));

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='essentials' AND table_name='source_outlets'
                   AND column_name='ingest_barred') THEN
    RAISE EXCEPTION 'source_outlets.ingest_barred missing after migration';
  END IF;
END $$;
