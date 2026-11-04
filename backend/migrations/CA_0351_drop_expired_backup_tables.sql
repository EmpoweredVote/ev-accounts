BEGIN;

-- =============================================================================
-- CA_0351: drop four expired backup tables; keep the twelve archives
-- =============================================================================
-- Created 2026-11-02 with Chris Andrews. Steward slot CA_0351. Follows CA_0348–
-- CA_0350 (PR #1273), which left sixteen backup/scratch tables on the Supabase
-- advisor's INFO `rls_enabled_no_policy` list as drop candidates, undecided.
--
-- Apply as `postgres` (owner of all sixteen). STATUS: APPLIED to prod 2026-11-02
-- (operator approval: Chris Andrews), via psql as postgres. Verified after: the
-- four are gone, all twelve archives present, live civic_spaces.posts 12 and
-- essentials.quotes 4,212 unchanged.
--
-- HOW EACH TABLE WAS JUDGED (2026-11-02, live)
-- For every table: the migration that created it and why; every reader, by
-- searching every repo under the workspace (code, docs, CI, planning notes) and
-- the live catalog — views, matviews, functions (prosrc), pg_cron jobs, foreign
-- keys in and out, triggers, and extensions.pg_stat_statements by role. No
-- view, function, cron job, foreign key or trigger touches any of the sixteen.
-- The only statements naming them in pg_stat_statements are the migrations that
-- wrote them (postgres) and CC_0296's gate (ev_api). The repo's references are
-- all migrations, plus check-rls-coverage.mjs / ci.yml naming
-- _fabricated_ca0156_removed in a comment.
--
-- DROPPED (4) — a one-time undo snapshot whose undo window has closed
--
--   table                                        rows   size    created by
--   civic_spaces.posts_backup_20260902             12   16 kB   civic-spaces 20260902000040
--   civic_spaces.slice_members_backup_20260902     24   16 kB   civic-spaces 20260902000040
--   civic_spaces.slices_backup_20260902            16   16 kB   civic-spaces 20260902000040
--   essentials.quotes_backup_260420               114   72 kB   070_quotes_deidentified_text
--
--   * civic_spaces.*_backup_20260902: snapshot taken 2026-09-01 so the slice-
--     taxonomy cut (civic-spaces 20260902000100) could be undone. That phase
--     shipped 2026-09-02 and is marked Complete in civic-spaces' ROADMAP; four
--     more phases have shipped on the new taxonomy since. All 12 backed-up posts
--     — the part the snapshot called irreplaceable — are still live, same id,
--     same body. The memberships and slices are re-derivable by design, and the
--     snapshot's own restore recipe would now wipe two months of later state.
--     ⚠ Its table comment says "drop only once Task 8 has verified a real member
--     end to end". Task 8's checkboxes were never ticked; its last step (record
--     the phase in the roadmap) was done. The member it named no longer has an
--     NC profile, so the check cannot be re-run. The dump below keeps the rows.
--   * essentials.quotes_backup_260420: pre-curation snapshot of essentials.quotes
--     taken 2026-04-20 before the Read & Rank curation pass deleted quotes. 22 of
--     its 114 rows are not in live quotes — the quotes that pass deliberately
--     removed. Nothing reads it; curation finished six months ago and live
--     quotes has grown to 4,212.
--
-- WHAT WAS DESTROYED, AND WHERE IT CAN BE RECOVERED
-- All four tables (schema and every row) were dumped before this file was
-- written, with pg_dump 17.11 --no-owner --no-privileges, to
-- `backup-tables-drop-2026-11-02.sql` (64,786 bytes, sha256 b906c4ca71159e1f
-- 75135bb90689d3121671c944f0f888ec124326d22ccfd730) in Chris Andrews' private
-- side-session notes folder for this work (local_b92e877e…), outside the repo.
-- The repo is public and two tables hold member posts, so the rows are NOT here.
-- The dump was restored into a scratch Postgres 17 and counted 12 / 24 / 16 /
-- 114. To restore: create the schemas if needed, then `psql -f` the dump as
-- postgres, and re-apply RLS on with no policy plus REVOKE ALL FROM anon,
-- authenticated (the dump carries no privileges).
--
-- KEPT (12) — and why each must stay
--
--   essentials._dedupe_1586_removed        34    16 kB  ┐ ev-cto decision 0015,
--   essentials._fabricated_1588_removed     2    16 kB  │ Part C: founder decision
--   essentials._fabricated_1590_removed     2    16 kB  │ 2026-09-10, "KEEP and
--   essentials._retired_1589_candidates     5    16 kB  │ protect, do NOT drop".
--   essentials._retired_1589_races          5    16 kB  ┘ 1596 amended this one.
--   essentials._fabricated_ca0156_removed  19    56 kB   same kind as the five; the
--     rollback for CA_0156 and CA_0159 reads it, and 19 live politicians.notes
--     rows tell a reader their deleted term was archived there.
--   essentials._retired_ca0206_offices     76,330  8000 kB  ┐ rollback archives for
--   essentials._retired_ca0206_office_terms 76,330 17 MB    │ occupancy migrations,
--   essentials._retired_ca0286_offices      11    32 kB    │ each header's restore
--   essentials._retired_ca0286_office_terms 11    32 kB    │ recipe reads them, and
--   essentials._retired_ca0287_chambers      1    32 kB    │ the same founder rule
--   essentials._retired_ca0287_offices       8    32 kB    ┘ covers rollback snapshots.
--   CC_0296's post-verify gate also reads _fabricated_ca0156_removed,
--   _retired_1589_races, _retired_ca0206_office_terms and
--   _retired_ca0286_office_terms.
--
-- Idempotent: DROP TABLE IF EXISTS; the pre-check only counts tables still there.
-- =============================================================================

