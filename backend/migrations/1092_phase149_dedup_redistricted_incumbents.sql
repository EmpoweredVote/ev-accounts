-- Migration 1092 — Phase 149 corrective: resolve 2 duplicate records created by mig 1091
-- (USHC-02 integrity — the milestone's #1 trap: a sitting incumbent / existing figure must
--  REUSE its record, never get a new one. mig 1091's live name-check was defeated by an accent
--  + middle-initial, so two redistricting/cross-office candidates were seeded as NEW records.)
--
-- Case 1 — Linda Sánchez (CA-41 Democratic nominee): she is the SITTING CA-38 incumbent
--   "Linda T. Sanchez" (external_id -100037, 28 stances, CA-38 office) redistricted into CA-41
--   under Prop 50 (per 148-field-table CA-41 cited source). Reuse her existing record.
-- Case 2 — Hilda Solis (CA-38 Democratic nominee): she is the existing prominent LA figure
--   "Hilda L. Solis" (external_id 683398, 32 stances). Reuse her existing record.
--
-- Both reuse targets are stance-done (>=24) and already carry a politician_images row, so they
-- correctly drop out of the Phase 149 headshot + stance scope (new-candidate count 38 -> 36).
-- is_incumbent stays false for both: neither is the incumbent OF the seat they now contest
-- (CA-41 incumbent = Calvert, redistricted; CA-38 incumbent = Sanchez, redistricted out).
-- Erroneous duplicate records are RETIRED via is_active=false (never hard-DELETE — project rule,
-- mirrors the Ruiz CA-25 dedup in 1091). Idempotent: each UPDATE guards on the current dup pid.

BEGIN;

-- Case 1: re-point CA-41 (geo_id 0641) race_candidate to the real incumbent record
UPDATE essentials.race_candidates
   SET politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8'   -- Linda T. Sanchez (-100037)
 WHERE id = 'f823e02c-4834-4bfc-89d4-23389fe095f6'
   AND politician_id = '2ebe5440-8333-4ba4-9118-24afa298d52e';  -- dup "Linda Sánchez" (-6014101)

-- Case 2: re-point CA-38 (geo_id 0638) race_candidate to the existing Hilda L. Solis record
UPDATE essentials.race_candidates
   SET politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b'   -- Hilda L. Solis (683398)
 WHERE id = 'c285d0f3-8bfa-49af-be65-e12a03ab3c04'
   AND politician_id = 'c64ccabb-743d-48bc-9015-5b82e54cc045';  -- dup "Hilda Solis" (-6013801)

-- Retire the two erroneously-created duplicate records (never DELETE)
UPDATE essentials.politicians
   SET is_active = false
 WHERE id IN ('2ebe5440-8333-4ba4-9118-24afa298d52e',   -- dup Linda Sánchez (-6014101)
              'c64ccabb-743d-48bc-9015-5b82e54cc045')   -- dup Hilda Solis (-6013801)
   AND is_active = true;

COMMIT;
