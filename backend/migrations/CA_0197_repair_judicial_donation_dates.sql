-- CA_0197_repair_judicial_donation_dates.sql
-- Put every judicial.donations.contribution_date back on the day the SOS export reports, recomputed from the row's
-- own raw_record RCPT_DATE.
--
-- THE DEFECT: judicial.donations.contribution_date is a `date`. calAccessAdapter builds RCPT_DATE as a JS Date at
-- UTC midnight (Date.UTC(y, m - 1, d)), and writeJudicialDonations passed that Date straight to node-postgres, which
-- serialises a Date in the HOST's local time zone. The 2026-09-23 re-run (after CA_0196) ran from a host in
-- America/Indianapolis (UTC-4), so 2018-12-03T00:00:00Z went out as 2018-12-02T20:00:00-04:00 and Postgres kept
-- 2018-12-02. Measured 2026-09-23 (read-only), right after that run:
--   - 1,040 of 1,040 rows have contribution_date = the UTC date of raw_record RCPT_DATE minus exactly one day;
--   - 1,040 of 1,040 carry RCPT_DATE in the adapter's canonical form 'YYYY-MM-DDT00:00:00.000Z', so the UTC date
--     of RCPT_DATE is the SOS date (the local parse of the same export gave e.g. Michel's last receipt 2018-12-03;
--     the column holds 2018-12-02);
--   - no row changes calendar year, so nothing derived from the year moves.
-- The code fix (same PR): writeJudicialDonations now sends toUtcDateString(date) — 'YYYY-MM-DD' from the UTC fields.
-- NOT AFFECTED: transparent_motivations.contributions.contribution_date is timestamptz, which stores the instant;
-- all 188,323 of its cal_access rows match their RCPT_DATE (measured the same day).
--
-- WHY A MIGRATION AND NOT A RE-RUN: writeJudicialDonations upserts ON CONFLICT and only touches updated_at, so a
-- re-run never rewrites a stored date. raw_record holds the source value for every row.
--
-- SCOPE (pinned by count and an md5 of the sorted ids — a changed population fails the pre-flight):
--   1,040 judicial.donations rows (all of them; 3 judges), each exactly one day early. The predicate is the defect:
--   contribution_date differs from the UTC date of raw_record RCPT_DATE.
-- NOT TOUCHED: every other column. updated_at is set to now() on the repaired rows, as any other write would.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 23:39 UTC (operator approval: Chris Andrews, in chat). Dry run first as
--   BEGIN ... ROLLBACK: pre-flight passed, UPDATE 1040, post gate passed, and after the rollback all 1,040 dates were
--   still one day early. Apply: UPDATE 1040, post gate passed. Re-run after (as ROLLBACK): UPDATE 0, every gate
--   passes. Date ranges now equal the local parse: Mathai 2013-09-27..2014-11-27, Townsend 2015-07-09..2017-05-01,
--   Michel 2018-02-07..2018-12-03.
--
-- ROLLBACK: UPDATE judicial.donations SET contribution_date = contribution_date - 1 WHERE id IN (<the pinned ids>)
--   would restore the wrong dates; there is no reason to.
-- IDEMPOTENT: a re-run finds 0 differing rows, updates nothing, and every gate passes.

BEGIN;

CREATE TEMP TABLE _fix ON COMMIT DROP AS
SELECT id,
       contribution_date AS stored_date,
       ((raw_record ->> 'RCPT_DATE')::timestamptz AT TIME ZONE 'UTC')::date AS source_date
  FROM judicial.donations
 WHERE contribution_date IS DISTINCT FROM ((raw_record ->> 'RCPT_DATE')::timestamptz AT TIME ZONE 'UTC')::date;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; v_not_one_day int; v_no_source int;
BEGIN
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)),
         count(*) FILTER (WHERE stored_date IS DISTINCT FROM source_date - 1),
         count(*) FILTER (WHERE source_date IS NULL)
    INTO v_n, v_md5, v_not_one_day, v_no_source
    FROM _fix;

  IF v_n = 0 THEN
    RAISE NOTICE 'PRE: every judicial.donations date already matches its RCPT_DATE (a re-run); nothing to repair';
  ELSIF v_n <> 1040 OR v_md5 <> '3da5fc5cc868dca9dc3062ba038dfc9e' THEN
    RAISE EXCEPTION 'PRE: the population changed: % rows, md5 % (expected 1040, 3da5fc5cc868dca9dc3062ba038dfc9e)', v_n, v_md5;
  END IF;

  -- The measured defect is exactly one day early. Any other difference (or a row with no RCPT_DATE, which would be
  -- set to NULL) is a different problem and must not be "repaired" by this file.
  IF v_not_one_day <> 0 OR v_no_source <> 0 THEN
    RAISE EXCEPTION 'PRE: % row(s) differ by other than one day, % have no RCPT_DATE', v_not_one_day, v_no_source;
  END IF;
END $$;

-- ─── Repair ──────────────────────────────────────────────────────────────────────────────────────
UPDATE judicial.donations d
   SET contribution_date = f.source_date,
       updated_at = now()
  FROM _fix f
 WHERE d.id = f.id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n
    FROM judicial.donations
   WHERE contribution_date IS DISTINCT FROM ((raw_record ->> 'RCPT_DATE')::timestamptz AT TIME ZONE 'UTC')::date;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % judicial.donations dates still differ from RCPT_DATE', v_n; END IF;

  SELECT count(*) INTO v_n FROM judicial.donations d JOIN _fix f ON f.id = d.id WHERE d.contribution_date <> f.stored_date + 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % repaired row(s) moved by other than one day', v_n; END IF;

  RAISE NOTICE 'POST OK: every judicial.donations date matches its RCPT_DATE';
END $$;

COMMIT;
