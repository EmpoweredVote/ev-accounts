-- 1550_source_discovery_runs_followups.sql
-- Fast-follows from review of 1535: funnel-loss counters + catalog comments + post-verify gate.

BEGIN;

-- (a) Funnel-loss counters: a run row should be able to distinguish "all seen" /
-- "prefiltered" / "recency-dropped", not just "classified" vs "inserted".
alter table essentials.source_discovery_runs
  add column if not exists skipped_seen integer not null default 0,
  add column if not exists prefiltered_out integer not null default 0,
  add column if not exists recency_filtered integer not null default 0;

-- (b) Promote the invariants that were previously only in the migration comment
-- into the catalog, where they'll actually be read.
comment on column essentials.source_discovery_runs.finished_at is
  'null = run never finished: crashed, or still in flight if started_at is recent';
comment on column essentials.source_discovery_runs.spend_capped is
  'count of items deferred by the per-run classifier spend cap (not a boolean)';
comment on column essentials.source_discovery_runs.failures is
  'newline-joined failure summaries, truncated to 4000 chars; failure_count is authoritative';

-- (c) Post-verify gate.
DO $$
DECLARE
  n_kind_constraints int;
  n_web_rss int;
  n_missing_cols int;
BEGIN
  -- Exactly one check constraint on source_outlets mentions kind, and it allows web_rss.
  SELECT count(*) INTO n_kind_constraints
    FROM pg_constraint
   WHERE conrelid = 'essentials.source_outlets'::regclass
     AND contype = 'c'
     AND pg_get_constraintdef(oid) ILIKE '%kind%';
  IF n_kind_constraints <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 kind-related check constraint on source_outlets, found %', n_kind_constraints;
  END IF;

  SELECT count(*) INTO n_web_rss
    FROM pg_constraint
   WHERE conrelid = 'essentials.source_outlets'::regclass
     AND contype = 'c'
     AND pg_get_constraintdef(oid) ILIKE '%kind%'
     AND pg_get_constraintdef(oid) LIKE '%web_rss%';
  IF n_web_rss <> 1 THEN
    RAISE EXCEPTION 'kind check constraint on source_outlets does not mention web_rss';
  END IF;

  -- source_discovery_runs carries all three new funnel-loss columns.
  SELECT count(*) INTO n_missing_cols
    FROM (VALUES ('skipped_seen'), ('prefiltered_out'), ('recency_filtered')) AS want(col)
   WHERE NOT EXISTS (
     SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'essentials'
        AND table_name = 'source_discovery_runs'
        AND column_name = want.col
   );
  IF n_missing_cols <> 0 THEN
    RAISE EXCEPTION 'source_discovery_runs is missing % of the 3 new funnel-loss columns', n_missing_cols;
  END IF;

  RAISE NOTICE 'source_discovery_runs follow-ups PASSED: kind check constraint is singular and mentions web_rss; all 3 funnel-loss columns present.';
END $$;

COMMIT;
