-- Migration 107: Fix TX state/federal officials structural gaps
--
-- Two fixes for the 8 pre-seeded TX state/federal politicians (Abbott, Patrick,
-- Paxton, Hegar, Buckingham, Miller, Cornyn, Cruz):
--
-- 1. chambers.name_formal back-fill for 6 TX executive chambers
--    Migration 103 inserted these chambers with name_formal = '' (empty string).
--    Profile rendering reads name_formal for the chamber line; empty string
--    yields blank UI. Fix: copy name into name_formal for the 6 specific chambers.
--    The US Senate chamber (7cbe07bc-...) already has name_formal populated and
--    is NOT touched.
--
-- 2. politicians.office_id back-fill for 8 TX state/federal politicians
--    Migration 103 inserted offices with offices.politician_id set, but never
--    did the reverse: politicians.office_id remained NULL. This caused profile
--    pages to render without title/chamber. Same pattern migration 106 fixed
--    for TX US House reps. Scoped to external_id range -100210..-100199 so it
--    only touches these 8 stubs.
--
-- Idempotent:
-- - chamber UPDATE has `AND name_formal = ''` guard
-- - politician UPDATE has `AND p.office_id IS NULL` guard

BEGIN;

-- ===== FIX 1: TX executive chamber name_formal =====
-- Six chambers inserted by migration 103 with name_formal = ''.
-- Setting name_formal = name is the convention used elsewhere
-- (e.g. 'United States Senate' has name = name_formal).
-- The US Senate chamber is NOT in this list because its name_formal
-- is already populated.

UPDATE essentials.chambers
SET name_formal = name
WHERE name_formal = ''
  AND id IN (
    '4c0bbd02-ecd2-4e9d-b7bc-4e03b05a3739',  -- Texas Governor
    'd661b79d-679d-4f08-89b1-e04d36e4bb95',  -- Texas Lieutenant Governor
    '621bfcf4-11d7-4c7a-a434-8f887ad51dcf',  -- Texas Attorney General
    'f599d3e2-140c-46a1-9f6b-3efcd3acf919',  -- Texas Comptroller
    '65cb5326-6e24-448a-9199-86de75274a86',  -- Texas Land Commissioner
    'b9fca92c-68d9-4031-bb50-ae3cf093daa8'   -- Texas Agriculture Commissioner
  );

-- ===== FIX 2: politicians.office_id back-fill =====
-- Joins offices -> politicians via offices.politician_id, sets politicians.office_id.
-- Scoped to external_id range -100210..-100199 so it only touches the 8 TX
-- state/federal stubs (Cruz=-100200, Cornyn=-100201, Abbott=-100202,
-- Patrick=-100203, Paxton=-100204, Hegar=-100205, Buckingham=-100206,
-- Miller=-100207). Range provides headroom if more state/federal stubs are
-- added in the same numeric block before another back-fill.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -100210 AND -100199
  AND p.office_id IS NULL;

COMMIT;
