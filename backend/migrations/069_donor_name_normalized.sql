-- 069: Add donor_name_normalized column and search indexes to contributions
--
-- Adds a normalized donor name column to transparent_motivations.contributions
-- for the Phase 26 Donor Search API. Two indexes are created:
--   - B-tree: exact matches and prefix queries (ORDER BY, =, LIKE 'prefix%')
--   - GIN trigram: fuzzy/partial matching (word_similarity, %> operator)
--
-- Column is nullable at this stage. NOT NULL will be added after the Phase 25
-- backfill script confirms zero NULLs remain in the table.
--
-- IMPORTANT: No BEGIN/COMMIT wrapper — CREATE INDEX CONCURRENTLY cannot run
-- inside a transaction block. Run all three statements in sequence outside
-- any transaction (e.g. via Supabase SQL Editor, not psql \i in a txn).
--
-- Operator class: extensions.gin_trgm_ops (NOT pg_trgm.gin_trgm_ops).
-- pg_trgm is installed in the extensions schema in this Supabase project.

ALTER TABLE transparent_motivations.contributions
  ADD COLUMN IF NOT EXISTS donor_name_normalized text;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contributions_donor_name_btree
  ON transparent_motivations.contributions (donor_name_normalized);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contributions_donor_name_trgm
  ON transparent_motivations.contributions
  USING GIN (donor_name_normalized extensions.gin_trgm_ops);
