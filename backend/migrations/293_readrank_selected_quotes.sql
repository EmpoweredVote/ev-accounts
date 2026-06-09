-- 293_readrank_selected_quotes.sql
-- Adds a per-stance "this is the Read & Rank quote" flag to essentials.quotes.
-- Keep-all model: multiple quotes per (politician, topic) are allowed; exactly one
-- per (politician_id, lower(topic_key)) may be readrank_selected.

BEGIN;

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS readrank_selected boolean NOT NULL DEFAULT false;

-- Backfill: pick exactly one row per existing stance.
-- Prefer a de-identified quote; tie-break by earliest created_at (nullable) then id.
WITH ranked AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY politician_id, lower(topic_key)
           ORDER BY (deidentified_text IS NOT NULL) DESC,
                    created_at ASC NULLS LAST,
                    id ASC
         ) AS rn
  FROM essentials.quotes
)
UPDATE essentials.quotes q
SET readrank_selected = true
FROM ranked
WHERE q.id = ranked.id AND ranked.rn = 1;

-- Enforce at most one selected per stance.
CREATE UNIQUE INDEX IF NOT EXISTS quotes_one_selected_per_stance
  ON essentials.quotes (politician_id, lower(topic_key))
  WHERE readrank_selected;

COMMIT;
