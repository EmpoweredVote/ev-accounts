-- CA_0410 — transparent_motivations.fec_fetch_checkpoints: resume a FEC fetch cut off by its time limit
-- (ev-cto watchlist #102, 2026-11-22)
--
-- WHAT. One row per (source, cycle, committee) of a CHAIN of attempts at one FEC source that share one
-- query (one min_load_date). A row is either `done` (that committee's main pull finished in this chain) or
-- holds FEC's keyset cursor (`last_indexes`) to continue from. Written only when an attempt is cut off by
-- its time limit; read at the start of every attempt. Logic and the cursor-after-a-chain rule:
-- backend/src/lib/adapters/fecFetchCheckpoint.ts.
--
-- WHY. The burst gives each source 10 minutes, and FEC's shared ~1,000 req/hr key holds one source to
-- ~12,000-15,000 rows in that time. On 2026-11-22 the biggest campaigns had more than that waiting, so each
-- attempt re-read the same top rows and was cut off again (13 of that day's 20 failures had already failed
-- that week). With a checkpoint, each attempt continues from the last saved page instead.
--
-- SIZE. Rows exist only for sources whose last attempt was cut off, plus a short-lived marker set after a
-- chain finishes: tens of rows, not thousands.
--
-- ACCESS. Default privileges in this schema give anon and authenticated SELECT on every new table. Nothing
-- public reads this, so it is revoked from them and RLS is on with no policy. ev_api (the jobs' role, which
-- has BYPASSRLS) reads and writes it, as it does fec_ingest_window_progress.
--
-- Overwrites no existing value.

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '1min';

DO $$
BEGIN
  IF to_regclass('transparent_motivations.fec_fetch_checkpoints') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0410: fec_fetch_checkpoints already exists';
  END IF;
END $$;

CREATE TABLE transparent_motivations.fec_fetch_checkpoints (
  politician_source_id uuid        NOT NULL
    REFERENCES transparent_motivations.politician_sources(id) ON DELETE CASCADE,
  election_cycle       text        NOT NULL,
  committee_id         text        NOT NULL,
  min_load_date        date,                         -- NULL = a whole-cycle first load
  last_indexes         jsonb,                        -- NULL = restart this committee (or it is done)
  rows_saved           integer     NOT NULL DEFAULT 0 CHECK (rows_saved >= 0),
  done                 boolean     NOT NULL DEFAULT false,
  chain_started_at     timestamptz NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (politician_source_id, election_cycle, committee_id),
  CHECK (NOT (done AND last_indexes IS NOT NULL))
);
COMMENT ON TABLE transparent_motivations.fec_fetch_checkpoints IS
  'Where a FEC source''s fetch stopped when its time limit cut it off, so the next attempt continues '
  'instead of starting over (CA_0410). Logic: backend/src/lib/adapters/fecFetchCheckpoint.ts.';

REVOKE ALL ON transparent_motivations.fec_fetch_checkpoints FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON transparent_motivations.fec_fetch_checkpoints TO ev_api;
ALTER TABLE transparent_motivations.fec_fetch_checkpoints ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  t oid := 'transparent_motivations.fec_fetch_checkpoints'::regclass;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = t) THEN
    RAISE EXCEPTION 'CA_0410 verify: RLS is off';
  END IF;
  IF has_table_privilege('anon', t, 'SELECT') OR has_table_privilege('authenticated', t, 'SELECT') THEN
    RAISE EXCEPTION 'CA_0410 verify: anon or authenticated can read the table';
  END IF;
  IF NOT (has_table_privilege('ev_api', t, 'SELECT') AND has_table_privilege('ev_api', t, 'INSERT')
          AND has_table_privilege('ev_api', t, 'UPDATE') AND has_table_privilege('ev_api', t, 'DELETE')) THEN
    RAISE EXCEPTION 'CA_0410 verify: ev_api lacks a privilege it needs';
  END IF;
  RAISE NOTICE 'CA_0410 verify OK: table created, RLS on, closed to anon/authenticated, ev_api arwd';
END $$;

COMMIT;
