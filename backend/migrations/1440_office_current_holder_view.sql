-- 1440_office_current_holder_view.sql
-- ADR 0002 phase 3 support: one place that answers "who holds this office right now".
-- Idempotent. Requires 1437.
--
-- WHY A SECOND VIEW. essentials.current_office_holders lists only offices that HAVE a current
--   term. Read paths additionally need the dual-read fallback to offices.politician_id for the
--   857 offices with no term row yet, and they need it in BOTH directions:
--     office -> politician   ("who holds this seat", e.g. a body roster)
--     politician -> office   ("what office does this person hold", e.g. a politician detail page)
--   Writing COALESCE(coh.politician_id, o.politician_id) inline at every call site works for the
--   first direction but is awkward for the second, and it scatters the transition rule across
--   ~31 join sites in 13 files. This view states the rule ONCE.
--
-- PHASE 5 BECOMES A ONE-LINE CHANGE. When offices.politician_id is finally dropped, only this
--   view's definition changes — every consumer keeps working. That is the whole reason for it.
--   The same edit also closes the documented gap where a term ending with no successor falls back
--   to the expired holder.
--
-- Exactly one row per office (including offices with no holder, where politician_id is NULL), so
--   joining it can never fan a result set out. Guaranteed by office_terms' exclusion constraint,
--   which permits at most one current term per office.
BEGIN;

CREATE OR REPLACE VIEW essentials.office_current_holder AS
SELECT o.id                                          AS office_id,
       COALESCE(coh.politician_id, o.politician_id)  AS politician_id,
       coh.term_start,
       coh.term_end,
       coh.how_started,
       (coh.office_id IS NOT NULL)                   AS from_office_terms
  FROM essentials.offices o
  LEFT JOIN essentials.current_office_holders coh ON coh.office_id = o.id;

COMMENT ON VIEW essentials.office_current_holder IS
  'Current occupant of every office, one row per office (politician_id NULL when unheld). '
  'Resolves from essentials.office_terms and falls back to essentials.offices.politician_id for '
  'offices that have no term row yet (ADR 0002 phase 3 dual-read). Read paths should join THIS '
  'rather than offices.politician_id, in either direction. from_office_terms shows which source '
  'answered. When offices.politician_id is dropped in phase 5, only this definition changes.';

-- ── Post-verify gate ──
DO $$
DECLARE n_offices int; n_rows int; n_divergent int; n_fanout int; n_from_terms int;
BEGIN
  SELECT count(*) INTO n_offices FROM essentials.offices;
  SELECT count(*) INTO n_rows    FROM essentials.office_current_holder;
  IF n_rows <> n_offices THEN
    RAISE EXCEPTION 'view must return exactly one row per office: % rows vs % offices', n_rows, n_offices;
  END IF;

  -- no office may appear twice (would fan out every consumer)
  SELECT count(*) INTO n_fanout FROM (
    SELECT office_id FROM essentials.office_current_holder GROUP BY office_id HAVING count(*) > 1
  ) f;
  IF n_fanout <> 0 THEN RAISE EXCEPTION '% offices appear more than once in the view', n_fanout; END IF;

  -- today the view must agree with offices.politician_id everywhere: office_terms was backfilled
  -- from that column, and the only future-dated term (Taylor) is not current yet. If this ever
  -- fails it means a hand-off has taken effect, which is exactly when the column stops being
  -- authoritative — expected from 2026-08-01.
  SELECT count(*) INTO n_divergent
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
   WHERE och.politician_id IS DISTINCT FROM o.politician_id;
  IF n_divergent <> 0 THEN
    RAISE NOTICE 'view diverges from offices.politician_id on % offices — expected once a dated hand-off is live', n_divergent;
  END IF;

  SELECT count(*) INTO n_from_terms FROM essentials.office_current_holder WHERE from_office_terms;
  RAISE NOTICE 'office_current_holder verify PASSED: % rows (1 per office), % resolved from office_terms, % via fallback.',
    n_rows, n_from_terms, n_rows - n_from_terms;
END $$;

COMMIT;
