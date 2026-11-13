-- CA_0378_drop_politicians_is_incumbent.sql
-- Drop essentials.politicians.is_incumbent. Incumbency is derived from essentials.office_terms.
--
-- Created 2026-11-12 with Chris Andrews. Steward slot CA_0378.
--
-- WHY. The column was a stored copy of what office_terms already says, and nothing recomputed it when the calendar
-- moved. A future-dated term starts resolving as current on its own date; the flag did not follow. Every seeded
-- handover therefore went stale on its own date (Reno, 2026-11-13: mayor, city attorney, Ward 2) and turned master CI
-- red on whoever pushed next. PR #1420 (squash 98eda8a53) moved every READ to src/lib/incumbency.ts
-- (isIncumbentSql / IS_INCUMBENT_SELECT_SQL: a current tenure on a non-'Candidate for%' office). Measured before that
-- switch: the derived value matched the column for every ACTIVE politician. The same PR as this file removes every
-- remaining WRITE (stagingService, adminService, scripts/lib/politician-upsert.ts and the loaders) and the person-flag
-- half of reconcile-incumbency.mjs, and flips check:occupancy to FAIL an INSERT that names the column.
--
-- NOT race_candidates.is_incumbent. That is a different, still-live column ("held THIS race's seat on THIS race's
-- election day"); this file does not touch it.
--
-- DATABASE DEPENDENCIES, checked live 2026-11-12 (read-only): pg_depend on the column holds only its own DEFAULT.
-- No view or matview definition, no function body (prosrc), no index, no policy, no trigger and no pg_cron command
-- names is_incumbent on this table. Stored values at that time (is_incumbent, is_active -> rows):
--   false,false 77,363   false,true 3,622   true,false 110   true,true 10,763        total 91,858
--
-- WHAT IS DESTROYED, AND WHERE IT IS KEPT. Dropping the column discards one boolean per politician. Before the drop,
-- this file copies every (id, is_incumbent) pair into essentials._dropped_ca0378_politicians_is_incumbent (RLS on,
-- no policy, no grants to anon/authenticated), so the values survive and the ROLLBACK below can restore them exactly.
-- Nothing reads that table; drop it once nobody needs to undo this (a later CA_ migration, like CA_0351 did).
--
-- 🔴 APPLY ORDER: MERGE AND DEPLOY THE CODE FIRST. Until the PR that carries this file is live on ev-accounts-api,
-- the running API still names the column in two INSERTs (staging promotion, admin "create politician"); dropping it
-- earlier makes both fail with 42703. Apply only after the deploy that contains this file has finished.
--
-- Apply as the table owner (ALTER TABLE ... DROP COLUMN). No migration runner exists; this file records SQL applied
-- by hand. Dry run first: `node scripts/dry-run-migration.mjs migrations/CA_0378_drop_politicians_is_incumbent.sql`.
-- STATUS: NOT APPLIED. Dry-run OK 2026-11-12 (rolled back). Awaiting operator approval after the code deploy.
--
-- ROLLBACK (restores the column, its default and every stored value):
--   ALTER TABLE essentials.politicians ADD COLUMN is_incumbent boolean NOT NULL DEFAULT false;
--   UPDATE essentials.politicians p SET is_incumbent = b.is_incumbent
--     FROM essentials._dropped_ca0378_politicians_is_incumbent b WHERE b.politician_id = p.id;
--   (then revert the code PR — the old code writes the column.)
-- IDEMPOTENT: the archive is created IF NOT EXISTS and filled only while the column exists; DROP COLUMN IF EXISTS.
-- A re-run after a successful apply changes nothing and every gate still passes.

BEGIN;

-- ALTER TABLE takes an ACCESS EXCLUSIVE lock. DROP COLUMN is metadata-only, but waiting for the lock behind a long
-- read would queue every other query on this table, so give up quickly instead.
SET LOCAL lock_timeout = '5s';

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_type text; v_deps int;
BEGIN
  SELECT data_type INTO v_type FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent';
  IF v_type IS NOT NULL AND v_type <> 'boolean' THEN
    RAISE EXCEPTION 'PRE: essentials.politicians.is_incumbent is %, expected boolean', v_type;
  END IF;

  -- Anything in the catalog that depends on the column other than its own default. DROP COLUMN without CASCADE
  -- would refuse anyway; this says why, and refuses CASCADE-shaped surprises before they happen.
  IF v_type IS NOT NULL THEN
    SELECT count(*) INTO v_deps FROM pg_depend d
     WHERE d.refobjid = 'essentials.politicians'::regclass
       AND d.refobjsubid = (SELECT attnum FROM pg_attribute
                             WHERE attrelid = 'essentials.politicians'::regclass AND attname = 'is_incumbent')
       AND d.classid <> 'pg_attrdef'::regclass;
    IF v_deps <> 0 THEN
      RAISE EXCEPTION 'PRE: % catalog object(s) depend on politicians.is_incumbent — find and port them first', v_deps;
    END IF;
  END IF;
END $$;

-- ─── Keep the values ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS essentials._dropped_ca0378_politicians_is_incumbent (
  politician_id uuid PRIMARY KEY,
  is_incumbent  boolean NOT NULL
);
ALTER TABLE essentials._dropped_ca0378_politicians_is_incumbent ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials._dropped_ca0378_politicians_is_incumbent FROM anon, authenticated;
COMMENT ON TABLE essentials._dropped_ca0378_politicians_is_incumbent IS
  'Archive of essentials.politicians.is_incumbent as it stood when CA_0378 dropped the column. Only for undoing '
  'CA_0378 (see its ROLLBACK). Nothing reads it. Incumbency is derived from office_terms (src/lib/incumbency.ts).';

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent') THEN
    EXECUTE $q$
      INSERT INTO essentials._dropped_ca0378_politicians_is_incumbent (politician_id, is_incumbent)
      SELECT id, is_incumbent FROM essentials.politicians
      ON CONFLICT (politician_id) DO UPDATE SET is_incumbent = EXCLUDED.is_incumbent
    $q$;
  END IF;
END $$;

-- Archive must hold every row before the drop. Checked HERE, while the column still exists.
DO $$
DECLARE v_missing int; v_differs int;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent') THEN
    EXECUTE $q$
      SELECT count(*) FILTER (WHERE b.politician_id IS NULL),
             count(*) FILTER (WHERE b.is_incumbent IS DISTINCT FROM p.is_incumbent)
        FROM essentials.politicians p
        LEFT JOIN essentials._dropped_ca0378_politicians_is_incumbent b ON b.politician_id = p.id
    $q$ INTO v_missing, v_differs;
    IF v_missing <> 0 OR v_differs <> 0 THEN
      RAISE EXCEPTION 'ARCHIVE: % politician row(s) missing and % differing in the archive — not dropping', v_missing, v_differs;
    END IF;
  END IF;
END $$;

-- ─── The change ──────────────────────────────────────────────────────────────────────────────────
ALTER TABLE essentials.politicians DROP COLUMN IF EXISTS is_incumbent;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_pol int; v_arch int; v_active_disagree int;
BEGIN
  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: essentials.politicians.is_incumbent still exists'; END IF;

  -- race_candidates.is_incumbent is a different column and must still be there.
  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'race_candidates' AND column_name = 'is_incumbent';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: race_candidates.is_incumbent is missing — wrong table touched'; END IF;

  SELECT count(*) INTO v_pol  FROM essentials.politicians;
  SELECT count(*) INTO v_arch FROM essentials._dropped_ca0378_politicians_is_incumbent a
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = a.politician_id);
  IF v_arch <> v_pol THEN
    RAISE EXCEPTION 'POST: archive covers % of % politicians', v_arch, v_pol;
  END IF;

  -- Reported, not gated: how many ACTIVE people the stored flag disagreed with the derived value on. It goes stale on
  -- every handover by design; that is why it is being dropped.
  SELECT count(*) INTO v_active_disagree
    FROM essentials.politicians p
    JOIN essentials._dropped_ca0378_politicians_is_incumbent a ON a.politician_id = p.id
   WHERE p.is_active
     AND a.is_incumbent IS DISTINCT FROM EXISTS (
           SELECT 1 FROM essentials.current_office_holders coh
             JOIN essentials.offices o ON o.id = coh.office_id
            WHERE coh.politician_id = p.id AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%');
  RAISE NOTICE 'CA_0378 applied: politicians.is_incumbent dropped; % values archived; % active row(s) where the stored flag had drifted from office_terms',
    v_arch, v_active_disagree;
END $$;

COMMIT;
