-- Migration 223a: Fix OR STATE_EXEC district state/district_id columns
-- Applied: 2026-05-29
--
-- Fixes two defects introduced by migration 223:
--   CR-01 (BLOCKER): state='or' (lowercase) caused backend queries filtering
--     districts.state='OR' to silently exclude all 5 OR constitutional officers.
--     All other STATE_EXEC rows use uppercase 2-letter postal code.
--   WR-02 (WARNING): district_id='Oregon (Statewide)' should be empty string
--     to match the MA/ME/TX multi-position STATE_EXEC pattern.
--
-- Idempotent: WHERE clause scoped to the exact bad row (state='or', geo_id='41').

BEGIN;

UPDATE essentials.districts
SET
  state = 'OR',
  district_id = ''
WHERE district_type = 'STATE_EXEC'
  AND geo_id = '41'
  AND state = 'or';

COMMIT;
