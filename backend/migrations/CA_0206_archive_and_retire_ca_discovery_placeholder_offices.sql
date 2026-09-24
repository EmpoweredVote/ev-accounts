-- CA_0206_archive_and_retire_ca_discovery_placeholder_offices.sql
-- Retire the 76,330 placeholder offices the May 2026 Cal-Access discovery sweep created, and their 76,330 placeholder
-- terms -- ARCHIVED FIRST into two locked tables, then deleted from the live tables. California's share of the
-- "77,001 placeholder occupancies" CC_0101 counted; the Indiana share was retired by CC_0101 - CC_0104.
-- Operator decision (Chris Andrews, 2026-09-24): archive, then delete.
--
-- WHAT THE PLACEHOLDERS ARE. discover-cal-access-candidates.ts (deleted in #677) made one essentials.politicians row
-- per Cal-Access committee filer -- the "names" are committee names ("FARLEY FOR COUNCIL", even "JAMES, FOR OUR
-- COMMUNITY HOSPITAL BILL") -- source = 'cal_access_discovery', all created 2026-05-22 -- and gave each one an office
-- of its own. Migration 1459 (ADR 0002 phase 2) turned each office's politician_id into an open office_terms row with
-- term_start NULL / 'unknown'. Measured 2026-09-24, every one of the 76,330:
--   - office: no district, no chamber, not flagged vacant; 73,793 have no title at all;
--   - exactly one term, held by its own discovery row; no other person ever held it; no race points at it;
--   - holder: is_active = false, is_incumbent = false, no race rows, no compass answers, 1 committee link, 0 confirmed.
-- They were 90% of essentials.offices (76,330 of 85,134) and of office_current_holder. No public read path shows them
-- (address search needs a district, browse needs a chamber, every person-rooted read needs is_active), so any count of
-- offices or officeholders that forgot to filter inactive holders was wrong by that much, and nothing else.
--
-- WHAT THIS FILE DOES.
--   1. Copies the 76,330 offices and 76,330 terms, row for row, into essentials._retired_ca0206_offices and
--      essentials._retired_ca0206_office_terms (LIKE the live tables, so the columns and their order match). The
--      copies are compared to the live rows (md5 of every row's text) BEFORE anything is deleted.
--   2. Deletes the 76,330 offices; their terms cascade (office_terms.office_id ON DELETE CASCADE). races.office_id
--      is NO ACTION, and no race points at them (gated).
--   3. Locks both archive tables the house way: row-level security on with no policy (default-deny, as CA_0186),
--      and SELECT revoked from anon and authenticated.
-- NOT TOUCHED: the 76,330 inactive discovery people and their 76,330 unconfirmed committee links stay (as the
-- Indiana retirement kept its people). offices_missing_terms does not move: every deleted office had a term.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run x2 with a planted control (tripped)
--   right before the apply; re-run after it changed nothing. Verified after: essentials.offices 85,134 -> 8,804,
--   office_terms 85,057 -> 8,727, both archives 76,330 rows with RLS on / no policy / no anon or authenticated SELECT,
--   the 76,330 discovery people and their 76,330 links unchanged, offices_missing_terms 428 unchanged.
--
-- ROLLBACK (restore everything, then the archive may be dropped):
--   INSERT INTO essentials.offices SELECT * FROM essentials._retired_ca0206_offices ON CONFLICT (id) DO NOTHING;
--   INSERT INTO essentials.office_terms SELECT * FROM essentials._retired_ca0206_office_terms ON CONFLICT (id) DO NOTHING;
-- IDEMPOTENT: a re-run finds no placeholder left in the live tables and the full set in the archive; it changes
-- nothing and every gate still passes.

BEGIN;

SET LOCAL statement_timeout = '15min';
-- A DELETE takes row locks only, but do not queue behind a long transaction on these tables.
SET LOCAL lock_timeout = '10s';

-- ─── The placeholder set (derived, then pinned) ──────────────────────────────────────────────────
CREATE TEMP TABLE _ph ON COMMIT DROP AS
SELECT o.id AS office_id, t.id AS term_id
  FROM essentials.offices o
  JOIN essentials.office_terms t ON t.office_id = o.id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE p.source = 'cal_access_discovery' AND NOT p.is_active AND NOT p.is_incumbent
   AND o.district_id IS NULL AND o.chamber_id IS NULL
   AND t.source = 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t2 WHERE t2.office_id = o.id AND t2.id <> t.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);
CREATE UNIQUE INDEX ON _ph (office_id);
ANALYZE _ph;

CREATE TABLE IF NOT EXISTS essentials._retired_ca0206_offices (LIKE essentials.offices INCLUDING DEFAULTS);
CREATE TABLE IF NOT EXISTS essentials._retired_ca0206_office_terms (LIKE essentials.office_terms INCLUDING DEFAULTS);
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0206_offices_pkey') THEN
    ALTER TABLE essentials._retired_ca0206_offices ADD CONSTRAINT _retired_ca0206_offices_pkey PRIMARY KEY (id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0206_office_terms_pkey') THEN
    ALTER TABLE essentials._retired_ca0206_office_terms ADD CONSTRAINT _retired_ca0206_office_terms_pkey PRIMARY KEY (id);
  END IF;
END $$;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices) AS offices,
       (SELECT count(*) FROM essentials.office_terms) AS terms,
       (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
       (SELECT count(*) FROM essentials.politicians WHERE source = 'cal_access_discovery') AS people,
       (SELECT count(*) FROM transparent_motivations.politician_sources ps
          JOIN essentials.politicians p ON p.id = ps.essentials_politician_id WHERE p.source = 'cal_access_discovery') AS links;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; v_arch int; v_arch_md5 text; v_held int;
BEGIN
  SELECT count(*), md5(string_agg(office_id::text, ',' ORDER BY office_id)) INTO v_n, v_md5 FROM _ph;
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)) INTO v_arch, v_arch_md5 FROM essentials._retired_ca0206_offices;

  -- first run: the reviewed 76,330 are live and the archive is empty; re-run: none live, all archived
  IF NOT ((v_n = 76330 AND v_md5 = '8d7fcd94780e685d7aa0323c7aaafd63' AND v_arch = 0)
       OR (v_n = 0 AND v_arch = 76330 AND v_arch_md5 = '8d7fcd94780e685d7aa0323c7aaafd63')) THEN
    RAISE EXCEPTION 'PRE: placeholder set is not the reviewed one: live % (md5 %), archived % (md5 %); expected 76330 / 8d7fcd94780e685d7aa0323c7aaafd63',
      v_n, v_md5, v_arch, v_arch_md5;
  END IF;

  -- nothing a discovery row holds escapes the definition (so no placeholder is silently left behind)
  SELECT count(DISTINCT t.office_id) INTO v_held FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id WHERE p.source = 'cal_access_discovery';
  IF v_held <> v_n THEN RAISE EXCEPTION 'PRE: discovery rows hold % offices, % match the placeholder definition', v_held, v_n; END IF;
END $$;

-- ─── 1. Archive, and prove the copy is exact before deleting ─────────────────────────────────────
INSERT INTO essentials._retired_ca0206_offices
SELECT o.* FROM essentials.offices o JOIN _ph ON _ph.office_id = o.id
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials._retired_ca0206_office_terms
SELECT t.* FROM essentials.office_terms t JOIN _ph ON _ph.term_id = t.id
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE v_live text; v_arch text; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _ph;
  IF v_n > 0 THEN
    SELECT md5(string_agg(o::text, '|' ORDER BY o.id)) INTO v_live FROM essentials.offices o JOIN _ph ON _ph.office_id = o.id;
    SELECT md5(string_agg(a::text, '|' ORDER BY a.id)) INTO v_arch FROM essentials._retired_ca0206_offices a JOIN _ph ON _ph.office_id = a.id;
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: office copies differ from the live rows (% vs %)', v_live, v_arch; END IF;
    SELECT md5(string_agg(t::text, '|' ORDER BY t.id)) INTO v_live FROM essentials.office_terms t JOIN _ph ON _ph.term_id = t.id;
    SELECT md5(string_agg(a::text, '|' ORDER BY a.id)) INTO v_arch FROM essentials._retired_ca0206_office_terms a JOIN _ph ON _ph.term_id = a.id;
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: term copies differ from the live rows (% vs %)', v_live, v_arch; END IF;
  END IF;
END $$;

-- ─── 2. Delete (terms cascade) ───────────────────────────────────────────────────────────────────
DELETE FROM essentials.offices o USING _ph WHERE o.id = _ph.office_id;

-- ─── 3. Lock the archive (default-deny, as CA_0186) ──────────────────────────────────────────────
ALTER TABLE essentials._retired_ca0206_offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._retired_ca0206_office_terms ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials._retired_ca0206_offices, essentials._retired_ca0206_office_terms FROM anon, authenticated;
COMMENT ON TABLE essentials._retired_ca0206_offices IS
  'CA_0206 (2026-09-24): archive of the 76,330 cal_access_discovery placeholder offices, deleted from essentials.offices. Restore with INSERT ... SELECT * (see the migration header).';
COMMENT ON TABLE essentials._retired_ca0206_office_terms IS
  'CA_0206 (2026-09-24): archive of the 76,330 migration-1459 backfill terms on the cal_access_discovery placeholder offices.';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)) INTO v_n, v_md5 FROM essentials._retired_ca0206_offices;
  IF v_n <> 76330 OR v_md5 <> '8d7fcd94780e685d7aa0323c7aaafd63' THEN RAISE EXCEPTION 'POST: archive holds % offices (md5 %)', v_n, v_md5; END IF;
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)) INTO v_n, v_md5 FROM essentials._retired_ca0206_office_terms;
  IF v_n <> 76330 OR v_md5 <> '7d3e7f01d665ce752ac5153ffd6c80b5' THEN RAISE EXCEPTION 'POST: archive holds % terms (md5 %)', v_n, v_md5; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials._retired_ca0206_offices a ON a.id = o.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % archived office(s) still live', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t JOIN essentials._retired_ca0206_office_terms a ON a.id = t.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % archived term(s) still live', v_n; END IF;

  -- exactly the retired rows left the live tables (b is taken after a re-run's no-op, so compare to what was live)
  SELECT count(*) INTO v_n FROM essentials.offices;
  IF v_n <> b.offices - (SELECT count(*) FROM _ph) THEN RAISE EXCEPTION 'POST: offices % -> %, expected -%', b.offices, v_n, (SELECT count(*) FROM _ph); END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> b.terms - (SELECT count(*) FROM _ph) THEN RAISE EXCEPTION 'POST: terms % -> %, expected -%', b.terms, v_n, (SELECT count(*) FROM _ph); END IF;

  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> b.missing_terms THEN RAISE EXCEPTION 'POST: offices_missing_terms moved % -> %', b.missing_terms, v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source = 'cal_access_discovery';
  IF v_n <> b.people THEN RAISE EXCEPTION 'POST: discovery people moved % -> %', b.people, v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id WHERE p.source = 'cal_access_discovery';
  IF v_n <> b.links THEN RAISE EXCEPTION 'POST: discovery links moved % -> %', b.links, v_n; END IF;

  SELECT count(*) INTO v_n FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname IN ('_retired_ca0206_offices', '_retired_ca0206_office_terms') AND c.relrowsecurity;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: row-level security is on for % of 2 archive tables', v_n; END IF;

  RAISE NOTICE 'CA_0206 applied: 76,330 placeholder offices and terms archived and retired; people and links untouched';
END $$;

COMMIT;
