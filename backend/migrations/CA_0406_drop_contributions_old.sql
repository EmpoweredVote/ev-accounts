-- CA_0406 — drop transparent_motivations.contributions_old (ev-cto 0038 Part D, Step 5)
--
-- WHAT. CA_0398 (applied 2026-11-19 19:15-19:17:44 UTC) swapped the slim copy in as `contributions` and kept the
-- original as `contributions_old`, closed to every role but postgres, as the undo path. This drops it.
--
-- WHAT THIS DESTROYS (recorded here because nothing else will hold it):
--   * contributions_old: 34 GB total (19 GB heap + TOAST + 10 indexes), ~29.79M rows (reltuples, 2026-11-20).
--   * Its only unique content is the FEC `raw_record` JSON. Every key a reader uses is a typed column on the new
--     table (inventory: ev-cto tasks/2026-11-13-disk-io-d1-raw-record-inventory.md, founder-approved 2026-11-13);
--     the rest is re-downloadable from the FEC by sub_id = source_transaction_id (13,791 / 13,791 sampled FEC rows
--     equal, 2026-11-20). State-source JSON is NOT lost: the new table still carries it until Step 6 archives it.
--   * Attached and dropped with it: trigger contributions_fill_typed (the FUNCTION stays, the new table uses it),
--     policy "contributions: public read" (the new table has its own), checks
--     chk_transparent_motivations_contributions_confidence_level / _data_source, contributions_old_pkey, and
--     ACL {postgres=arwdDxtm/postgres} (CA_0398 revoked anon/authenticated/ev_api/service_role).
--
-- WHY IT IS SAFE (2026-11-19/20):
--   * Every copied row passed _ca0381_row_ok at copy time; writes during the copy were mirrored (CA_0381).
--   * CA_0398 sampled 0.1% both ways: 0 missing, typed values equal to contribution_typed_fields(raw).
--   * Donor read functions run against both tables for 8 politicians across 8 sources: identical (one float-
--     summation rounding difference). verify-fec-retirement-invariant: PASS on both.
--   * Read/write counters on contributions_old unchanged from 2026-11-19 20:21 to 2026-11-20 12:49: nothing uses it.
--   * 0.05% sample 2026-11-20 ~13:00 UTC: 15,588 old rows, 0 missing from the new table.
--
-- THIS FILE re-checks completeness on a SYSTEM sample of `ca0406.sample_pct` percent (default 2) of the old
-- table's blocks: every sampled old id must exist in the new table, or be an FEC line the new table has since
-- superseded (same source, committee, report, donor, amount and date at a higher file_number — the retirement
-- rule, which deletes rows after the swap legitimately). Anything else aborts and nothing is dropped. The copy
-- worked in 1,000-block batches, so a lost batch is caught almost surely by a 2% block sample.
--
-- DROP is not CASCADE: an unseen dependent stops it.
-- Run only in the quiet window, 19:00-02:59 UTC, never on the 1st (the sample reads ~0.5 GB).
--
-- UNDO: none inside the database. Only a Supabase backup restored to a separate project brings the rows back.
--
-- STATUS: APPLIED 2026-11-21 01:02:45-01:08:25 UTC (scheduled 19:15 run on 11-20 never fired: the client machine
-- slept). Sample 2%: 591,152 old rows, 6 missing from new, all 6 superseded FEC lines; post-verify ok. Database
-- 66 GB -> 32 GB; live contributions 9.9 GB; no restart. Earlier: WRITTEN 2026-11-20, rehearsed with ROLLBACK
-- (0.05% sample, 0 missing) and 6 tamper controls.

BEGIN;
SET LOCAL statement_timeout = '30min';
SET LOCAL lock_timeout = '3s';

-- 1. Pre-check.
DO $$
DECLARE
  old_t oid := to_regclass('transparent_motivations.contributions_old');
  new_t oid := to_regclass('transparent_motivations.contributions');
  pct numeric := coalesce(nullif(current_setting('ca0406.sample_pct', true), ''), '2')::numeric;
  est bigint; sampled bigint; missing bigint; explained bigint; n int;
