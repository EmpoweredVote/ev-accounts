-- 1702_occupancy_evidence_view.sql
--
-- Make "is this an evidenced OFFICEHOLDER, or a discovered CANDIDATE?" a one-line question.
--
-- Why. essentials.office_current_holder returns 83,291 rows, but only ~5,476 rest on anything
-- more than a placeholder. The other 77,002 are open-ended, start_precision='unknown' terms
-- written by the ADR 0002 phase-2 backfill (migration 1459), sitting on offices with no
-- district, no chamber and no city. The backfill did the honest thing — CLAUDE.md asks for
-- exactly that shape when a start date is genuinely unknown — but the resulting view cannot
-- tell a sitting official from someone we discovered in a campaign-finance file.
--
-- These are NOT defects and must never be deleted. They are real people seeded from candidate
-- committee filings (backend/scripts/discover-indiana-candidates.ts and the CalAccess
-- equivalent), whose placeholder offices the backfill then turned into open tenures.
--
-- The cost of not having this: the 2026-08-11 headshot backlog excluded the CalAccess pool by
-- SOURCE STRING, catching most of California and none of Indiana. 957 of its 2,344 rows (41%)
-- are candidates — 674 of Indiana's 810, plus 277 Californians the name-based rule missed.
--
-- THE DISCRIMINATOR IS STRUCTURAL, NOT PROVENANCE. "Has a candidate committee" does NOT mean
-- "is not an officeholder" — every incumbent seeking re-election has one. Lindsey Graham, Bill
-- Keating, Nanette Diaz Barragan, David Brock Smith and James Talarico all have committees and
-- are all genuinely seated; an earlier draft of this view flagged all five, and the gate below
-- caught it. What actually separates the classes is the OFFICE: a real seat carries geography
-- (a district, a chamber, or a city), a discovery placeholder carries none. Provenance is kept
-- as an informational column, never as the test.
--
-- Independent confirmation that the flag names a real class: all 77,002 rows it flags ALSO have
-- a candidate committee, and 0 do not. Two unrelated signals agreeing on every row.
--
-- GRAIN: one row per (politician, currently-held office). Someone holding two offices appears
-- twice; someone holding none appears once with a NULL office_id. politician_id is NOT unique.
--
-- Additive and non-destructive: creates a view, changes no data and no existing object.

BEGIN;

CREATE OR REPLACE VIEW essentials.politician_occupancy_evidence AS
SELECT
  p.id                                        AS politician_id,
  p.full_name,
  p.source                                    AS politician_source,

  -- informational only — see the header; this is NOT the discriminator
  EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
          WHERE ps.essentials_politician_id = p.id
            AND ps.source_type = 'candidate_committee')  AS has_candidate_committee,
  EXISTS (SELECT 1 FROM essentials.race_candidates rc
          WHERE rc.politician_id = p.id)                 AS in_race_candidates,

  (och.politician_id IS NOT NULL)             AS is_current_holder,
  och.office_id,
  o.title                                     AS office_title,
  (o.district_id IS NOT NULL)                 AS office_has_district,
  (o.chamber_id  IS NOT NULL)                 AS office_has_chamber,
  (nullif(btrim(coalesce(o.representing_city, '')), '') IS NOT NULL) AS office_has_city,
  och.term_start,
  ot.start_precision,
  ot.source                                   AS term_source,

  CASE
    WHEN och.politician_id IS NULL THEN 'not_seated'
    WHEN o.district_id IS NULL AND o.chamber_id IS NULL
     AND nullif(btrim(coalesce(o.representing_city, '')), '') IS NULL
     AND (och.term_start IS NULL OR coalesce(ot.start_precision, '') = 'unknown')
         THEN 'placeholder_office'
    WHEN och.term_start IS NULL OR coalesce(ot.start_precision, '') = 'unknown'
         THEN 'undated_term'
    ELSE 'dated_term'
  END                                         AS occupancy_evidence,

  -- The one-line answer. TRUE = reads as a current officeholder, but the only thing behind it
  -- is an undated backfill term on an office with no geography at all. Exclude these before
  -- building ANY worklist of sitting officials.
  ( och.politician_id IS NOT NULL
    AND o.district_id IS NULL
    AND o.chamber_id  IS NULL
    AND nullif(btrim(coalesce(o.representing_city, '')), '') IS NULL
    AND (och.term_start IS NULL OR coalesce(ot.start_precision, '') = 'unknown')
  )                                           AS is_placeholder_occupancy

FROM essentials.politicians p
LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
LEFT JOIN essentials.offices o                 ON o.id  = och.office_id
LEFT JOIN LATERAL (
  -- the term backing THIS holder row; office_terms' exclusion constraint makes it at most one
  SELECT t.start_precision, t.source
  FROM essentials.office_terms t
  WHERE t.politician_id = och.politician_id
    AND t.office_id     = och.office_id
    AND (t.term_end   IS NULL OR t.term_end   >= current_date)
    AND (t.term_start IS NULL OR t.term_start <= current_date)
  ORDER BY t.term_start DESC NULLS LAST
  LIMIT 1
) ot ON och.politician_id IS NOT NULL;

COMMENT ON VIEW essentials.politician_occupancy_evidence IS
  'Separates evidenced officeholders from discovered candidates on placeholder offices. '
  'Filter is_placeholder_occupancy = false before building any worklist of sitting officials. '
  'has_candidate_committee is informational only - incumbents have committees too. '
  'One row per (politician, currently-held office); politician_id is not unique.';

GRANT SELECT ON essentials.politician_occupancy_evidence TO ev_api;

-- Post-verify. Named people, not just counts: these five all hold real seats AND have
-- candidate committees, and are precisely the rows an earlier draft got wrong.
DO $$
DECLARE n_flag int; n_ev int; n_pool int; n_pool_flag int; bad text;
BEGIN
  SELECT count(*) INTO n_flag FROM essentials.politician_occupancy_evidence
   WHERE is_placeholder_occupancy;
  SELECT count(*) INTO n_ev FROM essentials.politician_occupancy_evidence
   WHERE is_current_holder AND NOT is_placeholder_occupancy;
  IF n_flag = 0 OR n_ev = 0 THEN
    RAISE EXCEPTION 'view does not discriminate: % flagged, % evidenced', n_flag, n_ev;
  END IF;

  -- every discovered Indiana candidate must be caught
  SELECT count(*) INTO n_pool FROM essentials.politicians WHERE source = 'indiana_discovery';
  SELECT count(DISTINCT e.politician_id) INTO n_pool_flag
    FROM essentials.politician_occupancy_evidence e
    JOIN essentials.politicians p ON p.id = e.politician_id
   WHERE p.source = 'indiana_discovery' AND e.is_placeholder_occupancy;
  IF n_pool_flag <> n_pool THEN
    RAISE EXCEPTION 'expected all % indiana_discovery people flagged, got %', n_pool, n_pool_flag;
  END IF;

  -- and no genuinely seated official may be
  SELECT string_agg(x.full_name, ', ') INTO bad
    FROM (SELECT DISTINCT e.full_name
          FROM essentials.politician_occupancy_evidence e
          WHERE e.is_placeholder_occupancy
            AND e.full_name IN ('Lindsey Graham', 'Bill Keating', 'Nanette Diaz Baragán',
                                'David Brock Smith', 'James Talarico')) x;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'seated officeholder(s) wrongly flagged as placeholder: %', bad;
  END IF;

  RAISE NOTICE 'ok: % placeholder occupancies, % evidenced officeholders', n_flag, n_ev;
END $$;

COMMIT;
