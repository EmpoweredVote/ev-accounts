-- Migration 1387: distinct-donor-names matview to make donor search fast on common surnames
--
-- WHY: /api/campaign-finance/donors/search (searchDonors) fuzzy-matched donor names directly
--   against transparent_motivations.contributions (26.9M rows). A common surname like 'smith' is
--   trigram-similar to ~231K contribution rows; with a lossy GIN bitmap the word_similarity()
--   recheck ran over ~1M heap rows → ~58s (timed out at the 30s statement_timeout). EXPLAIN ANALYZE
--   confirmed the cost is the per-contribution recheck, not the downstream aggregation (~440 rows).
--
-- FIX: search a matview of DISTINCT confirmed donor names. Each name appears once, so the fuzzy
--   recheck runs over distinct names (fast). searchDonors then joins contributions only for the
--   ~50 matched names (cheap). Query rewrite: campaignFinanceService.ts searchDonors donor_matches
--   CTE now selects FROM donor_names_search instead of contributions.
--
-- Apply with a privileged role (postgres) OUTSIDE the 8s/30s caps — the initial build scans all
-- 26.9M rows (a few minutes). Run via psql with `SET statement_timeout='0'` (not the app role):
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SET statement_timeout=0" -f migrations/1387_...sql
-- Idempotent: IF NOT EXISTS guards; the cron reschedule is upsert-by-name.

-- Distinct confirmed donor names (contribution_count kept for possible ranking; not required).
CREATE MATERIALIZED VIEW IF NOT EXISTS transparent_motivations.donor_names_search AS
  SELECT c.donor_name_normalized, count(*)::bigint AS contribution_count
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  WHERE ps.research_status = 'confirmed'
    AND c.donor_name_normalized IS NOT NULL
    AND c.donor_name_normalized <> ''
  GROUP BY c.donor_name_normalized
WITH DATA;

-- Unique index: required for REFRESH ... CONCURRENTLY and backs the exact-name join.
CREATE UNIQUE INDEX IF NOT EXISTS donor_names_search_name_uk
  ON transparent_motivations.donor_names_search (donor_name_normalized);

-- GIN trigram index: backs the word_similarity / %> fuzzy search.
CREATE INDEX IF NOT EXISTS donor_names_search_name_trgm
  ON transparent_motivations.donor_names_search USING gin (donor_name_normalized extensions.gin_trgm_ops);

-- The API role reads it (matviews are not covered by GRANT ... ON ALL TABLES).
GRANT SELECT ON transparent_motivations.donor_names_search TO ev_api;

-- Nightly concurrent refresh (new donors become searchable next day; CONCURRENTLY never locks
-- readers). Upsert-by-jobname so re-running this migration just updates the schedule.
SELECT cron.schedule(
  'refresh-donor-names-search',
  '17 8 * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY transparent_motivations.donor_names_search$$
);
