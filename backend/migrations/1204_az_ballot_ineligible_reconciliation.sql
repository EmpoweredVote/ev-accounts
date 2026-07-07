-- 1204_az_ballot_ineligible_reconciliation.sql
-- Phase 161-11 (gate/reconciliation): 5 AZ candidates seeded 'active' by migration 1188
--   (161-02) were subsequently discovered, via live Ballotpedia checks during 161-03's
--   stance-research pass, to be withdrawn/disqualified from the July 21, 2026 primary
--   BEFORE this general-election data was ever surfaced to users. They have no stance
--   rows (honest-skip: ineligible, not an evidence gap). This migration sets their
--   race_candidates.candidate_status to 'withdrawn' (the project's existing inactive
--   value -- see essentials.race_candidates.candidate_status distinct values: active/
--   filed/withdrawn) so they no longer surface as active candidates on /elections.
--   Politician rows are NOT deleted (audit trail preserved; matches 161-ROSTER-
--   RECONCILIATION-QUEUE.md's explicit instruction).
--
--   Source: 161-ROSTER-RECONCILIATION-QUEUE.md + 161-03-SUMMARY.md "Ballot-ineligibility
--   discoveries" table.
--
-- | external_id | name                | district | status found  |
-- |-------------|---------------------|----------|----------------|
-- | -40108      | Christopher Ajluni  | AZ-1     | Withdrawn      |
-- | -40201      | Eric Descheenie     | AZ-2     | Withdrawn      |
-- | -40402      | Jerone Davison      | AZ-4     | Disqualified   |
-- | -40503      | Blake Bracht        | AZ-5     | Withdrawn      |
-- | -40602      | Iman Bah            | AZ-6     | Disqualified   |
--
-- Idempotent: guarded by candidate_status <> 'withdrawn' so a re-run is a 0-row no-op.
BEGIN;

UPDATE essentials.race_candidates rc
SET candidate_status = 'withdrawn'
FROM essentials.politicians p
WHERE rc.politician_id = p.id
  AND p.external_id IN (-40108, -40201, -40402, -40503, -40602)
  AND rc.candidate_status <> 'withdrawn';

COMMIT;
