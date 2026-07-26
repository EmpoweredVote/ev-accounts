-- 1462_office_terms_only_resolution.sql
-- ADR 0002 phase 5, part 1 of 2: make essentials.office_terms the ONLY source of occupancy.
-- Idempotent. Requires 1458 + 1459 + 1461.
--
-- !! DELIBERATELY DOES NOT DROP essentials.offices.politician_id. That is 1463, and it must not
--    run until the new backend is deployed, because the currently-deployed code still reads the
--    column directly in 13 places. THIS migration is safe to apply immediately and in either
--    order relative to that deploy:
--      - the column still exists, so old code keeps working;
--      - the view's output columns and types are unchanged, so new code keeps working.
--    It is the reversible half. 1463 is the irreversible half.
--
-- WHAT CHANGES: office_current_holder stops falling back to offices.politician_id.
--
--   Before: COALESCE(coh.politician_id, o.politician_id)
--   After:  coh.politician_id
--
-- WHY THIS CHANGES NO ANSWERS TODAY -- measured against prod before writing, not assumed:
--   * 82,336 occupied offices, 82,337 office_terms rows (82,336 current + 1 future).
--   * 0 occupied offices have no current term. So the fallback has nothing left to answer.
--   * 0 offices where the view diverges from the column.
--   * 0 rows where the view resolved via the fallback with a non-null result.
--   * The (politician_id, office_id) pair set is IDENTICAL across the two join forms:
--     82,336 pairs each way, 0 lost, 0 gained.
--   The fallback is now dead weight, which is exactly the precondition phase 5 was waiting for.
--
-- TWO BEHAVIOURS DO CHANGE, both intended:
--   1. A FUTURE-DATED term now takes effect on its own date. Rebecca Bradley holds the WI Supreme
--      Court seat per the column; office_terms hands it to Chris Taylor on 2026-08-01. After this
--      migration that hand-off happens because the calendar advanced -- no cron, no code change.
--      This is the entire reason ADR 0002 exists.
--   2. A term that has ENDED with no successor now reads as VACANT rather than reporting the
--      expired holder. That was the documented gap in the dual-read fallback. 0 offices are in
--      that state today. Consequence to know: closing a term without seating a successor now
--      removes that person from coverage/stance/campaign-finance lists rather than leaving them
--      in place. Correct, but it means "close the term" is a real edit with visible effect.
--
-- from_office_terms is KEPT even though it is now always true when politician_id is non-null:
--   removing a column requires DROP VIEW, which would cascade to dependents. Nothing consumes it
--   (verified across backend/src), so it stays as a harmless, honest provenance flag.
BEGIN;

CREATE OR REPLACE VIEW essentials.office_current_holder AS
SELECT o.id             AS office_id,
       coh.politician_id,
       coh.term_start,
       coh.term_end,
       coh.how_started,
       (coh.office_id IS NOT NULL) AS from_office_terms
  FROM essentials.offices o
  LEFT JOIN essentials.current_office_holders coh ON coh.office_id = o.id;

COMMENT ON VIEW essentials.office_current_holder IS
  'Current occupant of every office, one row per office (politician_id NULL when unheld). '
  'Resolved solely from essentials.office_terms at query time (ADR 0002 phase 5 removed the '
  'dual-read fallback to essentials.offices.politician_id, which 1463 drops). Read paths should '
  'join THIS in either direction rather than touching occupancy on offices. A future-dated term '
  'takes effect on its own date; a term that ended with no successor reads as vacant.';

