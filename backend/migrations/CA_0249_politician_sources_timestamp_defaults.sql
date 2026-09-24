-- CA_0249_politician_sources_timestamp_defaults.sql
-- Give transparent_motivations.politician_sources.created_at and updated_at a DEFAULT of now().
--
-- WHY: both columns were created with no default, and no trigger maintains them, so an INSERT that does not name
-- them stores NULL. Measured 2026-09-24: 77 of 87,403 rows carry a created_at, 8,887 an updated_at. That made "when
-- was this link made?" unanswerable. It bit the same day: checking the rows the FEC auto-match had just written, a
-- `created_at >= <run start>` filter returned 0 for ~900 new rows, silently, and the check had to fall back on
-- before/after counts.
--
-- WHAT: SET DEFAULT now() on both columns. From now on every INSERT that omits them records the time. Nothing else:
--   - NO BACKFILL. The existing NULLs stay NULL: nobody knows when those rows were made, and writing the apply date
--     into them would be an invented date that looks like a real one.
--   - No NOT NULL: the 87,326 NULL rows stay legal.
--   - No updated_at trigger. updated_at still changes only where a writer sets it (most migrations that move a link
--     already write updated_at = now()). The default only covers the INSERT.
-- READ-PATH NOTE: getSourcesByPolitician (ORDER BY created_at DESC) and getConfirmedFecSources (ORDER BY created_at
-- ASC) sort NULLs first / last respectively, so new dated rows land after / before the old undated ones. Order only;
-- no result set changes.
--
-- SET DEFAULT is a catalog-only change: no table rewrite, a brief ACCESS EXCLUSIVE lock.
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval and apply: Chris Andrews). Dry run (BEGIN ... ROLLBACK) passed and
--   the defaults were confirmed absent before the apply; verified after: both columns DEFAULT now(), 87,403 rows untouched
--   (77 / 8,887 dated).
--
-- ROLLBACK: ALTER TABLE transparent_motivations.politician_sources
--             ALTER COLUMN created_at DROP DEFAULT, ALTER COLUMN updated_at DROP DEFAULT;
-- IDEMPOTENT: SET DEFAULT to the same expression is a no-op on re-run, and the gate below still passes.

BEGIN;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT count(*) AS total, count(created_at) AS with_created, count(updated_at) AS with_updated
  FROM transparent_motivations.politician_sources;

ALTER TABLE transparent_motivations.politician_sources
  ALTER COLUMN created_at SET DEFAULT now(),
  ALTER COLUMN updated_at SET DEFAULT now();

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'politician_sources'
     AND column_name IN ('created_at', 'updated_at') AND column_default = 'now()';
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 columns carry DEFAULT now()', v_n; END IF;

  -- no existing row was touched: no backfill
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources;
  IF v_n <> b.total THEN RAISE EXCEPTION 'POST: row count moved from % to %', b.total, v_n; END IF;
  SELECT count(created_at) INTO v_n FROM transparent_motivations.politician_sources;
  IF v_n <> b.with_created THEN RAISE EXCEPTION 'POST: dated created_at rows moved from % to %', b.with_created, v_n; END IF;
  SELECT count(updated_at) INTO v_n FROM transparent_motivations.politician_sources;
  IF v_n <> b.with_updated THEN RAISE EXCEPTION 'POST: dated updated_at rows moved from % to %', b.with_updated, v_n; END IF;

  RAISE NOTICE 'CA_0249 applied: created_at and updated_at DEFAULT now(); % rows untouched (% / % dated)',
    b.total, b.with_created, b.with_updated;
END $$;

COMMIT;
