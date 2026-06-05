BEGIN;

-- Migration 211: Add created_at to essentials.politicians
--
-- Allows querying recently-added politicians by insertion timestamp.
-- Existing rows get the current timestamp as a reasonable default (backfill).

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

COMMIT;
