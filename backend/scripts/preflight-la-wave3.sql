-- preflight-la-wave3.sql
-- Re-runnable pre-flight verification for Wave 3 (10 new LA County cities).
-- Run before applying migrations 304–309.
-- Usage: psql $DATABASE_URL -f backend/scripts/preflight-la-wave3.sql

-- 1. Confirm external_id range -700200..-700699 is clean (zero prior allocations)
SELECT COUNT(*) AS used
FROM essentials.politicians
WHERE external_id BETWEEN -700699 AND -700200;
-- Expected: 0 before any Wave 3 migration is applied

-- 2. Duplicate-check: confirm each new city does NOT already exist in essentials.governments
SELECT 'City of South Gate'   AS city, COUNT(*) AS existing FROM essentials.governments WHERE name = 'City of South Gate'   AND state = 'CA'
UNION ALL
SELECT 'City of Compton',              COUNT(*)               FROM essentials.governments WHERE name = 'City of Compton'              AND state = 'CA'
UNION ALL
SELECT 'City of Carson',               COUNT(*)               FROM essentials.governments WHERE name = 'City of Carson'               AND state = 'CA'
UNION ALL
SELECT 'City of Hawthorne',            COUNT(*)               FROM essentials.governments WHERE name = 'City of Hawthorne'            AND state = 'CA'
UNION ALL
SELECT 'City of Whittier',             COUNT(*)               FROM essentials.governments WHERE name = 'City of Whittier'             AND state = 'CA'
UNION ALL
SELECT 'City of Alhambra',             COUNT(*)               FROM essentials.governments WHERE name = 'City of Alhambra'             AND state = 'CA'
UNION ALL
SELECT 'City of Gardena',              COUNT(*)               FROM essentials.governments WHERE name = 'City of Gardena'              AND state = 'CA'
UNION ALL
SELECT 'City of Culver City',          COUNT(*)               FROM essentials.governments WHERE name = 'City of Culver City'          AND state = 'CA'
UNION ALL
SELECT 'City of West Hollywood',       COUNT(*)               FROM essentials.governments WHERE name = 'City of West Hollywood'       AND state = 'CA'
UNION ALL
SELECT 'City of El Segundo',           COUNT(*)               FROM essentials.governments WHERE name = 'City of El Segundo'           AND state = 'CA'
ORDER BY city;
-- Expected: all rows show existing = 0
