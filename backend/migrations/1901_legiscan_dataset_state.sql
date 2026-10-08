-- 1901_legiscan_dataset_state.sql
-- State for the weekly LegiScan refresh job (ev-cto decision 0031, ev-jobs-legiscan on Render).
--
-- WHY. The Python loader kept two files under ~/.ev-backend: the last dataset_hash it imported per
-- session, and the monthly query count. A Render cron job has no disk that survives a run, so both
-- move into the database. Without the hash a run would reload every session every week. Without
-- the count the job could not stop itself at LegiScan's 10,000 queries a month free cap.
--
-- ADDITIVE ONLY. Two new tables, nothing else touched. RLS is on with no policy, so only the backend
-- role can read or write them (watchlist #81: do not add tables to this schema with RLS off).

CREATE TABLE IF NOT EXISTS essentials.legiscan_dataset_state (
  legiscan_session_id integer PRIMARY KEY,           -- LegiScan's session_id
  jurisdiction        text        NOT NULL,          -- e.g. 'california'
  dataset_hash        text        NOT NULL,          -- hash of the dataset last imported
  bridge_count        integer     NOT NULL DEFAULT 0,
  bills               integer     NOT NULL DEFAULT 0,
  imported_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS essentials.legiscan_query_counter (
  month   text    PRIMARY KEY,                       -- 'YYYY-MM'
  queries integer NOT NULL DEFAULT 0
);

ALTER TABLE essentials.legiscan_dataset_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legiscan_query_counter ENABLE ROW LEVEL SECURITY;
