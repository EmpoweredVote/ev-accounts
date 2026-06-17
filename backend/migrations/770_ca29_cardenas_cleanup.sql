-- Migration 770: CA-29 cleanup — remove stale Tony Cárdenas office
--
-- CA-29 (tiger_geoid 0629) had TWO Representative offices: Luz Maria Rivas (sitting
-- rep, active, 17 stances) and Tony Cárdenas (left Congress 2024; office already
-- is_vacant=true, 0 stances, no other offices). The duplicate made CA-29 resolve to
-- two reps. Pre-existing data from the v2.2 CA seed — surfaced during v2.15 verify.
--
-- Fix: delete the stale Cárdenas office; mark Cárdenas as a former (inactive,
-- non-incumbent) member (kept as a record, not hard-deleted — FK-safe, reversible).
-- Idempotent: guarded by id + politician_id.

BEGIN;

DELETE FROM essentials.offices
WHERE id = 'ebee1293-f308-4d59-854b-e69d58cbd0f1'
  AND politician_id = 'ee52c1ec-85b8-486e-83ea-4fe337497486';

UPDATE essentials.politicians
SET is_active = false, is_incumbent = false
WHERE id = 'ee52c1ec-85b8-486e-83ea-4fe337497486';

COMMIT;