BEGIN
  IF old_t IS NULL THEN RAISE EXCEPTION 'CA_0406: contributions_old does not exist'; END IF;
  IF new_t IS NULL OR new_t = old_t THEN RAISE EXCEPTION 'CA_0406: contributions is missing or is the old table'; END IF;
  IF (SELECT relkind FROM pg_class WHERE oid = old_t) <> 'r' THEN RAISE EXCEPTION 'CA_0406: contributions_old is not a table'; END IF;

  -- The live table is the slim one, with its two triggers.
  IF pg_total_relation_size(new_t) > 15::bigint * 1024 * 1024 * 1024 THEN
    RAISE EXCEPTION 'CA_0406: live contributions is % — not the slim table', pg_size_pretty(pg_total_relation_size(new_t));
  END IF;
  IF (SELECT array_agg(tgname::text ORDER BY tgname) FROM pg_trigger WHERE tgrelid = new_t AND NOT tgisinternal)
     IS DISTINCT FROM ARRAY['contributions_fill_typed', 'contributions_strip_fec_raw'] THEN
    RAISE EXCEPTION 'CA_0406: live contributions triggers are not {fill_typed, strip_fec_raw}';
  END IF;

  -- Nothing depends on the old table: no view/matview rules, no foreign keys either way.
  SELECT count(*) INTO n FROM pg_depend d JOIN pg_rewrite r ON r.oid = d.objid
   WHERE d.classid = 'pg_rewrite'::regclass AND d.refobjid = old_t AND r.ev_class <> old_t;
  IF n > 0 THEN RAISE EXCEPTION 'CA_0406: % view rule(s) depend on contributions_old', n; END IF;
  SELECT count(*) INTO n FROM pg_constraint WHERE contype = 'f' AND (conrelid = old_t OR confrelid = old_t);
  IF n > 0 THEN RAISE EXCEPTION 'CA_0406: % foreign key(s) touch contributions_old', n; END IF;

  -- Still closed, as CA_0398 left it.
  IF (SELECT relacl::text FROM pg_class WHERE oid = old_t) IS DISTINCT FROM '{postgres=arwdDxtm/postgres}' THEN
    RAISE EXCEPTION 'CA_0406: contributions_old ACL is %, expected postgres only', (SELECT relacl::text FROM pg_class WHERE oid = old_t);
  END IF;

  -- Completeness sample.
  SELECT reltuples::bigint INTO est FROM pg_class WHERE oid = old_t;
  EXECUTE format($q$
    WITH s AS (
      SELECT o.id, o.data_source, o.politician_source_id, o.donor_name_normalized, o.amount, o.contribution_date,
             coalesce(o.fec_committee_id, t.fec_committee_id) AS cmte,
             coalesce(o.fec_report_year,  t.fec_report_year)  AS ry,
             coalesce(o.fec_report_type,  t.fec_report_type)  AS rt,
             coalesce(o.fec_file_number,  t.fec_file_number)  AS fn
        FROM transparent_motivations.contributions_old o TABLESAMPLE SYSTEM (%s) REPEATABLE (406)
        CROSS JOIN LATERAL transparent_motivations.contribution_typed_fields(o.raw_record) t
    ), m AS (
      SELECT s.* FROM s
       WHERE NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions n WHERE n.id = s.id)
    )
    SELECT (SELECT count(*) FROM s),
           (SELECT count(*) FROM m),
           (SELECT count(*) FROM m
             WHERE m.data_source = 'fec' AND m.fn IS NOT NULL
               AND EXISTS (SELECT 1 FROM transparent_motivations.contributions n
                            WHERE n.politician_source_id = m.politician_source_id
                              AND n.data_source = 'fec' AND n.fec_file_number_present
                              AND n.fec_committee_id = m.cmte AND n.fec_report_year = m.ry
                              AND n.fec_report_type = m.rt
                              AND n.donor_name_normalized IS NOT DISTINCT FROM m.donor_name_normalized
                              AND n.amount = m.amount
                              AND n.contribution_date IS NOT DISTINCT FROM m.contribution_date
                              AND n.fec_file_number > m.fn))
  $q$, pct) INTO sampled, missing, explained;

  RAISE NOTICE 'CA_0406: sample of % percent of blocks: % old rows, % missing from new, % explained as superseded FEC lines',
    pct, sampled, missing, explained;
  IF sampled < 5000 OR sampled < (est * pct / 100.0) * 0.5 THEN
    RAISE EXCEPTION 'CA_0406: sample too small (% rows for % percent of ~% rows)', sampled, pct, est;
  END IF;
  IF missing > explained THEN
    RAISE EXCEPTION 'CA_0406: % sampled old row(s) are missing from the new table and not superseded — not dropping',
      missing - explained;
  END IF;

  PERFORM set_config('ca0406.old_oid', old_t::text, true);
END $$;

-- 2. Drop. Not CASCADE.
DROP TABLE transparent_motivations.contributions_old;

-- 3. Post-verify.
DO $$
DECLARE
  new_t oid := to_regclass('transparent_motivations.contributions');
  old_oid oid := current_setting('ca0406.old_oid')::oid;
  n int;
BEGIN
  IF to_regclass('transparent_motivations.contributions_old') IS NOT NULL THEN RAISE EXCEPTION 'CA_0406: old table still there'; END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE oid = old_oid) THEN RAISE EXCEPTION 'CA_0406: old relation oid % still exists', old_oid; END IF;
  SELECT count(*) INTO n FROM pg_class WHERE relnamespace = 'transparent_motivations'::regnamespace AND relname LIKE '%\_old%' AND relkind IN ('r','i');
  IF n > 0 THEN RAISE EXCEPTION 'CA_0406: % *_old relation(s) left', n; END IF;
  -- The live table is untouched.
  SELECT count(*) INTO n FROM pg_index WHERE indrelid = new_t AND indisvalid;
  IF n <> 6 THEN RAISE EXCEPTION 'CA_0406: live contributions has % valid indexes, expected 6', n; END IF;
  IF (SELECT array_agg(tgname::text ORDER BY tgname) FROM pg_trigger WHERE tgrelid = new_t AND NOT tgisinternal)
     IS DISTINCT FROM ARRAY['contributions_fill_typed', 'contributions_strip_fec_raw'] THEN
    RAISE EXCEPTION 'CA_0406: live triggers changed';
  END IF;
  IF to_regprocedure('transparent_motivations.contributions_fill_typed()') IS NULL THEN
    RAISE EXCEPTION 'CA_0406: contributions_fill_typed() function is gone';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = new_t AND polname = 'contributions: public read') THEN
    RAISE EXCEPTION 'CA_0406: live read policy missing';
  END IF;
  IF (SELECT relacl::text FROM pg_class WHERE oid = new_t)
     IS DISTINCT FROM '{postgres=arwdDxtm/postgres,anon=r/postgres,authenticated=r/postgres,ev_api=arwd/postgres}' THEN
    RAISE EXCEPTION 'CA_0406: live ACL changed: %', (SELECT relacl::text FROM pg_class WHERE oid = new_t);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_rewrite r ON r.oid = d.objid
                  WHERE d.refobjid = new_t AND r.ev_class = 'transparent_motivations.donor_names_search'::regclass) THEN
    RAISE EXCEPTION 'CA_0406: donor_names_search no longer reads the live table';
  END IF;
  RAISE NOTICE 'CA_0406: post-verify ok';
END $$;

COMMIT;