-- ── The one RPC that resolved occupancy itself ──
-- SECURITY DEFINER with SET search_path TO '', so every reference must stay schema-qualified.
-- CREATE OR REPLACE preserves the owner and existing GRANTs.
CREATE OR REPLACE FUNCTION public.admin_list_politicians()
 RETURNS TABLE(id uuid, first_name text, last_name text, preferred_name text, full_name text,
               office_title text, photo_origin_url text, is_active boolean, is_candidate boolean,
               is_vacant boolean, representing_city text, representing_state text,
               district_type text, district_label text, district_id text, chamber_name text,
               chamber_name_formal text, government_name text,
               created_at timestamp with time zone, answer_count bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT * FROM (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.first_name,
      p.last_name,
      p.preferred_name,
      p.full_name,
      o.title                     AS office_title,
      p.photo_origin_url,
      p.is_active,
      false::boolean              AS is_candidate,
      p.is_vacant,
      o.representing_city,
      o.representing_state,
      NULL::text                  AS district_type,
      NULL::text                  AS district_label,
      NULL::text                  AS district_id,
      NULL::text                  AS chamber_name,
      NULL::text                  AS chamber_name_formal,
      NULL::text                  AS government_name,
      NULL::timestamptz           AS created_at,
      (
        SELECT COUNT(*)
        FROM inform.politician_answers pa
        WHERE pa.politician_id = p.id
      )                           AS answer_count
    FROM essentials.politicians p
    -- ADR 0002 phase 5: occupancy via office_current_holder, not offices.politician_id.
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    WHERE p.is_active = true
    ORDER BY p.id, o.id
  ) sub
  ORDER BY
    COALESCE(NULLIF(TRIM(sub.last_name), ''), sub.full_name),
    sub.first_name
$function$;

-- ── Deprecate politicians.valid_from / valid_to (the other half of phase 5) ──
-- Not dropped: 701 and 699 rows are populated and they are `text`, so whatever is in them is
-- salvage-able history we should not destroy in the same breath as the column drop. Marking them
-- deprecated stops new code adopting them; migrating the salvageable values into office_terms is
-- a separate data task.
COMMENT ON COLUMN essentials.politicians.valid_from IS
  'DEPRECATED (ADR 0002). Dates belong to a TENURE, not a person -- several politicians hold two '
  'offices with different windows, which this cannot express. Use essentials.office_terms. '
  'Do not read in new code; retained only because 701 rows hold un-migrated history.';
COMMENT ON COLUMN essentials.politicians.valid_to IS
  'DEPRECATED (ADR 0002). See valid_from. Use essentials.office_terms.term_end instead.';

-- ── Post-verify gate ──
DO $$
DECLARE
  n_offices int; n_rows int; n_fanout int; n_held int;
  n_fallback_nonnull int; n_future int; v_def text;
BEGIN
  SELECT count(*) INTO n_offices FROM essentials.offices;
  SELECT count(*) INTO n_rows    FROM essentials.office_current_holder;
  IF n_rows <> n_offices THEN
    RAISE EXCEPTION 'view must return exactly one row per office: % rows vs % offices', n_rows, n_offices;
  END IF;

  SELECT count(*) INTO n_fanout FROM (
    SELECT office_id FROM essentials.office_current_holder GROUP BY office_id HAVING count(*) > 1
  ) f;
  IF n_fanout <> 0 THEN RAISE EXCEPTION '% offices appear more than once in the view', n_fanout; END IF;

  -- the fallback must be GONE from the definition, not merely unused
  SELECT pg_get_viewdef('essentials.office_current_holder'::regclass, true) INTO v_def;
  IF v_def ~* 'o\.politician_id|COALESCE' THEN
    RAISE EXCEPTION 'view still references offices.politician_id / COALESCE -- fallback not removed';
  END IF;

  -- and no row may now resolve via a fallback that no longer exists
  SELECT count(*) INTO n_fallback_nonnull
    FROM essentials.office_current_holder WHERE NOT from_office_terms AND politician_id IS NOT NULL;
  IF n_fallback_nonnull <> 0 THEN
    RAISE EXCEPTION '% rows claim a holder without a term row -- impossible, view is wrong', n_fallback_nonnull;
  END IF;

  -- every occupied office must still resolve: this is the "changed no answers" assertion
  SELECT count(*) INTO n_held FROM essentials.office_current_holder WHERE politician_id IS NOT NULL;
  IF n_held <> (SELECT count(*) FROM essentials.offices WHERE politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'view resolves % holders but offices.politician_id claims % -- answers changed',
      n_held, (SELECT count(*) FROM essentials.offices WHERE politician_id IS NOT NULL);
  END IF;

  IF to_regprocedure('public.admin_list_politicians()') IS NULL THEN
    RAISE EXCEPTION 'admin_list_politicians missing';
  END IF;
  IF (SELECT prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname='public' AND p.proname='admin_list_politicians') ~* 'o\.politician_id' THEN
    RAISE EXCEPTION 'admin_list_politicians still joins on offices.politician_id';
  END IF;

  SELECT count(*) INTO n_future FROM essentials.office_terms WHERE term_start > CURRENT_DATE;

  RAISE NOTICE 'phase 5 part 1 PASSED: % offices, % held, fallback removed, RPC migrated, % future term(s) now self-activating.',
    n_offices, n_held, n_future;
END $$;

COMMIT;
