-- ============================================================================
-- Migration 1336: Fix 4 wrong-party VA House of Delegates records
-- ============================================================================
-- Purpose: The 2026-07-12 VA stance retry wave found 4 delegates whose
--   politicians.party is wrong. Each verified against >=2 independent sources
--   (Wikipedia district pages, VPAP, the member's own campaign site):
--
--   1. Will P. Davis (HD-39)            Democrat  -> Republican
--      wikipedia.org/wiki/Virginia's_39th_House_of_Delegates_district; own
--      platform (davisfordelegate.com) is GOP (vouchers, photo ID, pro-life).
--   2. Hillary Pugh Kent (HD-67)        Democrat  -> Republican
--      vpap.org/legislators/288244-hillary-pugh-kent/; own site
--      hillarypughkentva.com self-describes "Wife, Mother, Businesswoman &
--      Republican".
--   3. Charles H. Schmidt, Jr. (HD-77)  Republican -> Democrat
--      wikipedia.org/wiki/Charlie_Schmidt_(politician); own site charlie4va.com
--      self-describes progressive Democrat; ACLU attorney.
--   4. Andrew Rice (HD-98)              Democrat  -> Republican
--      wikipedia.org/wiki/Virginia's_98th_House_of_Delegates_district; won the
--      2026-03-17 special election (R) after Del. Barry Knight died 2026-02-19.
--
-- Scope guard: politician_id resolved via the VA STATE_LOWER district join,
--   never by name alone. Idempotent: WHERE party <> target.
-- ============================================================================

BEGIN;

WITH va_delegates AS (
  SELECT p.id, p.full_name, d.label
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_LOWER'
    AND lower(d.state) = 'va'
    AND o.title NOT ILIKE 'Candidate for%'
)
UPDATE essentials.politicians p
SET party = fix.new_party
FROM va_delegates v
JOIN (VALUES
  ('Will P. Davis',            'State House District 39', 'Republican'),
  ('Hillary Pugh Kent',        'State House District 67', 'Republican'),
  ('Charles H. Schmidt, Jr.',  'State House District 77', 'Democrat'),
  ('Andrew Rice',              'State House District 98', 'Republican')
) AS fix(full_name, district_label, new_party)
  ON fix.full_name = v.full_name AND fix.district_label = v.label
WHERE p.id = v.id
  AND p.party IS DISTINCT FROM fix.new_party;

COMMIT;

-- ============================================================================
-- Verification (expect the 4 rows with corrected parties):
-- SELECT p.full_name, p.party, d.label
-- FROM essentials.politicians p
-- JOIN essentials.offices o ON o.politician_id = p.id
-- JOIN essentials.districts d ON d.id = o.district_id
-- WHERE d.district_type='STATE_LOWER' AND lower(d.state)='va'
--   AND d.label IN ('State House District 39','State House District 67',
--                   'State House District 77','State House District 98');
-- ============================================================================
