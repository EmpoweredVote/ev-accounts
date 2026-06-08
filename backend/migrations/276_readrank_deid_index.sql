-- 276_readrank_deid_index.sql
-- Read & Rank: speed up the playable-races / blind-quotes / reveal joins, which
-- always filter essentials.quotes to rows that HAVE a de-identified version and
-- join to race_candidates by politician_id.
--
-- No table changes: deidentified_text stays nullable (NULL = "not yet de-id'd,
-- don't serve"). Additive + idempotent.

-- Partial index: only de-identified, servable quotes, keyed by politician for the
-- quotes -> race_candidates join.
CREATE INDEX IF NOT EXISTS idx_quotes_deid_politician
  ON essentials.quotes (politician_id)
  WHERE deidentified_text IS NOT NULL;

-- Support the race_candidates join in both directions.
CREATE INDEX IF NOT EXISTS idx_race_candidates_politician_id
  ON essentials.race_candidates (politician_id);

CREATE INDEX IF NOT EXISTS idx_race_candidates_race_id
  ON essentials.race_candidates (race_id);
