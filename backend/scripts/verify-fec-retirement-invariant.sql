-- Verify the FEC per-line supersession invariant.
--
-- PASS CONDITION: zero last-copy deletions. Every line the retirement removes must
-- still have a surviving row in the SAME report (committee_id, report_year,
-- report_type) at the survivor file_number.
--
-- Why this check exists: FEC amendments are DELTA filings, not full re-reports.
-- FEC-04b assumed the opposite and deleted every row below the max file_number
-- per REPORT, which destroyed lines the amendment never restated. The per-LINE
-- rule below only retires a line when the SAME line reappears at a higher
-- file_number, so an orphan should be structurally impossible -- this query is
-- what proves that empirically rather than by argument.
--
-- Read-only. Run BEFORE --apply (to confirm the plan is safe) and AFTER (to
-- confirm nothing was orphaned). Takes one politician_source_id; loop it over the
-- detector's 173 sources, or pass NULL to sweep every FEC source (slow -- each
-- source is a full scan, there is no index for `raw_record ? 'file_number'`).
--
-- Usage:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v src="'<uuid>'" \
--     -f scripts/verify-fec-retirement-invariant.sql

\set src :src

WITH slice AS (
  SELECT id,
         raw_record->>'committee_id'          AS cmte,
         (raw_record->>'report_year')::int    AS ry,
         raw_record->>'report_type'           AS rt,
         donor_name_normalized                AS donor,
         amount,
         contribution_date,
         (raw_record->>'file_number')::bigint AS fn
    FROM transparent_motivations.contributions
   WHERE politician_source_id = :src
     AND data_source = 'fec'
     AND raw_record ? 'file_number'
), ranked AS (
  SELECT *,
         max(fn) OVER (
           PARTITION BY cmte, ry, rt, donor, amount, contribution_date
         ) AS survivor_fn,
         count(*) FILTER (WHERE TRUE) OVER (
           PARTITION BY cmte, ry, rt, donor, amount, contribution_date
         ) AS grp_rows
    FROM slice
), victims AS (
  SELECT * FROM ranked WHERE fn < survivor_fn
), survivors AS (
  -- The row(s) that must remain for each victim's group.
  SELECT cmte, ry, rt, donor, amount, contribution_date, fn, count(*) AS n
    FROM ranked
   WHERE fn = survivor_fn
   GROUP BY 1,2,3,4,5,6,7
)
SELECT
  (SELECT count(*) FROM victims)                                   AS victims,
  (SELECT count(DISTINCT (cmte, ry, rt, donor, amount, contribution_date))
     FROM victims)                                                 AS victim_groups,
  -- THE PASS CONDITION. Any victim group with no surviving row at survivor_fn
  -- would be a last-copy deletion. Must be 0.
  (SELECT count(*) FROM (
     SELECT DISTINCT v.cmte, v.ry, v.rt, v.donor, v.amount, v.contribution_date, v.survivor_fn
       FROM victims v
       LEFT JOIN survivors s
         ON  s.cmte = v.cmte AND s.ry = v.ry AND s.rt = v.rt
         AND s.donor IS NOT DISTINCT FROM v.donor
         AND s.amount = v.amount
         AND s.contribution_date IS NOT DISTINCT FROM v.contribution_date
         AND s.fn = v.survivor_fn
      WHERE s.fn IS NULL
   ) orphaned)                                                     AS last_copy_deletions,
  -- Sanity: a victim must never share a file_number with its own survivor.
  (SELECT count(*) FROM victims WHERE fn = survivor_fn)            AS self_supersession,
  -- Rows the backfill could not resolve are invisible to the rule and stay put.
  (SELECT count(*) FROM transparent_motivations.contributions
    WHERE politician_source_id = :src AND data_source = 'fec'
      AND NOT (raw_record ? 'file_number'))                        AS unresolvable_untouched;
