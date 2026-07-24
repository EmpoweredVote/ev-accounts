-- =============================================================================
-- Migration 1410: Phase 220 post-apply reconcile (2 targeted single-row fixes)
-- (Phase 220 Plan 06 — Contact Data Backfill, Wave 3 verification close-out)
--
-- Two idempotent corrections surfaced during Wave-3 verification of migs
-- 1405-1408. NOT a mass re-write (D-03) — only the two named rows below.
--
--   FIX 1 (email reconcile): Fairview Seat 2. RESEARCH sourced "Joe Boggs" but
--     the DB row is "Joe W. Boggs" (same person, middle initial) — mig 1407's
--     exact full_name guard correctly no-op'd rather than risk a wrong-person
--     attach, leaving his email NULL. Seed the sourced address here, matched by
--     politician_id so there is zero ambiguity.
--       Fairview (4825224) Seat 2 → JBoggs@FairviewTexas.org
--       (source: fairviewtexas.org/government/mayor-town-council/)
--
--   FIX 2 (valid_to outlier, COLLIN-CONTACT-03 / D-03): Allen Mayor Chris
--     Schulmeister had valid_to = NULL / precision = NULL (elected 2026-05-03).
--     RESEARCH spot-check shows a 2026-2029 term. Set the derived term-end.
--       Allen (4801924) Mayor → valid_to 2029-05-01, term_date_precision 'month'
--
-- Idempotent: FIX 1 only writes where the email is absent; FIX 2 only where
-- valid_to IS NULL. Re-applying is net-zero.
-- =============================================================================

BEGIN;

-- FIX 1 — Fairview Seat 2 (Joe W. Boggs) email, matched by politician_id.
UPDATE essentials.politicians
   SET email_addresses = ARRAY['JBoggs@FairviewTexas.org']
 WHERE id = '1a726799-8eb1-4479-b46a-83aacb0109e8'
   AND (email_addresses IS NULL OR array_length(email_addresses,1) IS NULL);

-- FIX 2 — Allen Mayor (Chris Schulmeister) valid_to derived term-end.
UPDATE essentials.politicians p
   SET valid_to = '2029-05-01', term_date_precision = 'month'
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
 WHERE p.id = o.politician_id
   AND g.geo_id = '4801924' AND o.title = 'Mayor'
   AND p.full_name = 'Chris Schulmeister'
   AND p.valid_to IS NULL;

COMMIT;
