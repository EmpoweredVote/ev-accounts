-- ============================================================================
-- Migration 1328: Seed Brett Ligon — TX Senate District 4 special-election winner
-- ============================================================================
-- Purpose: Fill the vacant TX SD-4 seat. Brett W. Ligon (R), former Montgomery
--   County District Attorney, won the 2026-05-02 special election 75%-25% over
--   Ron Angeletti (D) and assumed office 2026-05-19, succeeding Brandon
--   Creighton (resigned Nov 2025 to become Texas Tech University System
--   chancellor). Sources: senate.texas.gov/member.php?d=4,
--   en.wikipedia.org/wiki/Brett_Ligon.
--
-- The seat was vacant at the TX senate seed: a vacant office row exists
--   (ec839798-2084-49ec-bbe4-37512c3cf879, politician_id NULL, is_vacant=true)
--   and external_id -100404 was left unused in the TX senator band (-1004NN by
--   district). This migration creates the politician and attaches him to the
--   EXISTING office row (officeholder title 'Senator' is correct here — he is
--   the officeholder, not a candidate).
--
-- Idempotency: NOT EXISTS / null-guarded updates; re-runnable.
-- ============================================================================

BEGIN;

-- 1. Politician
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party,
   is_incumbent, is_active, is_appointed, is_vacant,
   photo_origin_url, appointment_date)
SELECT
  -100404, 'Brett Ligon', 'Brett', 'Ligon', 'Republican',
  true, true, false, false,
  'https://senate.texas.gov/member.php?d=4', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians WHERE external_id = -100404
);

-- 2. Attach him to the existing vacant SD-4 office row and clear the vacancy
UPDATE essentials.offices o
SET politician_id = p.id,
    is_vacant = false,
    vacant_since = NULL
FROM essentials.politicians p
WHERE o.id = 'ec839798-2084-49ec-bbe4-37512c3cf879'
  AND p.external_id = -100404
  AND o.politician_id IS NULL;

-- 3. Back-reference politician -> office
UPDATE essentials.politicians p
SET office_id = 'ec839798-2084-49ec-bbe4-37512c3cf879'
FROM essentials.offices o
WHERE p.external_id = -100404
  AND o.id = 'ec839798-2084-49ec-bbe4-37512c3cf879'
  AND o.politician_id = p.id
  AND p.office_id IS DISTINCT FROM o.id;

COMMIT;

-- ============================================================================
-- Verification (run after applying):
-- ============================================================================
-- Expect 1 row: Brett Ligon | Republican | Senator | TX Senate District 4 | not vacant
-- SELECT p.full_name, p.party, p.is_incumbent, o.title, o.is_vacant, d.label
-- FROM essentials.politicians p
-- JOIN essentials.offices o ON o.politician_id = p.id
-- JOIN essentials.districts d ON d.id = o.district_id
-- WHERE p.external_id = -100404;
--
-- TX senate incumbent count should now be 31:
-- SELECT COUNT(DISTINCT o.politician_id) FROM essentials.offices o
-- JOIN essentials.districts d ON d.id = o.district_id
-- JOIN essentials.politicians p ON p.id = o.politician_id
-- WHERE d.district_type = 'STATE_UPPER' AND d.state = 'TX' AND p.is_incumbent;
