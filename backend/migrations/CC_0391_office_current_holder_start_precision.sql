-- CC_0391 — expose start_precision on essentials.office_current_holder.
--
-- The read path serves a voter's "term start" from essentials.politicians.valid_from — the
-- DEPRECATED per-person snapshot, not the tenure. CLAUDE.md has said not to read it in new code
-- since ADR 0002 ("wrong entity — dates belong to a tenure, and people hold two offices"), and
-- every address, list and detail query still does. Measured on prod 2026-11-10:
--
--   office_terms rows carrying a start date                          4,169
--   people carrying a non-empty valid_from                             693
--   🔴 current, dated tenures showing NO date to a voter             4,033
--   ⚠ current tenures where the shown date DISAGREES with the term      39
--
-- ⚠ valid_from is TEXT and holds values like '2024', so it is not even a date: a cast over the
--   column errors with 'invalid input syntax for type date: "2024"'. That is how far the snapshot
--   has drifted from the thing it claims to describe.
--
-- The accompanying code change switches all ten select sites to essentials.office_current_holder,
-- which every one of those queries ALREADY JOINS. The view carries term_start, term_end and
-- how_started — but not start_precision, which the API returns as term_date_precision. The inner
-- view essentials.current_office_holders already selects start_precision and the outer one simply
-- drops it. This migration stops dropping it. That is the whole change.
--
-- 🔴 CREATE OR REPLACE, NEVER DROP. Three rewrite rules depend on this view, and a DROP ... CASCADE
--    would take them with it and silently discard the view's grants (anon/authenticated SELECT,
--    ev_api). REPLACE keeps the ACL, the ownership and security_invoker, and it is why the new
--    column is APPENDED: replacing a view may add columns only at the END, and may not rename,
--    reorder or retype the existing ones. start_precision therefore sits after from_office_terms
--    rather than next to term_start, which is cosmetically wrong and structurally required.
--
-- ⚠ security_invoker=true is restated explicitly rather than left to inheritance, so that the
--   property is visible in this file and asserted below. Both views carry it today.
--
-- 🔴 ev_api CANNOT RUN THIS. It is DDL, and apply-migration-file.mjs authenticates as ev_api.
--    Applied through the Supabase MCP, which connects privileged.
--
-- No column is dropped, no row is written, and nothing that reads the view today sees a
-- different value for any column it already selects.
--
-- Applied to production 2026-11-10.

BEGIN;

-- Capture the before-state so the gate can prove what changed and what did not.
CREATE TEMP TABLE och_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_current_holder)                        AS rows_total,
       (SELECT count(politician_id) FROM essentials.office_current_holder)            AS rows_held,
       (SELECT count(term_start) FROM essentials.office_current_holder)               AS rows_dated,
       (SELECT array_to_string(relacl, E'\n') FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'essentials' AND c.relname = 'office_current_holder')      AS acl,
       (SELECT count(*) FROM pg_depend d JOIN pg_rewrite r ON r.oid = d.objid
          JOIN pg_class c ON c.oid = d.refobjid
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'essentials' AND c.relname = 'office_current_holder'
           AND d.deptype = 'n' AND r.ev_class <> c.oid)                               AS dependents;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'office_current_holder'
     AND column_name = 'start_precision';
  IF v <> 0 THEN
    RAISE NOTICE 'CC_0391: office_current_holder already exposes start_precision; this is a no-op';
  END IF;

  -- The inner view is where the column comes from. If it ever stops selecting it, appending it
  -- below would fail with a confusing error about a missing column on office_terms.
  SELECT count(*) INTO v
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'current_office_holders'
     AND column_name = 'start_precision';
  IF v <> 1 THEN
    RAISE EXCEPTION 'CC_0391 pre-check: essentials.current_office_holders does not expose '
                    'start_precision, so the outer view cannot forward it';
  END IF;
END $$;

-- ── The view ──────────────────────────────────────────────────────────────────────────────────
-- Unchanged from the definition on prod except for the final column. LEFT JOIN from offices is
-- load-bearing and stays: 🔴 a vacancy is a row with a NULL politician_id, which is why callers
-- must count och.politician_id and never count(*).
CREATE OR REPLACE VIEW essentials.office_current_holder
WITH (security_invoker = true) AS
SELECT o.id AS office_id,
       coh.politician_id,
       coh.term_start,
       coh.term_end,
       coh.how_started,
       coh.office_id IS NOT NULL AS from_office_terms,
       -- 🔴 APPENDED, NOT INSERTED. CREATE OR REPLACE VIEW may only add columns at the end.
       -- 'unknown' pairs with a NULL term_start and means "this tenure is real and its start is
       -- not established" — a different statement from "there is no tenure", which is a NULL
       -- politician_id on this same row.
       coh.start_precision
  FROM essentials.offices o
  LEFT JOIN essentials.current_office_holders coh ON coh.office_id = o.id;

