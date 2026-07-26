-- 1463_drop_offices_politician_id.sql
-- ADR 0002 phase 5, part 2 of 2: drop essentials.offices.politician_id. Idempotent.
--
-- !! DO NOT APPLY UNTIL THE BACKEND THAT STOPPED READING THIS COLUMN IS DEPLOYED.
--    The API reads offices.politician_id in 13 places until that ship lands; dropping the column
--    under the running process turns every one of those queries into a 42703 undefined_column
--    error -- stance research, coverage stats, the coverage map, campaign-finance search, donor
--    detail, compass comparisons and the FEC matchers all start returning 500s.
--    Requires 1462 (which removes the view's and the RPC's dependency on the column) and the
--    deploy. 1462 is safe on its own and in any order; this file is the point of no return.
--
-- NO CASCADE, deliberately. If any view, function, constraint or index still depends on this
--   column, PostgreSQL must refuse and this migration must fail loudly. A silent CASCADE here
--   would drop somebody else's object as a side effect of a cleanup. The dependency audit run
--   against prod before writing found exactly four dependents:
--     - offices_politician_id_fkey            (FK, added by 1455) -> drops WITH the column, correct
--     - idx_offices_politician_id_nonuniq     (index)             -> drops WITH the column, correct
--     - essentials.office_current_holder      (view)              -> rewritten by 1462
--     - public.admin_list_politicians          (SECURITY DEFINER RPC) -> rewritten by 1462
--   The first two are column-local and go away with it; the last two had to be edited first, which
--   is the whole reason phase 5 is two files.
--
-- WHY THIS IS NOT A DATA LOSS. Every value in the column was copied into essentials.office_terms
--   by 1459, and the equivalence was asserted there with zero divergence. The pre-drop gate below
--   re-asserts it at drop time rather than trusting a migration that ran earlier: if a single
--   occupied office lacks a term, this aborts and the column stays.
--
-- ROLLBACK. Not reversible by re-adding the column -- the values would be gone. Recovery is
--   `UPDATE essentials.offices o SET politician_id = c.politician_id FROM
--    essentials.current_office_holders c WHERE c.office_id = o.id` after re-adding it, which
--   reconstructs today's snapshot from office_terms. History would be unaffected either way,
--   since office_terms is now the system of record.
--
-- essentials.offices is now what its name implies: a SEAT (district + chamber + title). Occupancy
--   is a separate, dated fact.
BEGIN;

-- ── Pre-drop gate: refuse to drop if office_terms cannot answer for every occupant ──
-- Dynamic SQL throughout, so this block still parses after the column is gone (idempotent re-run).
DO $$
DECLARE
  col_exists bool; n_missing int; n_col int; n_view int; v_def text;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='essentials' AND table_name='offices'
                    AND column_name='politician_id') INTO col_exists;

  IF NOT col_exists THEN
    RAISE NOTICE 'offices.politician_id already dropped -- nothing to do, verifying end state only.';
    RETURN;
  END IF;

  -- 1462 must have run: the view may no longer reference the column.
  SELECT pg_get_viewdef('essentials.office_current_holder'::regclass, true) INTO v_def;
  IF v_def ~* 'o\.politician_id|COALESCE' THEN
    RAISE EXCEPTION 'office_current_holder still falls back to offices.politician_id -- apply 1462 first';
  END IF;

  -- THE gate: every occupied office must have a current term, or dropping loses its holder.
  EXECUTE $q$
    SELECT count(*) FROM essentials.offices o
     WHERE o.politician_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM essentials.current_office_holders c WHERE c.office_id = o.id)
  $q$ INTO n_missing;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'REFUSING TO DROP: % occupied offices have no current term in office_terms', n_missing;
  END IF;

  -- and the two sources must agree on the count, so the drop is answer-preserving
  EXECUTE 'SELECT count(*) FROM essentials.offices WHERE politician_id IS NOT NULL' INTO n_col;
  SELECT count(*) INTO n_view
    FROM essentials.office_current_holder WHERE politician_id IS NOT NULL;
  IF n_col <> n_view THEN
    RAISE EXCEPTION 'REFUSING TO DROP: column claims % holders, office_terms resolves % -- reconcile first',
      n_col, n_view;
  END IF;

  RAISE NOTICE 'pre-drop gate PASSED: % holders, fully reproduced by office_terms.', n_col;
END $$;

ALTER TABLE essentials.offices DROP COLUMN IF EXISTS politician_id;

COMMENT ON TABLE essentials.offices IS
  'A SEAT: district + chamber + title. Occupancy is NOT here -- it lives in essentials.office_terms '
  'and is resolved at query time via essentials.office_current_holder (ADR 0002). offices.politician_id '
  'was dropped in phase 5 (migration 1463); is_vacant remains for seats known vacant without a date.';

-- ── Post-verify gate ──
DO $$
DECLARE n_col int; n_fk int; n_idx int; n_offices int; n_rows int; n_held int; n_future int;
BEGIN
  SELECT count(*) INTO n_col FROM information_schema.columns
   WHERE table_schema='essentials' AND table_name='offices' AND column_name='politician_id';
  IF n_col <> 0 THEN RAISE EXCEPTION 'offices.politician_id still present'; END IF;

  -- the FK and index were column-local; both must have gone with it
  SELECT count(*) INTO n_fk FROM pg_constraint
   WHERE conrelid='essentials.offices'::regclass AND conname='offices_politician_id_fkey';
  IF n_fk <> 0 THEN RAISE EXCEPTION 'offices_politician_id_fkey survived the column drop'; END IF;

  SELECT count(*) INTO n_idx FROM pg_indexes
   WHERE schemaname='essentials' AND indexname='idx_offices_politician_id_nonuniq';
  IF n_idx <> 0 THEN RAISE EXCEPTION 'idx_offices_politician_id_nonuniq survived the column drop'; END IF;

  -- the view must still work, still be one row per office, and still resolve every holder
  SELECT count(*) INTO n_offices FROM essentials.offices;
  SELECT count(*) INTO n_rows    FROM essentials.office_current_holder;
  IF n_rows <> n_offices THEN
    RAISE EXCEPTION 'view returns % rows for % offices', n_rows, n_offices;
  END IF;

  SELECT count(*) INTO n_held FROM essentials.office_current_holder WHERE politician_id IS NOT NULL;
  IF n_held = 0 THEN RAISE EXCEPTION 'view resolves NO holders -- occupancy lost'; END IF;

  -- office_terms is now the sole system of record; a term row must exist per resolved holder
  IF n_held <> (SELECT count(*) FROM essentials.current_office_holders WHERE politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'view and current_office_holders disagree after drop';
  END IF;

  SELECT count(*) INTO n_future FROM essentials.office_terms WHERE term_start > CURRENT_DATE;

  RAISE NOTICE 'phase 5 COMPLETE: column + FK + index dropped; % of % offices held, resolved solely from office_terms; % future term(s) pending.',
    n_held, n_offices, n_future;
END $$;

COMMIT;
