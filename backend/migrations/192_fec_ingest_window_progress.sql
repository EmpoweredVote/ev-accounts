-- Migration 192: transparent_motivations.fec_ingest_window_progress
--
-- Purpose: makes a mega-committee FEC pull RESUMABLE across dyno restarts.
--
-- A large (source, cycle) pair is subdivided into date windows during fetch
-- (see fecAdapter streamWindowAdaptive). When a window is fully fetched, the FEC
-- adapter records it here. A later run (e.g. after a Render restart mid-pull) skips
-- windows already recorded complete instead of re-hitting the FEC API from page zero.
--
-- Incremental per-page upsert is what makes each window's ROWS durable; this table is
-- what makes the FETCH resumable. The adapter reads/writes this table best-effort and
-- degrades gracefully (log + continue) if it is absent, so ordering vs. code deploy is
-- not load-bearing.
--
-- Idempotency: CREATE ... IF NOT EXISTS + additive index. Safe to re-apply.

BEGIN;

CREATE TABLE IF NOT EXISTS transparent_motivations.fec_ingest_window_progress (
  politician_source_id uuid        NOT NULL,
  election_cycle       varchar(10) NOT NULL,
  committee_id         text        NOT NULL,
  window_start         date        NOT NULL,
  window_end           date        NOT NULL,
  records_fetched      integer     NOT NULL DEFAULT 0,
  completed_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (politician_source_id, election_cycle, committee_id, window_start, window_end)
);

COMMENT ON TABLE transparent_motivations.fec_ingest_window_progress IS
  'Per-(source,cycle,committee,date-window) completion log so a restarted FEC mega-pull resumes from where it stopped instead of re-fetching from page zero (quick-030 Task 1).';

-- Lookup by pair (all committees/windows for one source+cycle) is the hot read.
CREATE INDEX IF NOT EXISTS idx_fec_window_progress_pair
  ON transparent_motivations.fec_ingest_window_progress (politician_source_id, election_cycle);

COMMIT;