COMMENT ON COLUMN essentials.office_current_holder.start_precision IS
  'How precise term_start is: day | month | year | unknown. CC_0391 exposed it so the read path '
  'can serve term dates from office_terms instead of the deprecated politicians.valid_from '
  'snapshot. NULL when the office has no current holder at all.';

-- ── Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  b_total int; b_held int; b_dated int; b_acl text; b_dep int;
  a_total int; a_held int; a_dated int; a_acl text; a_dep int;
  v_pos int; v_opts text; v_prec int; v_mismatch int;
BEGIN
  SELECT rows_total, rows_held, rows_dated, acl, dependents
    INTO b_total, b_held, b_dated, b_acl, b_dep FROM och_before;

  SELECT count(*), count(politician_id), count(term_start)
    INTO a_total, a_held, a_dated FROM essentials.office_current_holder;

  -- Every column that existed before must still answer identically. Adding a column must not
  -- change a single row or a single value anybody already reads.
  IF (a_total, a_held, a_dated) IS DISTINCT FROM (b_total, b_held, b_dated) THEN
    RAISE EXCEPTION 'CC_0391 gate: the view changed shape — rows % -> %, held % -> %, dated % -> %',
                    b_total, a_total, b_held, a_held, b_dated, a_dated;
  END IF;

  -- The new column must be present, and LAST, or a positional consumer would be reading the
  -- wrong value. Nothing in this repo selects by position, and the ordering is still asserted.
  SELECT ordinal_position INTO v_prec
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'office_current_holder'
     AND column_name = 'start_precision';
  IF v_prec IS NULL THEN
    RAISE EXCEPTION 'CC_0391 gate: start_precision is not on the view';
  END IF;
  SELECT max(ordinal_position) INTO v_pos
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'office_current_holder';
  IF v_prec <> v_pos THEN
    RAISE EXCEPTION 'CC_0391 gate: start_precision is at position % of %, expected last',
                    v_prec, v_pos;
  END IF;

  -- 🔴 The grants must survive. A DROP would have taken them, and anon/authenticated losing
  --    SELECT is a production outage that no test in this repo would catch.
  SELECT array_to_string(relacl, E'\n') INTO a_acl
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname = 'office_current_holder';
  IF a_acl IS DISTINCT FROM b_acl THEN
    RAISE EXCEPTION 'CC_0391 gate: the view ACL changed. before=[%] after=[%]', b_acl, a_acl;
  END IF;

  -- security_invoker must still be on, or the view would read with the owner's rights.
  SELECT array_to_string(reloptions, ',') INTO v_opts
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname = 'office_current_holder';
  IF v_opts IS NULL OR v_opts NOT LIKE '%security_invoker=true%' THEN
    RAISE EXCEPTION 'CC_0391 gate: security_invoker is not on (reloptions=[%])', v_opts;
  END IF;

  SELECT count(*) INTO a_dep
    FROM pg_depend d JOIN pg_rewrite r ON r.oid = d.objid
    JOIN pg_class c ON c.oid = d.refobjid
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname = 'office_current_holder'
     AND d.deptype = 'n' AND r.ev_class <> c.oid;
  IF a_dep <> b_dep THEN
    RAISE EXCEPTION 'CC_0391 gate: dependent rules went % -> %. Something was dropped.',
                    b_dep, a_dep;
  END IF;

  -- The forwarded column must equal the inner view's, row for row — not merely be non-null.
  SELECT count(*) INTO v_mismatch
    FROM essentials.office_current_holder och
    LEFT JOIN essentials.current_office_holders coh ON coh.office_id = och.office_id
   WHERE och.start_precision IS DISTINCT FROM coh.start_precision;
  IF v_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0391 gate: % row(s) disagree with current_office_holders.start_precision',
                    v_mismatch;
  END IF;

  -- A held row must carry a precision; an empty seat must not.
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder
              WHERE politician_id IS NOT NULL AND start_precision IS NULL) THEN
    RAISE EXCEPTION 'CC_0391 gate: a held seat has a NULL start_precision';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder
              WHERE politician_id IS NULL AND start_precision IS NOT NULL) THEN
    RAISE EXCEPTION 'CC_0391 gate: an empty seat carries a start_precision';
  END IF;

  RAISE NOTICE 'CC_0391 OK: start_precision exposed at position % · % offices, % held, % dated · '
               'ACL, security_invoker and % dependent rule(s) all unchanged',
               v_prec, a_total, a_held, a_dated, a_dep;
END $$;

COMMIT;
