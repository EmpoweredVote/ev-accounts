-- CA_0171_office_holders_as_of_skip_unverified.sql
-- Make essentials.office_holders_as_of(date) skip terms whose source carries the tag '| unverified <slot>'.
--
-- WHY. CA_0156 (LA unified boards, 174 terms) and CA_0159 (LA elementary/high boards, 135 terms) kept the
-- closed terms of placeholder politicians they could not disprove, tagged '| unverified CA_0156' /
-- '| unverified CA_0159' ("absence is not disproof" -- 1588/1590). Every one of those 309 terms has
-- term_start NULL, so daterange(NULL, term_end) covers the seat from the beginning of time. The history
-- function therefore answered "who held this seat in 2019?" with a seeded name nobody could find: measured
-- 2026-09-23, office_holders_as_of('2020-06-01') returned all 95 terms of the 99 rows CA_0169 re-checked.
-- No app code calls the function today (backend/src has no caller; only old migrations use it in gates),
-- so this fixes the answer before anyone builds on it. The terms themselves stay, as both audits decided.
--
-- WHAT. One added predicate: COALESCE(ot.source, '') NOT LIKE '%| unverified %'. The marker is the
-- convention, not the slot: a future audit that keeps a term it cannot verify uses the same tag and gets
-- the same treatment. At the time of writing exactly 309 terms match '%unverified%' and all 309 carry the
-- marker. To see them anyway, read essentials.office_terms directly.
--
-- NOT CHANGED: essentials.office_current_holder (reads open terms only; these terms are all closed), the
-- office_terms_no_overlap exclusion constraint (a real historical term on such a seat is still refused
-- until the unverified term is dealt with -- a loud failure, which is the point), grants (CREATE OR REPLACE
-- keeps them; asserted below).
--
-- No migration runner exists; applied by hand over psql (DATABASE_URL). Operator approval: Chris Andrews,
-- 2026-09-23 ("I agree with your recommendations, go ahead" -- option (a), guard the history function).
--
-- ROLLBACK: re-run the CREATE OR REPLACE and COMMENT from 1458_office_terms_schema.sql.
-- IDEMPOTENT: CREATE OR REPLACE; the gates compare the function with a direct query, so a re-run passes.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _grants ON COMMIT DROP AS
  SELECT r.rolname, has_function_privilege(r.rolname, 'essentials.office_holders_as_of(date)', 'EXECUTE') AS can_exec
    FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated', 'service_role', 'ev_api');

-- ─── PRE-VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_m int;
BEGIN
  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'essentials' AND p.proname = 'office_holders_as_of') <> 1 THEN
    RAISE EXCEPTION 'PRE: expected exactly one essentials.office_holders_as_of'; END IF;

  -- the marker is the only form "unverified" takes in term sources (no near-miss spellings to leak)
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE source ILIKE '%unverified%';
  SELECT count(*) INTO v_m FROM essentials.office_terms WHERE source LIKE '%| unverified %';
  IF v_n <> v_m THEN RAISE EXCEPTION 'PRE: % sources mention unverified but only % carry the marker', v_n, v_m; END IF;
  IF v_m = 0 THEN RAISE EXCEPTION 'PRE: no marked terms found -- nothing to guard'; END IF;

  -- nothing that is still OPEN is marked (a marked open term would vanish from history but not from
  -- office_current_holder, which would be a contradiction)
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE source LIKE '%| unverified %' AND term_end IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % open terms carry the unverified marker', v_n; END IF;

  RAISE NOTICE 'PRE: % marked terms; % of them answer office_holders_as_of(2020-06-01) before the change',
    v_m, (SELECT count(*) FROM essentials.office_holders_as_of('2020-06-01') h
            JOIN essentials.office_terms ot ON ot.office_id = h.office_id AND ot.politician_id IS NOT DISTINCT FROM h.politician_id
                                           AND ot.term_start IS NOT DISTINCT FROM h.term_start AND ot.term_end IS NOT DISTINCT FROM h.term_end
           WHERE ot.source LIKE '%| unverified %');
END $$;

-- ─── 1. The function ────────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION essentials.office_holders_as_of(as_of date)
RETURNS TABLE (office_id uuid, politician_id uuid, term_start date, term_end date)
LANGUAGE sql STABLE AS $$
  SELECT ot.office_id, ot.politician_id, ot.term_start, ot.term_end
    FROM essentials.office_terms ot
   WHERE (ot.term_start IS NULL OR ot.term_start <= as_of)
     AND (ot.term_end   IS NULL OR ot.term_end   >= as_of)
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
$$;

COMMENT ON FUNCTION essentials.office_holders_as_of(date) IS
  'Who held each office on a given date. Answers "who represented me in 2019" without a schema '
  'change (ADR 0002). Skips terms whose source carries ''| unverified <slot>'' -- placeholder terms an '
  'audit kept but could not verify (CA_0156, CA_0159); read essentials.office_terms to see them (CA_0171).';

-- ─── POST-VERIFY ────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE d date; v_fn int; v_direct int; v_bad int;
BEGIN
  FOREACH d IN ARRAY ARRAY['2019-01-01', '2020-06-01', '2022-06-01', '2024-06-01', current_date]::date[] LOOP
    SELECT count(*) INTO v_fn FROM essentials.office_holders_as_of(d);
    SELECT count(*) INTO v_direct FROM essentials.office_terms ot
     WHERE (ot.term_start IS NULL OR ot.term_start <= d) AND (ot.term_end IS NULL OR ot.term_end >= d)
       AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
    IF v_fn <> v_direct THEN RAISE EXCEPTION 'POST: % -- function returns %, direct query %', d, v_fn, v_direct; END IF;

    SELECT count(*) INTO v_bad FROM essentials.office_holders_as_of(d) h
      JOIN essentials.office_terms ot ON ot.office_id = h.office_id AND ot.politician_id IS NOT DISTINCT FROM h.politician_id
                                     AND ot.term_start IS NOT DISTINCT FROM h.term_start AND ot.term_end IS NOT DISTINCT FROM h.term_end
     WHERE ot.source LIKE '%| unverified %';
    IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % -- % marked terms still answer', d, v_bad; END IF;
  END LOOP;

  -- today's answer equals the current-holder view's occupied seats (no marked term is open, so the guard
  -- cannot have dropped a current holder)
  SELECT count(*) INTO v_fn FROM essentials.office_holders_as_of(current_date) WHERE politician_id IS NOT NULL;
  SELECT count(*) INTO v_direct FROM essentials.office_terms ot
   WHERE ot.politician_id IS NOT NULL AND (ot.term_start IS NULL OR ot.term_start <= current_date)
     AND (ot.term_end IS NULL OR ot.term_end >= current_date);
  IF v_fn <> v_direct THEN RAISE EXCEPTION 'POST: today % holders via function vs % in office_terms', v_fn, v_direct; END IF;

  SELECT count(*) INTO v_bad FROM _grants g
   WHERE g.can_exec <> has_function_privilege(g.rolname, 'essentials.office_holders_as_of(date)', 'EXECUTE');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % roles changed EXECUTE on the function', v_bad; END IF;
END $$;

COMMIT;
