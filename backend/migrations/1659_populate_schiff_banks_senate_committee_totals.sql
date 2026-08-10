-- Migration 1659: populate total_raised for Schiff and Banks from their SENATE committees
--
-- ============================================================================
-- CORRECTING THE DIAGNOSIS IN MIGRATION 1657
-- ============================================================================
-- 1657 removed the `total_raised` key from Adam Schiff and Jim Banks, and its header
-- blamed "a CROSSWALK defect ... politician_sources still points at their old HOUSE
-- candidate id". THAT WAS WRONG. The crosswalk is correct and well curated:
--
--   Schiff  S4CA00555 / fec_senate / confirmed        H0CA27085 / fec_house / not_applicable
--   Banks   S4IN00196 / fec_senate / confirmed        H6IN03229 / fec_house / not_applicable
--
-- Both superseded House rows even carry the note "dedup 2026-07-08: superseded by
-- canonical FEC source". lookupFecIdViaSources() in run-fec-finance-summary.ts filters on
-- `research_status = 'confirmed'` and orders by created_at DESC, so the loader picks the
-- Senate id correctly.
--
-- The defect was in the ad-hoc ANALYSIS query used to build 1657's worklist, which
-- selected `WHERE source_system LIKE 'fec%' LIMIT 1` with no research_status filter and no
-- ORDER BY. It grabbed the superseded House row, fetched the dormant House committee, got
-- a true $0, and that $0 was mistaken for evidence of a bad crosswalk.
--
-- 🔑 An ad-hoc query that omits a filter the production code applies will manufacture
-- defects that do not exist. Mirror the real lookup, or you are auditing your own query.
--
-- Blast radius checked: only 5 cycle-2026 rows have more than one FEC source row
-- (Schiff, Banks, Andre Carson, Glenn Ivey, Keith Self). Carson/Ivey/Self already had
-- NONZERO totals so they were never in 1657's 70-row worklist and were not written to.
-- No incorrect value was stored by 1657 — the only casualties were these two cleared keys.
--
-- ============================================================================
-- WHAT THIS WRITES
-- ============================================================================
-- FEC /candidates/totals/ with election_full=false, cycle 2026, fetched 2026-08-09
-- against the CONFIRMED Senate ids:
--   Schiff  S4CA00555  receipts  8,832,154.09
--   Banks   S4IN00196  receipts  2,291,158.59
--
-- Matched on research_status='confirmed' this time, and guarded on the key being ABSENT so
-- it cannot overwrite a later correction and is safe to replay.
--
-- Still legitimately unknown after this (unchanged from 1657): Wesley Hunt (H0TX07170),
-- Seth Moulton (H4MA06090) and John Sununu (S0NH00201). All three have a single
-- `confirmed` source row, so their ids are right — FEC simply has no 2026 totals row for
-- them even with election_full=false. Key stays absent; absent means unknown, not $0.

BEGIN;

WITH senate_totals(fec_id, receipts) AS (
  VALUES
    ('S4CA00555', 8832154.09),
    ('S4IN00196', 2291158.59)
)
UPDATE essentials.politicians p
SET finance_summary = jsonb_set(p.finance_summary, '{total_raised}', to_jsonb(t.receipts))
FROM transparent_motivations.politician_sources ps, senate_totals t
WHERE ps.essentials_politician_id = p.id
  AND ps.source_system LIKE 'fec%'
  AND ps.research_status = 'confirmed'
  AND ps.external_id = t.fec_id
  AND p.finance_summary->>'cycle' = '2026'
  AND NOT (p.finance_summary ? 'total_raised');

COMMIT;
