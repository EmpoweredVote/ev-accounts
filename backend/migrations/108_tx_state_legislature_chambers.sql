-- Migration 108: TX State Legislature chambers
--
-- Creates two new chambers under the State of Texas government for Phase 21:
--   - Texas State Senate              (parent of the 31 STATE_UPPER offices in Plan 21-03)
--   - Texas House of Representatives  (parent of the 150 STATE_LOWER offices in Plan 21-04)
--
-- The State of Texas government_id (8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9) was
-- created in migration 087, and the executive-branch chambers were created in
-- migration 103. The two legislature chambers were deferred to Phase 21.
--
-- name_formal is set to the same value as name (NOT empty string). Migration
-- 107 documents that empty name_formal breaks profile page rendering, so we
-- avoid that defect here.
--
-- DO NOT include `slug` in the column list — it is GENERATED ALWAYS (migration
-- 060). Including it raises "cannot insert a non-DEFAULT value into column slug".
--
-- Idempotency: guarded by NOT EXISTS so re-running this migration is safe.

BEGIN;

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Texas State Senate',
       'Texas State Senate',
       '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Texas State Senate'
    AND government_id = '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Texas House of Representatives',
       'Texas House of Representatives',
       '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Texas House of Representatives'
    AND government_id = '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'
);

COMMIT;
