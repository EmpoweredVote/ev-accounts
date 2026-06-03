-- Normalize party strings: ~495 'Democrat' rows → 'Democratic'
-- 'Democratic' is the canonical form (official party name: Democratic Party, not Democrat Party)
-- Affected: essentials.politicians — no FK dependencies, no PostgREST impact
-- Verified: no hardcoded 'Democrat' string comparisons in backend/src TS files

BEGIN;

UPDATE essentials.politicians
SET party = 'Democratic'
WHERE party = 'Democrat';

-- Verify: should return 0 rows after normalization
-- SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat'; -- expected: 0 after migration

COMMIT;
