-- =============================================================================
-- Link Monroe County 2026 Primary Candidates to Existing Politician Records
--
-- Matches race_candidates to politicians by last_name (with first_name prefix
-- disambiguation for collisions). Linked candidates get politician_id set and
-- is_incumbent = true, enabling CandidateProfile to show full politician data.
--
-- This script is IDEMPOTENT — only updates candidates where politician_id IS NULL.
-- Safe to re-run without side effects.
--
-- Usage: psql $DATABASE_URL -f scripts/link-monroe-candidates-to-politicians.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 0: Fix known name corrections
-- =============================================================================

-- Efrat Feferman → Efrat Rosser (married name change)
UPDATE essentials.politicians
SET last_name = 'Rosser', slug = 'efrat-rosser'
WHERE id = 'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd'
  AND last_name = 'Feferman';

-- =============================================================================
-- Step 1: Preview matches (SELECT only — no changes)
-- =============================================================================

SELECT
  rc.full_name AS candidate_name,
  p.first_name || ' ' || p.last_name AS politician_name,
  p.id AS politician_id,
  r.position_name,
  r.primary_party
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p
  ON lower(rc.last_name) = lower(p.last_name)
  AND lower(left(rc.first_name, 3)) = lower(left(p.first_name, 3))
WHERE e.name = '2026 Indiana Primary'
  AND e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND rc.politician_id IS NULL
ORDER BY rc.last_name;

-- =============================================================================
-- Step 2: UPDATE candidates with matched politician_id
-- =============================================================================

WITH matched AS (
  SELECT
    rc.id AS candidate_id,
    p.id AS politician_id
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.politicians p
    ON lower(rc.last_name) = lower(p.last_name)
    AND lower(left(rc.first_name, 3)) = lower(left(p.first_name, 3))
  WHERE e.name = '2026 Indiana Primary'
    AND e.election_date = '2026-05-05'
    AND e.state = 'IN'
    AND rc.politician_id IS NULL
)
UPDATE essentials.race_candidates
SET
  politician_id = matched.politician_id,
  is_incumbent = true,
  updated_at = now()
FROM matched
WHERE essentials.race_candidates.id = matched.candidate_id
  AND essentials.race_candidates.politician_id IS NULL;

-- =============================================================================
-- Step 3: Verification — show all candidates with link status
-- =============================================================================

SELECT
  rc.full_name,
  rc.is_incumbent,
  rc.politician_id,
  p.first_name || ' ' || p.last_name AS linked_politician,
  r.position_name
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
WHERE e.name = '2026 Indiana Primary'
  AND e.election_date = '2026-05-05'
  AND e.state = 'IN'
ORDER BY rc.politician_id IS NULL, rc.last_name;

COMMIT;