-- (pre) Each table still holds exactly what was dumped. A count that moved means
-- the dump is stale: stop, re-dump, and update the header.
DO $$
DECLARE r record; v_n bigint;
BEGIN
  FOR r IN SELECT * FROM (VALUES
      ('civic_spaces.posts_backup_20260902',         12),
      ('civic_spaces.slice_members_backup_20260902', 24),
      ('civic_spaces.slices_backup_20260902',        16),
      ('essentials.quotes_backup_260420',           114)) AS t(tbl, n)
  LOOP
    IF to_regclass(r.tbl) IS NOT NULL THEN
      EXECUTE format('SELECT count(*) FROM %s', r.tbl) INTO v_n;
      IF v_n <> r.n THEN
        RAISE EXCEPTION 'CA_0351 PRE: % has % rows, the dump recorded %', r.tbl, v_n, r.n;
      END IF;
    END IF;
  END LOOP;
END $$;

DROP TABLE IF EXISTS civic_spaces.posts_backup_20260902;
DROP TABLE IF EXISTS civic_spaces.slice_members_backup_20260902;
DROP TABLE IF EXISTS civic_spaces.slices_backup_20260902;
DROP TABLE IF EXISTS essentials.quotes_backup_260420;

-- (post) The four are gone and all twelve kept archives are still here.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
      'civic_spaces.posts_backup_20260902',
      'civic_spaces.slice_members_backup_20260902',
      'civic_spaces.slices_backup_20260902',
      'essentials.quotes_backup_260420']
  LOOP
    IF to_regclass(t) IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0351 POST: % still exists', t;
    END IF;
  END LOOP;

  FOREACH t IN ARRAY ARRAY[
      'essentials._dedupe_1586_removed',
      'essentials._fabricated_1588_removed',
      'essentials._fabricated_1590_removed',
      'essentials._fabricated_ca0156_removed',
      'essentials._retired_1589_candidates',
      'essentials._retired_1589_races',
      'essentials._retired_ca0206_offices',
      'essentials._retired_ca0206_office_terms',
      'essentials._retired_ca0286_offices',
      'essentials._retired_ca0286_office_terms',
      'essentials._retired_ca0287_chambers',
      'essentials._retired_ca0287_offices']
  LOOP
    IF to_regclass(t) IS NULL THEN
      RAISE EXCEPTION 'CA_0351 POST: kept archive % is missing', t;
    END IF;
  END LOOP;

  RAISE NOTICE 'CA_0351 OK: 4 backup tables dropped, 12 archives kept';
END $$;

COMMIT;
