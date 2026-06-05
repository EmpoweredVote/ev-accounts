-- Migration 259: Normalize SJUSD name to remove accent
-- 'San José Unified School District' → 'San Jose Unified School District'
-- Fixes spelling inconsistency: San Jose city uses no accent;
-- SJUSD section header was showing 'San José' (with accent).

-- 1. Normalize essentials.governments.name
UPDATE essentials.governments
SET name = 'San Jose Unified School District, California, US'
WHERE name = 'San José Unified School District, California, US';

-- 2. Normalize essentials.chambers.name_formal
UPDATE essentials.chambers
SET name_formal = 'San Jose Unified School District Board of Education'
WHERE name_formal = 'San José Unified School District Board of Education';

-- Verify: governments row updated (should return 1)
SELECT COUNT(*) AS governments_updated
FROM essentials.governments
WHERE name = 'San Jose Unified School District, California, US';

-- Verify: no accented rows remain
SELECT COUNT(*) AS accented_remaining
FROM essentials.governments
WHERE name LIKE '%San Jos_% Unified%';
