-- Migration 049: Fix Ruben Marte candidate record
-- Fixes trailing apostrophe from seed SQL typo and links to politician profile
-- Idempotent: safe to run multiple times

-- NOTE: For future candidate imports, normalize Unicode names before matching:
-- JS: name.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
-- This strips diacritical marks (e.g., Martè → Marte) for ASCII matching.

-- Step 1: Fix the stored name (remove trailing apostrophe)
UPDATE essentials.race_candidates
SET
  full_name  = 'Ruben Marte',
  last_name  = 'Marte'
WHERE full_name LIKE 'Ruben Marte%'
  AND last_name LIKE 'Marte%'
  AND full_name != 'Ruben Marte';

-- Step 2: Link to politician profile by matching corrected name
-- If no politician record exists, politician_id stays NULL (acceptable)
UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.full_name = 'Ruben Marte'
  AND rc.politician_id IS NULL
  AND (p.full_name = 'Ruben Marte' OR (p.first_name = 'Ruben' AND p.last_name = 'Marte'));
